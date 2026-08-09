import Foundation

@main
struct MacCoreTests {
    static func main() async {
        await runCoreTests()
    }

    @MainActor
    private static func runCoreTests() async {
        let suiteName = "ChronoFocusMacCoreTests-\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            fail("Could not create isolated UserDefaults suite")
        }
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = FocusStore(defaults: defaults)
        store.tasks.removeAll()
        store.sessions.removeAll()
        store.pomodoroPlan.removeAll()
        store.activeTimer = nil
        store.settings.focusMinutes = 25
        store.settings.shortBreakMinutes = 5
        store.settings.longBreakMinutes = 15
        store.settings.roundsBeforeLongBreak = 4
        store.settings.completionSound = .ripple
        assert(store.settings.completionSound.title == "水波", "Expected Pro completion sound metadata")

        let dueDate = Date().addingTimeInterval(3600)
        guard let task = store.addTask(
            title: "Mac 验收任务",
            category: "测试",
            dueDate: dueDate,
            estimatedRounds: 2,
            accentHex: "#3DE8C5",
            isEnabled: true,
            autoStartPomodoro: true
        ) else {
            fail("Task creation failed")
        }

        assert(store.upcomingTasks().count == 1, "Expected one upcoming task")
        let plan = store.generatePomodoroPlanFromSchedule(referenceDate: Date())
        assert(plan.count == 2, "Expected two generated plan items")
        assert(plan.allSatisfy { $0.taskID == task.id }, "Generated plan should point at created task")
        assert(store.workloadAnalysis().remainingRounds == 2, "Expected two remaining rounds")

        store.recordSession(
            FocusSession(
                taskID: task.id,
                taskTitle: task.title,
                category: task.category,
                mode: .focus,
                startedAt: Date(),
                endedAt: Date().addingTimeInterval(1500),
                plannedSeconds: 1500,
                actualSeconds: 1500,
                completed: true
            )
        )
        assert(store.todayFocusSeconds == 1500, "Expected today's focus seconds to include completed session")
        assert(store.categoryBreakdown().first?.category == "测试", "Expected category breakdown for completed session")
        assert(store.categoryBreakdown().first?.sessionCount == 1, "Expected category breakdown to count completed sessions")

        _ = store.incrementRound(for: task.id)
        assert(store.task(for: task.id)?.completedRounds == 1, "Expected completed rounds to increment")

        _ = store.finishTask(task.id)
        assert(store.task(for: task.id)?.isDone == true, "Expected task to be marked done")

        guard let categorizedTask = store.addTask(
            title: "分类清洗任务",
            category: "  工作  ",
            dueDate: nil,
            estimatedRounds: 1,
            accentHex: "#54A0FF"
        ) else {
            fail("Categorized task creation failed")
        }
        assert(categorizedTask.category == "工作", "Expected task category to be trimmed")
        guard let uncategorizedTask = store.addTask(
            title: "空白分类任务",
            category: "   ",
            dueDate: nil,
            estimatedRounds: 1,
            accentHex: "#3DE8C5"
        ) else {
            fail("Uncategorized task creation failed")
        }
        assert(uncategorizedTask.category == "未分类", "Expected blank category to normalize to fallback")
        let defaultCategoryTitles = TaskCategoryPreset.defaults.map(\.title)
        assert(Array(store.taskCategories.prefix(defaultCategoryTitles.count)) == defaultCategoryTitles, "Expected default category order to stay stable")
        assert(store.taskCategories.contains("工作"), "Expected default category in category list")
        assert(store.taskCategories.contains("测试"), "Expected used category in category list")
        assert(store.taskCategories.contains("未分类"), "Expected normalized fallback category in category list")
        assert(TaskCategoryPreset.matching("工程")?.symbolName == "hammer.fill", "Expected category preset metadata lookup")
        let orderedCategories = TaskCategoryPreset.prioritizedFilterOptions(
            categories: ["工作", "成长", "测试", "复盘"]
        ) { category in
            ["测试": 3, "成长": 1][category] ?? 0
        }
        assert(orderedCategories.map(\.category) == ["测试", "成长", "工作", "复盘"], "Expected active categories to be prioritized by count")
        assert(orderedCategories.first?.symbolName == "tag.fill", "Expected custom category fallback symbol")
        assert(orderedCategories.first?.accentHex == "#3DE8C5", "Expected custom category fallback accent")

        await runStartableTaskTests(store: store)
        await runTimerEngineBoundaryTests(store: store)

        print("Mac core tests passed.")
    }

    @MainActor
    private static func runStartableTaskTests(store: FocusStore) async {
        store.tasks.removeAll()
        store.pomodoroPlan.removeAll()
        store.activeTimer = nil

        let now = Date()
        guard let laterTask = store.addTask(
            title: "稍后启动",
            category: "测试",
            dueDate: now.addingTimeInterval(7200),
            estimatedRounds: 1,
            accentHex: "#3DE8C5"
        ), let disabledTask = store.addTask(
            title: "停用但未完成",
            category: "测试",
            dueDate: now.addingTimeInterval(3600),
            estimatedRounds: 1,
            accentHex: "#54A0FF",
            isEnabled: false
        ), let earlierTask = store.addTask(
            title: "优先启动",
            category: "测试",
            dueDate: now.addingTimeInterval(1800),
            estimatedRounds: 1,
            accentHex: "#FFB84D"
        ) else {
            fail("Startable task fixture creation failed")
        }

        assert(store.upcomingTasks().map(\.id) == [earlierTask.id, disabledTask.id, laterTask.id], "Expected upcoming tasks to retain due-date ordering and disabled tasks")
        assert(store.startableTasks().map(\.id) == [earlierTask.id, laterTask.id], "Expected startable tasks to retain upcoming ordering while excluding disabled tasks")
        assert(store.startableTask(for: disabledTask.id) == nil, "Expected disabled task to be non-startable")

        guard let reenabledTask = store.setTaskEnabled(disabledTask, enabled: true) else {
            fail("Task re-enable failed")
        }
        assert(store.startableTask(for: reenabledTask.id)?.id == disabledTask.id, "Expected re-enabled task to become startable")
        assert(store.startableTasks().map(\.id) == [earlierTask.id, disabledTask.id, laterTask.id], "Expected re-enabled task to return at its upcoming position")

        _ = store.toggleTaskDone(earlierTask)
        assert(store.startableTask(for: earlierTask.id) == nil, "Expected completed task to be non-startable")
        assert(!store.upcomingTasks().contains(where: { $0.id == earlierTask.id }), "Expected completed task to leave upcoming tasks")

        store.deleteTasks(ids: [laterTask.id])
        assert(store.startableTask(for: laterTask.id) == nil, "Expected deleted task id to be non-startable")
        assert(store.startableTask(for: nil) == nil, "Expected nil task id to be non-startable")

        await Task.yield()
    }

    @MainActor
    private static func runTimerEngineBoundaryTests(store: FocusStore) async {
        store.tasks.removeAll()
        store.pomodoroPlan.removeAll()
        store.activeTimer = nil
        store.settings.autoGeneratePomodoroPlan = false
        store.settings.autoStartBreaks = false
        store.settings.autoStartFocus = false
        store.settings.notificationsEnabled = false
        store.settings.liveActivityEnabled = false

        let notifications = FakeTimerNotificationService()
        let liveActivities = FakeTimerLiveActivityService()
        let engine = TimerEngine(store: store, notifications: notifications, liveActivities: liveActivities)

        guard let selectedTask = store.addTask(
            title: "引擎选择任务",
            category: "引擎",
            dueDate: Date().addingTimeInterval(600),
            estimatedRounds: 1,
            accentHex: "#3DE8C5"
        ), let otherTask = store.addTask(
            title: "保持当前选择",
            category: "引擎",
            dueDate: Date().addingTimeInterval(1200),
            estimatedRounds: 2,
            accentHex: "#54A0FF"
        ) else {
            fail("Timer engine fixture creation failed")
        }

        engine.selectTask(otherTask)
        _ = store.setTaskEnabled(selectedTask, enabled: false)
        engine.selectTask(selectedTask)
        assert(engine.selectedTaskID == otherTask.id, "Expected stale disabled selection not to clear another valid selection")
        assert(engine.currentTaskTitle == otherTask.title, "Expected valid current selection title to remain")

        _ = store.setTaskEnabled(otherTask, enabled: false)
        await Task.yield()
        assert(engine.selectedTaskID == nil, "Expected idle disabled selection to reconcile to free focus")
        assert(engine.currentTaskTitle == "自由专注", "Expected idle disabled selection title to reconcile")

        _ = store.setTaskEnabled(selectedTask, enabled: true)
        guard let currentSelectedTask = store.startableTask(for: selectedTask.id) else {
            fail("Re-enabled timer task should be startable")
        }
        engine.selectTask(currentSelectedTask)
        _ = store.setTaskEnabled(currentSelectedTask, enabled: false)
        engine.start()
        assert(store.activeTimer?.taskID == nil, "Expected start final guard to drop invalid selected task")
        assert(store.activeTimer?.taskTitle == "自由专注", "Expected invalid selection to start as free focus")
        engine.stop(markIncomplete: false)

        _ = store.setTaskEnabled(selectedTask, enabled: true)
        guard let planTask = store.startableTask(for: selectedTask.id) else {
            fail("Plan task should be startable")
        }
        store.settings.autoGeneratePomodoroPlan = true
        let plan = store.generatePomodoroPlanFromSchedule(referenceDate: Date())
        guard let planItem = plan.first(where: { $0.taskID == planTask.id }) else {
            fail("Plan fixture creation failed")
        }
        let originalPlanItem = planItem
        _ = store.setTaskEnabled(planTask, enabled: false)
        engine.startPlanItem(planItem)
        assert(store.activeTimer == nil, "Expected invalid plan item not to start a session")
        assert(store.pomodoroPlan.first(where: { $0.id == planItem.id }) == originalPlanItem, "Expected invalid plan item not to be marked started")

        _ = store.setTaskEnabled(selectedTask, enabled: true)
        guard let runningTask = store.startableTask(for: selectedTask.id) else {
            fail("Running task should be startable")
        }
        engine.selectTask(runningTask)
        engine.start()
        let runningSnapshot = store.activeTimer
        _ = store.setTaskEnabled(runningTask, enabled: false)
        await Task.yield()
        assert(engine.isRunning, "Expected disabling a running task not to stop the engine")
        assert(engine.selectedTaskID == runningTask.id, "Expected running selection to preserve snapshot task id")
        assert(engine.currentTaskTitle == runningTask.title, "Expected running selection to preserve snapshot title")
        assert(store.activeTimer?.sessionID == runningSnapshot?.sessionID, "Expected running snapshot to remain intact after disabling its task")
        engine.stop(markIncomplete: false)
        assert(engine.selectedTaskID == nil, "Expected stop path to reconcile invalid selection")
        assert(engine.currentTaskTitle == "自由专注", "Expected stop path to restore free focus title")

        _ = store.setTaskEnabled(selectedTask, enabled: true)
        guard let pausedTask = store.startableTask(for: selectedTask.id) else {
            fail("Paused task should be startable")
        }
        engine.selectTask(pausedTask)
        engine.start()
        engine.pause()
        let pausedSnapshot = store.activeTimer
        store.deleteTasks(ids: [pausedTask.id])
        await Task.yield()
        assert(engine.isRunning && engine.isPaused, "Expected deleting a paused task not to stop the engine")
        assert(engine.selectedTaskID == pausedTask.id, "Expected paused selection to preserve snapshot task id")
        assert(engine.currentTaskTitle == pausedTask.title, "Expected paused selection to preserve snapshot title")
        assert(store.activeTimer?.sessionID == pausedSnapshot?.sessionID, "Expected paused snapshot to remain intact after deleting its task")
        engine.stop(markIncomplete: false)
        assert(engine.selectedTaskID == nil, "Expected paused stop path to reconcile deleted selection")

        guard let completableTask = store.addTask(
            title: "完成后收敛",
            category: "引擎",
            dueDate: nil,
            estimatedRounds: 1,
            accentHex: "#FFB84D"
        ) else {
            fail("Completable task fixture creation failed")
        }
        engine.selectTask(completableTask)
        engine.start()
        engine.finishCurrentTask()
        assert(store.task(for: completableTask.id)?.isDone == true, "Expected finish path to complete selected task")
        assert(engine.selectedTaskID == nil, "Expected finish path to reconcile completed selection")
        assert(engine.currentTaskTitle == "自由专注", "Expected finish path to restore free focus title")
    }

    private static func fail(_ message: String) -> Never {
        fputs("Test failed: \(message)\n", stderr)
        Foundation.exit(1)
    }
}

@MainActor
private final class FakeTimerNotificationService: TimerNotificationServicing {
    func scheduleCompletion(
        identifier: String,
        mode: TimerMode,
        taskTitle: String,
        nextMode: TimerMode,
        endDate: Date,
        soundEnabled: Bool
    ) async {}

    func cancel(identifier: String?) {}
    func cancelTaskReminder(taskID: UUID) {}
    func playCompletionAlert(soundVolume: Double, vibrationEnabled: Bool, completionSound: CompletionSound) {}
}

@MainActor
private final class FakeTimerLiveActivityService: TimerLiveActivityServicing {
    func start(for snapshot: ActiveTimerSnapshot) async {}
    func update(with snapshot: ActiveTimerSnapshot, remainingSeconds: Int) async {}
    func end(immediate: Bool) async {}
}

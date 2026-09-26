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
            accentHex: "#54A0FF",
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
        store.recordSession(
            FocusSession(
                taskID: nil,
                taskTitle: "历史记录",
                category: "历史",
                mode: .shortBreak,
                startedAt: Date(),
                endedAt: Date().addingTimeInterval(300),
                plannedSeconds: 300,
                actualSeconds: 300,
                completed: true
            )
        )
        store.recordSession(
            FocusSession(
                taskID: task.id,
                taskTitle: task.title,
                category: "  测试  ",
                mode: .focus,
                startedAt: Date(),
                endedAt: Date().addingTimeInterval(300),
                plannedSeconds: 300,
                actualSeconds: 300,
                completed: true
            )
        )
        assert(store.todayFocusSeconds == 1800, "Expected today's focus seconds to include completed sessions")
        assert(store.categoryBreakdown().first?.category == "测试", "Expected category breakdown for completed session")
        assert(store.categoryBreakdown().first?.sessionCount == 2, "Expected normalized categories to share one breakdown row")
        assert(store.categoryBreakdown().count == 1, "Expected whitespace variants to merge and break sessions to stay excluded")
        assert(store.categoryBreakdown().first?.seconds == 1800, "Expected normalized category seconds to include both focus sessions")

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
        assert(store.representativeAccentHex(for: "工作") == "#3DE8C5", "Preset category should keep its preset accent")
        assert(store.representativeAccentHex(for: "测试") == task.accentHex, "Custom category should use its first task accent")
        assert(store.representativeAccentHex(for: "历史") == TaskCategoryPreset.fallbackAccentHex, "Session-only category should use the shared fallback accent")
        assert(store.representativeAccentHex(for: " 工作 ") == "#3DE8C5", "Preset category matching should trim whitespace")
        assert(TaskCategoryPreset.accentHex(for: "非法", preferred: "not-a-color") == TaskCategoryPreset.fallbackAccentHex, "Invalid preferred accent should use the shared fallback")
        assert(TaskCategoryPreset.usableAccentHex(" #abc ") == "#ABC", "Three-digit accents should be normalized")
        assert(TaskCategoryPreset.contrastTextHex(on: "#000000") == "#FFFFFF", "Dark accents should use a light foreground")
        assert(TaskCategoryPreset.contrastTextHex(on: "#FFFFFF") == "#111827", "Light accents should use a dark foreground")
        assert(TaskCategoryPreset.contrastTextHex(on: "#111827") == "#FFFFFF", "The dark foreground itself should use contrasting white text")
        assert(TaskCategoryPreset.contrastTextHex(on: "#777777") == "#FFFFFF", "Mid-gray should prefer white over the actual dark foreground, not pure black")
        assert(TaskCategoryPreset.contrastTextHex(on: "#808080") == "#111827", "Lighter mid-gray should prefer the actual dark foreground")
        // Adjacent gray levels straddle the white/#111827 contrast crossover.
        assert(TaskCategoryPreset.contrastTextHex(on: "#7B7B7B") == "#FFFFFF", "Gray below the actual contrast crossover should prefer white")
        assert(TaskCategoryPreset.contrastTextHex(on: "#7C7C7C") == "#111827", "Gray above the actual contrast crossover should prefer dark text")
        assert(TaskCategoryPreset.contrastTextHex(on: " #777 ") == "#FFFFFF", "Short HEX normalization should preserve the mid-gray contrast choice")
        assert(TaskCategoryPreset.contrastTextHex(on: "not-a-color") == "#111827", "Invalid HEX should use the shared fallback's higher-contrast dark foreground")
        assert(TaskCategoryPreset.contrastTextHex(on: "") == "#111827", "Empty HEX should use the shared fallback's higher-contrast dark foreground")
        assert(TaskCategoryPreset.contrastTextHex(on: nil) == "#111827", "Missing HEX should use the shared fallback's higher-contrast dark foreground")
        store.tasks = [
            FocusTask(title: "首个颜色", category: "颜色", dueDate: nil, estimatedRounds: 1, accentHex: "#FFB84D"),
            FocusTask(title: "后续颜色", category: "颜色", dueDate: nil, estimatedRounds: 1, accentHex: "#54A0FF")
        ]
        assert(store.representativeAccentHex(for: "颜色") == "#FFB84D", "Custom category should use the first matching task color")
        let orderedCategories = TaskCategoryPreset.prioritizedFilterOptions(
            categories: ["工作", "成长", "测试", "复盘"],
            countProvider: { category in
                ["测试": 3, "成长": 1][category] ?? 0
            }
        )
        assert(orderedCategories.map(\.category) == ["测试", "成长", "工作", "复盘"], "Expected active categories to be prioritized by count")
        assert(orderedCategories.first?.symbolName == "tag.fill", "Expected custom category fallback symbol")
        let coloredOptions = TaskCategoryPreset.prioritizedFilterOptions(
            categories: ["颜色", "工作", "历史"],
            countProvider: { _ in 1 },
            accentProvider: { category in store.representativeAccentHex(for: category) }
        )
        assert(coloredOptions.map(\.accentHex) == ["#FFB84D", "#3DE8C5", TaskCategoryPreset.fallbackAccentHex], "Expected filter options to reuse representative accents")

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
        await waitForCondition("Idle disabled selection did not reconcile") {
            engine.selectedTaskID == nil && engine.currentTaskTitle == "自由专注"
        }
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
        if let currentPlanItem = store.pomodoroPlan.first(where: { $0.id == planItem.id }) {
            assert(
                currentPlanItem.scheduledStart == originalPlanItem.scheduledStart,
                "Expected invalid plan item not to be marked started"
            )
        }

        _ = store.setTaskEnabled(selectedTask, enabled: true)
        guard let runningTask = store.startableTask(for: selectedTask.id) else {
            fail("Running task should be startable")
        }
        engine.selectTask(runningTask)
        engine.start()
        guard let runningSnapshot = store.activeTimer else {
            fail("Expected a running snapshot before testing task mutation guards")
        }
        assert(store.settings.autoGeneratePomodoroPlan, "Running deletion guards must be tested with automatic plan generation enabled")
        let runningTasks = store.tasks
        let runningPlan = store.pomodoroPlan
        assert(runningPlan.contains { $0.taskID == runningTask.id }, "Expected existing plan items before testing running task protection")
        assert(runningSnapshot.taskID == runningTask.id, "Running snapshot should capture the task identity")
        assert(runningSnapshot.taskTitle == runningTask.title, "Running snapshot should capture the task title")
        assert(runningSnapshot.category == runningTask.category, "Running snapshot should capture the task category")
        assert(runningSnapshot.tintHex == "#54A0FF", "Running snapshot should use the first same-category task's representative accent, even when that task is disabled")
        let runningEdit = store.updateTask(
            runningTask,
            title: "Rejected running edit",
            category: "Rejected category",
            dueDate: nil,
            estimatedRounds: 3,
            accentHex: "#FF0000"
        )
        assert(runningEdit == nil, "Expected editing a running task to be rejected")
        let runningDisable = store.setTaskEnabled(runningTask, enabled: false)
        assert(runningDisable == nil, "Expected disabling a running task to be rejected")
        let runningCompletion = store.toggleTaskDone(runningTask)
        assert(runningCompletion == nil, "Expected toggling a running task's completion to be rejected")
        for ids in [[runningTask.id], [], [UUID()]] {
            store.deleteTasks(ids: ids)
            assert(store.tasks == runningTasks, "Running rejected or invalid deletion must preserve the complete ordered task array")
            assert(store.pomodoroPlan == runningPlan, "Running rejected or invalid deletion must preserve all plan identities, times and metadata")
            assert(store.activeTimer == runningSnapshot, "Running rejected or invalid deletion must preserve the complete active snapshot")
            assert(engine.isRunning && !engine.isPaused, "Running rejected or invalid deletion must preserve engine state")
        }
        await Task.yield()
        assert(store.task(for: runningTask.id) == runningTask, "Rejected running mutations must preserve the task identity, title, category, accent and enabled state")
        assert(store.pomodoroPlan == runningPlan, "Rejected running mutations must preserve the complete plan")
        assert(engine.isRunning && !engine.isPaused, "Expected rejected running mutations not to change engine state")
        assert(engine.selectedTaskID == runningTask.id, "Expected running selection to preserve snapshot task id")
        assert(engine.currentTaskTitle == runningTask.title, "Expected running selection to preserve snapshot title")
        assert(store.activeTimer == runningSnapshot, "Rejected running mutations must preserve the entire snapshot, including session identity, title, category and tint")
        engine.stop(markIncomplete: false)
        assert(store.activeTimer == nil && !engine.isRunning && !engine.isPaused, "Expected stop to clear the running snapshot and runtime state")
        assert(engine.selectedTaskID == runningTask.id, "Expected stop to preserve a still-startable selection")
        assert(engine.currentTaskTitle == runningTask.title, "Expected stop to preserve the valid task title")
        let idleDisabledTask = store.setTaskEnabled(runningTask, enabled: false)
        assert(idleDisabledTask?.isEnabled == false, "Expected disabling the task after stop to succeed")
        assert(store.startableTask(for: runningTask.id) == nil, "Expected the idle disabled task to become non-startable")
        await waitForCondition("Idle disabling after stop did not reconcile") {
            engine.selectedTaskID == nil && engine.currentTaskTitle == "自由专注"
        }
        assert(engine.selectedTaskID == nil, "Expected idle disabling after stop to reconcile invalid selection")
        assert(engine.currentTaskTitle == "自由专注", "Expected idle disabling after stop to restore free focus title")
        assert(store.activeTimer == nil && !engine.isRunning && !engine.isPaused, "Idle disabling must not start a new timer")

        _ = store.setTaskEnabled(selectedTask, enabled: true)
        guard let pausedTask = store.startableTask(for: selectedTask.id) else {
            fail("Paused task should be startable")
        }
        engine.selectTask(pausedTask)
        engine.start()
        engine.pause()
        guard let pausedSnapshot = store.activeTimer else {
            fail("Expected a paused snapshot before testing task mutation guards")
        }
        assert(store.settings.autoGeneratePomodoroPlan, "Paused deletion guards must be tested with automatic plan generation enabled")
        let pausedTasks = store.tasks
        let pausedPlan = store.pomodoroPlan
        assert(pausedPlan.contains { $0.taskID == pausedTask.id }, "Expected existing plan items before testing paused task protection")
        assert(pausedSnapshot.isPaused, "Expected the snapshot to record paused state")
        assert(pausedSnapshot.taskID == pausedTask.id, "Paused snapshot should preserve the task identity")
        assert(pausedSnapshot.taskTitle == pausedTask.title, "Paused snapshot should preserve the task title")
        assert(pausedSnapshot.category == pausedTask.category, "Paused snapshot should preserve the task category")
        assert(pausedSnapshot.tintHex == "#54A0FF", "Paused snapshot should preserve the first same-category task's representative accent")
        let pausedEdit = store.updateTask(
            pausedTask,
            title: "Rejected paused edit",
            category: "Rejected category",
            dueDate: nil,
            estimatedRounds: 3,
            accentHex: "#FF0000"
        )
        assert(pausedEdit == nil, "Expected editing a paused task to be rejected")
        let pausedDisable = store.setTaskEnabled(pausedTask, enabled: false)
        assert(pausedDisable == nil, "Expected disabling a paused task to be rejected")
        let pausedCompletion = store.toggleTaskDone(pausedTask)
        assert(pausedCompletion == nil, "Expected toggling a paused task's completion to be rejected")
        for ids in [[pausedTask.id], [], [UUID()]] {
            store.deleteTasks(ids: ids)
            assert(store.tasks == pausedTasks, "Paused rejected or invalid deletion must preserve the complete ordered task array")
            assert(store.pomodoroPlan == pausedPlan, "Paused rejected or invalid deletion must preserve all plan identities, times and metadata")
            assert(store.activeTimer == pausedSnapshot, "Paused rejected or invalid deletion must preserve the complete active snapshot")
            assert(engine.isRunning && engine.isPaused, "Paused rejected or invalid deletion must preserve engine state")
        }
        await Task.yield()
        assert(store.task(for: pausedTask.id) == pausedTask, "Rejected paused mutations must preserve the task identity, title, category, accent and enabled state")
        assert(store.pomodoroPlan == pausedPlan, "Rejected paused mutations must preserve the complete plan")
        assert(engine.isRunning && engine.isPaused, "Expected rejected paused mutations not to change engine state")
        assert(engine.selectedTaskID == pausedTask.id, "Expected paused selection to preserve snapshot task id")
        assert(engine.currentTaskTitle == pausedTask.title, "Expected paused selection to preserve snapshot title")
        assert(store.activeTimer == pausedSnapshot, "Rejected paused mutations must preserve the entire snapshot, including session identity, title, category and tint")

        guard let batchTask = store.addTask(
            title: "Mixed deletion companion",
            category: "Batch deletion",
            dueDate: nil,
            estimatedRounds: 1,
            accentHex: "#FFB84D"
        ) else {
            fail("Mixed deletion fixture creation failed")
        }
        assert(store.pomodoroPlan.contains { $0.taskID == batchTask.id }, "Mixed deletion should include a real non-active plan item")
        let tasksBeforeBatch = store.tasks
        store.deleteTasks(ids: [pausedTask.id, batchTask.id, batchTask.id, UUID()])
        assert(store.tasks == tasksBeforeBatch.filter { $0.id != batchTask.id }, "Mixed deletion must remove only the eligible non-active task")
        assert(!store.pomodoroPlan.contains { $0.taskID == batchTask.id }, "Mixed deletion must remove the non-active task's plan items")
        assert(store.pomodoroPlan.contains { $0.taskID == pausedTask.id }, "Mixed deletion must retain a plan for the protected active task")
        assert(store.activeTimer == pausedSnapshot, "Mixed deletion must preserve the active snapshot despite legitimate plan regeneration")
        assert(engine.isRunning && engine.isPaused && engine.selectedTaskID == pausedTask.id, "Mixed deletion must preserve the paused engine selection")
        engine.stop(markIncomplete: false)
        assert(store.activeTimer == nil && !engine.isRunning && !engine.isPaused, "Expected stop to clear the paused snapshot and runtime state")
        assert(engine.selectedTaskID == pausedTask.id, "Expected paused stop to preserve a still-startable selection")
        assert(engine.currentTaskTitle == pausedTask.title, "Expected paused stop to preserve the valid task title")
        store.deleteTasks(ids: [pausedTask.id])
        assert(store.task(for: pausedTask.id) == nil, "Expected deleting the task after stop to succeed")
        assert(!store.pomodoroPlan.contains { $0.taskID == pausedTask.id }, "Expected deletion after stop to remove the related plan items")
        assert(store.startableTask(for: pausedTask.id) == nil, "Expected the idle deleted task to become non-startable")
        await waitForCondition("Idle deletion after paused stop did not reconcile") {
            engine.selectedTaskID == nil && engine.currentTaskTitle == "自由专注"
        }
        assert(engine.selectedTaskID == nil, "Expected idle deletion after paused stop to reconcile deleted selection")
        assert(engine.currentTaskTitle == "自由专注", "Expected idle deletion after paused stop to restore free focus title")
        assert(store.activeTimer == nil && !engine.isRunning && !engine.isPaused, "Idle deletion must not start a new timer")

        guard let editableTask = store.addTask(
            title: "Editable after stop",
            category: "Editable category",
            dueDate: nil,
            estimatedRounds: 1,
            accentHex: "#FFB84D"
        ) else {
            fail("Post-stop editing fixture creation failed")
        }
        engine.selectTask(editableTask)
        engine.start()
        assert(store.activeTimer?.taskID == editableTask.id, "Expected editing fixture to start before testing stop unlock")
        engine.stop(markIncomplete: false)
        guard let editedTask = store.updateTask(
            editableTask,
            title: "Edited after stop",
            category: "Updated category",
            dueDate: nil,
            estimatedRounds: 3,
            accentHex: "#FF0000"
        ) else {
            fail("Expected editing the task after stop to succeed")
        }
        assert(editedTask.id == editableTask.id && editedTask.isEnabled, "Post-stop editing should preserve task identity and enabled state")
        assert(editedTask.title == "Edited after stop" && editedTask.category == "Updated category", "Post-stop editing should apply title and category changes")
        assert(editedTask.accentHex == "#FF0000" && editedTask.estimatedRounds == 3, "Post-stop editing should apply accent and round changes")
        assert(store.startableTask(for: editableTask.id) == editedTask, "Expected the edited task to remain stored and startable")
        await waitForCondition("Idle editing after stop did not refresh selection") {
            engine.selectedTaskID == editedTask.id && engine.currentTaskTitle == editedTask.title
        }
        assert(engine.selectedTaskID == editedTask.id, "Idle editing must not clear a still-startable selection")
        assert(engine.currentTaskTitle == editedTask.title, "Idle editing should refresh the selected task title")
        assert(store.activeTimer == nil && !engine.isRunning && !engine.isPaused, "Idle editing must not start a new timer")

        guard var orphanedPlanItem = store.pomodoroPlan.first else {
            fail("Plan-only deletion requires a nonempty automatically generated plan")
        }
        orphanedPlanItem.id = UUID()
        orphanedPlanItem.taskID = UUID()
        store.pomodoroPlan.append(orphanedPlanItem)
        let tasksBeforePlanOnlyDeletion = store.tasks
        let planBeforeItemIDDeletion = store.pomodoroPlan
        store.deleteTasks(ids: [orphanedPlanItem.id])
        assert(store.tasks == tasksBeforePlanOnlyDeletion && store.pomodoroPlan == planBeforeItemIDDeletion, "Deletion ids must match task IDs, not plan item IDs")
        store.deleteTasks(ids: [orphanedPlanItem.taskID])
        assert(store.tasks == tasksBeforePlanOnlyDeletion, "Plan-only deletion must preserve unrelated tasks")
        assert(!store.pomodoroPlan.contains { $0.taskID == orphanedPlanItem.taskID }, "An orphaned non-active plan item must be deletable by task ID")
        assert(store.pomodoroPlan.count == editedTask.remainingRounds && store.pomodoroPlan.allSatisfy { $0.taskID == editedTask.id }, "Plan-only deletion should retain normal automatic plan generation for startable tasks")
        assert(store.activeTimer == nil, "Plan-only deletion must not create an active snapshot")

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

        store.settings.liveActivityEnabled = true
        let startsBeforeLiveActivity = liveActivities.startCount
        let updatesBeforeLiveActivity = liveActivities.updateCount
        engine.start()
        await Task.yield()
        assert(liveActivities.startCount == startsBeforeLiveActivity + 1, "Enabled live activity should start with a new timer")
        engine.pause()
        await Task.yield()
        assert(liveActivities.updateCount > updatesBeforeLiveActivity, "Pausing should publish the remaining live activity time")
        assert(liveActivities.lastRemainingSeconds > 0, "Paused live activity should retain a positive remaining time")

        guard var pausedForRecording = store.activeTimer else {
            fail("Expected an active paused snapshot before recording elapsed time")
        }
        pausedForRecording.remainingWhenPaused = pausedForRecording.plannedSeconds - 60
        store.activeTimer = pausedForRecording
        let sessionCountBeforePausedStop = store.sessions.count
        engine.stop()
        await Task.yield()
        assert(store.sessions.count == sessionCountBeforePausedStop + 1, "A paused timer with one active minute should record a session")
        assert(store.sessions.first?.actualSeconds == 60, "Paused time should not inflate recorded active seconds")
        assert(liveActivities.endCount > 0, "Stopping should end the live activity")
        store.settings.liveActivityEnabled = false
    }

    @MainActor
    private static func waitForCondition(_ message: String, condition: () -> Bool) async {
        // Let queued store observers run; never drive reconciliation from the test.
        for _ in 0..<100 {
            if condition() { return }
            do {
                try await Task.sleep(nanoseconds: 10_000_000)
            } catch {
                fail("State observation wait was cancelled: \(message)")
            }
        }
        guard condition() else { fail(message) }
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
    private(set) var startCount = 0
    private(set) var updateCount = 0
    private(set) var endCount = 0
    private(set) var lastRemainingSeconds = 0

    func start(for snapshot: ActiveTimerSnapshot) async {
        startCount += 1
        lastRemainingSeconds = snapshot.remainingWhenPaused
    }

    func update(with snapshot: ActiveTimerSnapshot, remainingSeconds: Int) async {
        updateCount += 1
        lastRemainingSeconds = remainingSeconds
    }

    func end(immediate: Bool) async {
        endCount += 1
    }
}

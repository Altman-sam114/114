import Foundation

@main
struct MacCoreTests {
    static func main() async {
        await MainActor.run {
            runFocusStoreTests()
        }
    }

    @MainActor
    private static func runFocusStoreTests() {
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

        _ = store.incrementRound(for: task.id)
        assert(store.task(for: task.id)?.completedRounds == 1, "Expected completed rounds to increment")

        _ = store.finishTask(task.id)
        assert(store.task(for: task.id)?.isDone == true, "Expected task to be marked done")

        print("Mac core tests passed.")
    }

    private static func fail(_ message: String) -> Never {
        fputs("Test failed: \(message)\n", stderr)
        Foundation.exit(1)
    }
}

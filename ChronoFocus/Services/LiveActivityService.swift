import ActivityKit
import Foundation

@MainActor
final class LiveActivityService: TimerLiveActivityServicing {
    private var activity: Activity<PomodoroActivityAttributes>?

    init() {
        activity = Activity<PomodoroActivityAttributes>.activities.first
    }

    var activitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    func start(for snapshot: ActiveTimerSnapshot) async {
        await end(immediate: true)
        guard activitiesEnabled else { return }

        let activeElapsed = activeElapsedSeconds(for: snapshot)

        let attributes = PomodoroActivityAttributes(
            sessionID: snapshot.sessionID.uuidString,
            startedAt: Date().addingTimeInterval(-TimeInterval(activeElapsed))
        )
        let state = contentState(for: snapshot)
        let content = ActivityContent(
            state: state,
            staleDate: snapshot.isPaused ? nil : snapshot.endAt
        )

        do {
            activity = try Activity<PomodoroActivityAttributes>.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            activity = nil
        }
    }

    func update(with snapshot: ActiveTimerSnapshot, remainingSeconds: Int) async {
        guard let activity else { return }
        var updated = snapshot
        updated.remainingWhenPaused = remainingSeconds
        let state = contentState(for: updated)
        await activity.update(
            ActivityContent(
                state: state,
                staleDate: snapshot.isPaused ? nil : snapshot.endAt
            )
        )
    }

    func end(immediate: Bool = false) async {
        let activities = Activity<PomodoroActivityAttributes>.activities
        guard !activities.isEmpty else {
            activity = nil
            return
        }
        let state = PomodoroActivityAttributes.ContentState(
            modeName: "完成",
            taskTitle: "已归档",
            endDate: Date(),
            tintHex: "#3DE8C5",
            isPaused: false,
            remainingSeconds: 0
        )
        let policy: ActivityUIDismissalPolicy = immediate ? .immediate : .after(Date().addingTimeInterval(3600))
        for activity in activities {
            await activity.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: policy)
        }
        self.activity = nil
    }

    private func activeElapsedSeconds(for snapshot: ActiveTimerSnapshot) -> Int {
        let remaining = snapshot.isPaused
            ? snapshot.remainingWhenPaused
            : max(0, Int(ceil(snapshot.endAt.timeIntervalSinceNow)))
        return min(snapshot.plannedSeconds, max(0, snapshot.plannedSeconds - remaining))
    }

    private func contentState(for snapshot: ActiveTimerSnapshot) -> PomodoroActivityAttributes.ContentState {
        PomodoroActivityAttributes.ContentState(
            modeName: snapshot.mode.title,
            taskTitle: snapshot.taskTitle,
            endDate: snapshot.endAt,
            tintHex: snapshot.tintHex,
            isPaused: snapshot.isPaused,
            remainingSeconds: snapshot.remainingWhenPaused
        )
    }
}

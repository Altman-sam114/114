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
        guard activitiesEnabled else { return }
        await end(immediate: true)

        let attributes = PomodoroActivityAttributes(
            sessionID: snapshot.sessionID.uuidString,
            startedAt: snapshot.startedAt
        )
        let state = contentState(for: snapshot)
        let content = ActivityContent(state: state, staleDate: snapshot.endAt)

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
        await activity.update(ActivityContent(state: state, staleDate: snapshot.endAt))
    }

    func end(immediate: Bool = false) async {
        guard let activity else { return }
        let state = PomodoroActivityAttributes.ContentState(
            modeName: "完成",
            taskTitle: "已归档",
            endDate: Date(),
            tintHex: "#3DE8C5",
            isPaused: false,
            remainingSeconds: 0
        )
        let policy: ActivityUIDismissalPolicy = immediate ? .immediate : .after(Date().addingTimeInterval(3600))
        await activity.end(ActivityContent(state: state, staleDate: nil), dismissalPolicy: policy)
        self.activity = nil
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

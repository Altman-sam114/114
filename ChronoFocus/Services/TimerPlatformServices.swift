import Foundation

@MainActor
protocol TimerNotificationServicing: AnyObject {
    func scheduleCompletion(
        identifier: String,
        mode: TimerMode,
        taskTitle: String,
        nextMode: TimerMode,
        endDate: Date,
        soundEnabled: Bool
    ) async

    func cancel(identifier: String?)
    func cancelTaskReminder(taskID: UUID)
    func playCompletionAlert(soundVolume: Double, vibrationEnabled: Bool)
}

@MainActor
protocol TimerLiveActivityServicing: AnyObject {
    func start(for snapshot: ActiveTimerSnapshot) async
    func update(with snapshot: ActiveTimerSnapshot, remainingSeconds: Int) async
    func end(immediate: Bool) async
}

extension TimerLiveActivityServicing {
    func end() async {
        await end(immediate: false)
    }
}

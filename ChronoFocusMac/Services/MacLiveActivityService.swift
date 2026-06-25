import Foundation

@MainActor
final class MacLiveActivityService: TimerLiveActivityServicing {
    func start(for snapshot: ActiveTimerSnapshot) async {}
    func update(with snapshot: ActiveTimerSnapshot, remainingSeconds: Int) async {}
    func end(immediate: Bool = false) async {}
}

import Combine
import Foundation
import UIKit

@MainActor
final class TimerEngine: ObservableObject {
    @Published var mode: TimerMode = .focus
    @Published var selectedTaskID: UUID?
    @Published private(set) var isRunning = false
    @Published private(set) var isPaused = false
    @Published private(set) var remainingSeconds = TimerSettings().focusMinutes * 60
    @Published private(set) var plannedSeconds = TimerSettings().focusMinutes * 60
    @Published private(set) var roundIndex = 0
    @Published private(set) var currentTaskTitle = "自由专注"

    private let store: FocusStore
    private let notifications: NotificationService
    private let liveActivities: LiveActivityService
    private var ticker: Timer?
    private var lastLiveActivityUpdate = Date.distantPast

    init(store: FocusStore, notifications: NotificationService, liveActivities: LiveActivityService) {
        self.store = store
        self.notifications = notifications
        self.liveActivities = liveActivities
        restoreFromStore()
    }

    var progress: Double {
        guard plannedSeconds > 0 else { return 0 }
        return min(1, max(0, 1 - Double(remainingSeconds) / Double(plannedSeconds)))
    }

    var formattedRemaining: String {
        remainingSeconds.clockString
    }

    var nextModeHint: String {
        nextMode(after: mode, completedRoundIndex: roundIndex).title
    }

    var isCurrentTaskOpenEnded: Bool {
        store.task(for: selectedTaskID)?.startMode == .openEnded
    }

    func selectMode(_ newMode: TimerMode) {
        guard !isRunning else { return }
        mode = newMode
        syncIdleDuration()
    }

    func selectTask(_ task: FocusTask?) {
        guard !isRunning else { return }
        selectedTaskID = task?.id
        currentTaskTitle = task?.title ?? "自由专注"
    }

    func startPlanItem(_ item: PomodoroPlanItem) {
        guard !isRunning, let task = store.task(for: item.taskID) else { return }
        mode = .focus
        selectedTaskID = task.id
        currentTaskTitle = task.title
        store.markPlanItemStarted(item)
        syncIdleDuration()
        start()
    }

    func checkScheduledAutoStart() {
        guard !isRunning, let task = store.autoStartCandidate() else { return }
        mode = .focus
        selectedTaskID = task.id
        currentTaskTitle = task.title
        store.markTaskAutoStarted(task.id)
        syncIdleDuration()
        start()
    }

    func syncIdleDuration() {
        guard !isRunning else { return }
        plannedSeconds = store.settings.seconds(for: mode)
        remainingSeconds = plannedSeconds
    }

    func handleSettingsChange() {
        updateIdleTimerPolicy()
        guard let snapshot = store.activeTimer else {
            syncIdleDuration()
            return
        }

        if store.settings.notificationsEnabled && !snapshot.isPaused {
            Task {
                await notifications.scheduleCompletion(
                    identifier: snapshot.sessionID.uuidString,
                    mode: snapshot.mode,
                    taskTitle: snapshot.taskTitle,
                    nextMode: nextMode(after: snapshot.mode, completedRoundIndex: snapshot.roundIndex),
                    endDate: snapshot.endAt,
                    soundEnabled: store.settings.soundEnabled && store.settings.soundVolume > 0
                )
            }
        } else {
            notifications.cancel(identifier: snapshot.sessionID.uuidString)
        }

        Task {
            if store.settings.liveActivityEnabled {
                await liveActivities.start(for: snapshot)
            } else {
                await liveActivities.end(immediate: true)
            }
        }
    }

    func refreshFromClock() {
        guard let snapshot = store.activeTimer else {
            syncIdleDuration()
            return
        }

        if !snapshot.isPaused && snapshot.endAt <= Date() {
            completeCurrentSession(playSound: false)
        } else {
            apply(snapshot)
            if !snapshot.isPaused {
                startTicker()
            }
            updateIdleTimerPolicy()
        }
    }

    func start() {
        guard store.activeTimer == nil else {
            if isPaused { resume() }
            return
        }

        let task = store.task(for: selectedTaskID)
        let taskTitle = task?.title ?? "自由专注"
        let category = task?.category ?? "自由"
        let planned = store.settings.seconds(for: mode)
        let now = Date()
        let snapshot = ActiveTimerSnapshot(
            sessionID: UUID(),
            mode: mode,
            taskID: task?.id,
            taskTitle: taskTitle,
            category: category,
            startedAt: now,
            endAt: now.addingTimeInterval(TimeInterval(planned)),
            plannedSeconds: planned,
            remainingWhenPaused: planned,
            isPaused: false,
            roundIndex: roundIndex,
            tintHex: task?.accentHex ?? mode.tintHex
        )

        store.activeTimer = snapshot
        apply(snapshot)
        startTicker()
        updateIdleTimerPolicy()
        activateSystemSurfaces(for: snapshot)
    }

    func pause() {
        guard var snapshot = store.activeTimer, !snapshot.isPaused else { return }
        ticker?.invalidate()
        ticker = nil
        let remaining = max(1, Int(ceil(snapshot.endAt.timeIntervalSinceNow)))
        snapshot.remainingWhenPaused = remaining
        snapshot.isPaused = true
        store.activeTimer = snapshot
        apply(snapshot)
        notifications.cancel(identifier: snapshot.sessionID.uuidString)
        updateIdleTimerPolicy()
        Task { await liveActivities.update(with: snapshot, remainingSeconds: remaining) }
    }

    func resume() {
        guard var snapshot = store.activeTimer, snapshot.isPaused else { return }
        snapshot.isPaused = false
        snapshot.endAt = Date().addingTimeInterval(TimeInterval(snapshot.remainingWhenPaused))
        store.activeTimer = snapshot
        apply(snapshot)
        startTicker()
        updateIdleTimerPolicy()
        activateSystemSurfaces(for: snapshot)
    }

    func stop(markIncomplete: Bool = true) {
        guard let snapshot = store.activeTimer else { return }
        ticker?.invalidate()
        ticker = nil
        let actual = max(0, Int(Date().timeIntervalSince(snapshot.startedAt)))
        if markIncomplete && actual >= 60 {
            store.recordSession(
                FocusSession(
                    taskID: snapshot.taskID,
                    taskTitle: snapshot.taskTitle,
                    category: snapshot.category,
                    mode: snapshot.mode,
                    startedAt: snapshot.startedAt,
                    endedAt: Date(),
                    plannedSeconds: snapshot.plannedSeconds,
                    actualSeconds: min(actual, snapshot.plannedSeconds),
                    completed: false
                )
            )
        }
        notifications.cancel(identifier: snapshot.sessionID.uuidString)
        store.activeTimer = nil
        resetRuntimeState(nextMode: mode)
        updateIdleTimerPolicy()
        Task { await liveActivities.end(immediate: true) }
    }

    func finishCurrentTask() {
        guard let snapshot = store.activeTimer else { return }
        ticker?.invalidate()
        ticker = nil
        let endedAt = Date()
        let actual = max(1, Int(endedAt.timeIntervalSince(snapshot.startedAt)))
        store.recordSession(
            FocusSession(
                taskID: snapshot.taskID,
                taskTitle: snapshot.taskTitle,
                category: snapshot.category,
                mode: snapshot.mode,
                startedAt: snapshot.startedAt,
                endedAt: endedAt,
                plannedSeconds: snapshot.plannedSeconds,
                actualSeconds: actual,
                completed: true
            )
        )
        if snapshot.mode == .focus {
            _ = store.finishTask(snapshot.taskID)
        }
        notifications.cancel(identifier: snapshot.sessionID.uuidString)
        store.activeTimer = nil
        resetRuntimeState(nextMode: .focus)
        updateIdleTimerPolicy()
        Task { await liveActivities.end(immediate: true) }
    }

    func skipToNextSession() {
        guard let snapshot = store.activeTimer else { return }
        ticker?.invalidate()
        ticker = nil
        notifications.cancel(identifier: snapshot.sessionID.uuidString)
        store.activeTimer = nil
        Task { await liveActivities.end(immediate: true) }

        let nextMode = nextMode(after: snapshot.mode, completedRoundIndex: snapshot.roundIndex)
        if snapshot.mode == .focus {
            roundIndex = snapshot.roundIndex + 1
        }
        resetRuntimeState(nextMode: nextMode)
        updateIdleTimerPolicy()
    }

    private func restoreFromStore() {
        guard let snapshot = store.activeTimer else {
            syncIdleDuration()
            return
        }
        apply(snapshot)
        if !snapshot.isPaused && snapshot.endAt <= Date() {
            completeCurrentSession(playSound: false)
        } else if !snapshot.isPaused {
            startTicker()
            updateIdleTimerPolicy()
            Task { await liveActivities.update(with: snapshot, remainingSeconds: remainingSeconds) }
        }
    }

    private func apply(_ snapshot: ActiveTimerSnapshot) {
        mode = snapshot.mode
        selectedTaskID = snapshot.taskID
        currentTaskTitle = snapshot.taskTitle
        plannedSeconds = snapshot.plannedSeconds
        roundIndex = snapshot.roundIndex
        isRunning = true
        isPaused = snapshot.isPaused
        remainingSeconds = snapshot.isPaused
            ? snapshot.remainingWhenPaused
            : max(0, Int(ceil(snapshot.endAt.timeIntervalSinceNow)))
    }

    private func startTicker() {
        ticker?.invalidate()
        ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        if let ticker {
            RunLoop.main.add(ticker, forMode: .common)
        }
    }

    private func tick() {
        guard let snapshot = store.activeTimer else {
            ticker?.invalidate()
            ticker = nil
            return
        }

        guard !snapshot.isPaused else {
            remainingSeconds = snapshot.remainingWhenPaused
            return
        }

        remainingSeconds = max(0, Int(ceil(snapshot.endAt.timeIntervalSinceNow)))
        if remainingSeconds <= 0 {
            completeCurrentSession(playSound: true)
        } else if Date().timeIntervalSince(lastLiveActivityUpdate) > 15 {
            lastLiveActivityUpdate = Date()
            Task { await liveActivities.update(with: snapshot, remainingSeconds: remainingSeconds) }
        }
    }

    private func completeCurrentSession(playSound: Bool) {
        guard let snapshot = store.activeTimer else { return }
        ticker?.invalidate()
        ticker = nil

        let endedAt = max(Date(), snapshot.endAt)
        store.recordSession(
            FocusSession(
                taskID: snapshot.taskID,
                taskTitle: snapshot.taskTitle,
                category: snapshot.category,
                mode: snapshot.mode,
                startedAt: snapshot.startedAt,
                endedAt: endedAt,
                plannedSeconds: snapshot.plannedSeconds,
                actualSeconds: snapshot.plannedSeconds,
                completed: true
            )
        )

        if snapshot.mode == .focus,
           let updatedTask = store.incrementRound(for: snapshot.taskID),
           updatedTask.isDone {
            notifications.cancelTaskReminder(taskID: updatedTask.id)
        }

        if playSound {
            notifications.playCompletionAlert(
                soundVolume: store.settings.soundEnabled ? store.settings.soundVolume : 0,
                vibrationEnabled: store.settings.vibrationEnabled
            )
        }
        notifications.cancel(identifier: snapshot.sessionID.uuidString)
        store.activeTimer = nil
        Task { await liveActivities.end() }

        let nextMode = nextMode(after: snapshot.mode, completedRoundIndex: snapshot.roundIndex)
        if snapshot.mode == .focus {
            roundIndex = snapshot.roundIndex + 1
        }
        resetRuntimeState(nextMode: nextMode)
        updateIdleTimerPolicy()

        if shouldAutoStart(after: snapshot.mode) {
            start()
        }
    }

    private func resetRuntimeState(nextMode: TimerMode) {
        isRunning = false
        isPaused = false
        mode = nextMode
        currentTaskTitle = store.task(for: selectedTaskID)?.title ?? "自由专注"
        plannedSeconds = store.settings.seconds(for: nextMode)
        remainingSeconds = plannedSeconds
    }

    private func updateIdleTimerPolicy() {
        UIApplication.shared.isIdleTimerDisabled = store.settings.keepScreenAwake && isRunning && !isPaused
    }

    private func nextMode(after completedMode: TimerMode) -> TimerMode {
        nextMode(after: completedMode, completedRoundIndex: roundIndex)
    }

    private func nextMode(after completedMode: TimerMode, completedRoundIndex: Int) -> TimerMode {
        switch completedMode {
        case .focus:
            let completedRoundNumber = completedRoundIndex + 1
            return completedRoundNumber % max(1, store.settings.roundsBeforeLongBreak) == 0 ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            return .focus
        }
    }

    private func shouldAutoStart(after completedMode: TimerMode) -> Bool {
        switch completedMode {
        case .focus:
            return store.settings.autoStartBreaks
        case .shortBreak, .longBreak:
            return store.settings.autoStartFocus
        }
    }

    private func activateSystemSurfaces(for snapshot: ActiveTimerSnapshot) {
        Task {
            if store.settings.notificationsEnabled {
                await notifications.scheduleCompletion(
                    identifier: snapshot.sessionID.uuidString,
                    mode: snapshot.mode,
                    taskTitle: snapshot.taskTitle,
                    nextMode: nextMode(after: snapshot.mode, completedRoundIndex: snapshot.roundIndex),
                    endDate: snapshot.endAt,
                    soundEnabled: store.settings.soundEnabled && store.settings.soundVolume > 0
                )
            }

            if store.settings.liveActivityEnabled {
                await liveActivities.start(for: snapshot)
            }
        }
    }
}

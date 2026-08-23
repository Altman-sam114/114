import Combine
import Foundation
#if os(iOS)
import UIKit
#endif

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
    private let notifications: TimerNotificationServicing
    private let liveActivities: TimerLiveActivityServicing
    private var ticker: Timer?
    private var lastLiveActivityUpdate = Date.distantPast
    private var activeTaskStartMode: TaskStartMode?
    private var systemSurfaceGeneration: UInt64 = 0
    private var notificationTask: Task<Void, Never>?
    private var liveActivityTask: Task<Void, Never>?
    private var cancellableNotificationTask: Task<Void, Never>?
    private var cancellableLiveActivityTask: Task<Void, Never>?
    private var cancellables: Set<AnyCancellable> = []

    init(store: FocusStore, notifications: TimerNotificationServicing, liveActivities: TimerLiveActivityServicing) {
        self.store = store
        self.notifications = notifications
        self.liveActivities = liveActivities
        restoreFromStore()
        observeTaskChanges()
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
        mode == .focus && activeTaskStartMode == .openEnded
    }

    func selectMode(_ newMode: TimerMode) {
        guard !isRunning else { return }
        mode = newMode
        syncIdleDuration()
    }

    func selectTask(_ task: FocusTask?) {
        guard !isRunning else { return }
        guard let requestedID = task?.id else {
            setIdleSelectedTask(nil)
            return
        }
        guard let currentTask = store.startableTask(for: requestedID) else {
            reconcileIdleSelectedTask()
            return
        }
        setIdleSelectedTask(currentTask)
    }

    func startPlanItem(_ item: PomodoroPlanItem) {
        guard !isRunning else { return }
        guard let task = store.startableTask(for: item.taskID) else {
            reconcileIdleSelectedTask()
            return
        }
        mode = .focus
        setIdleSelectedTask(task)
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
        reconcileIdleSelectedTask()
        plannedSeconds = store.settings.seconds(for: mode)
        remainingSeconds = plannedSeconds
    }

    func reconcileIdleSelectedTask() {
        guard !isRunning, !isPaused else { return }
        guard let selectedTaskID else {
            setIdleSelectedTask(nil)
            return
        }
        guard let task = store.startableTask(for: selectedTaskID) else {
            setIdleSelectedTask(nil)
            return
        }
        setIdleSelectedTask(task)
    }

    func handleSettingsChange() {
        updateIdleTimerPolicy()
        let generation = advanceSystemSurfaceGeneration()
        guard let snapshot = store.activeTimer else {
            syncIdleDuration()
            enqueueLiveActivityEnd(immediate: true, generation: generation)
            return
        }

        let notificationsEnabled = store.settings.notificationsEnabled && !snapshot.isPaused
        let soundEnabled = store.settings.soundEnabled && store.settings.soundVolume > 0
        let nextMode = nextMode(after: snapshot.mode, completedRoundIndex: snapshot.roundIndex)
        if notificationsEnabled {
            let notifications = self.notifications
            enqueueNotificationOperation(snapshot: snapshot, generation: generation) {
                await notifications.scheduleCompletion(
                    identifier: snapshot.sessionID.uuidString,
                    mode: snapshot.mode,
                    taskTitle: snapshot.taskTitle,
                    nextMode: nextMode,
                    endDate: snapshot.endAt,
                    soundEnabled: soundEnabled
                )
            }
        } else {
            cancelNotification(for: snapshot)
        }

        if store.settings.liveActivityEnabled {
            let liveActivities = self.liveActivities
            enqueueLiveActivityOperation(snapshot: snapshot, generation: generation) {
                await liveActivities.start(for: snapshot)
            }
        } else {
            enqueueLiveActivityEnd(immediate: true, generation: generation)
        }
    }

    func refreshFromClock() {
        guard let snapshot = store.activeTimer else {
            syncIdleDuration()
            let generation = advanceSystemSurfaceGeneration()
            enqueueLiveActivityEnd(immediate: true, generation: generation)
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
            if snapshot.isPaused {
                cancelNotification(for: snapshot)
            }
            syncLiveActivity(
                snapshot: snapshot,
                remainingSeconds: remainingSeconds,
                generation: systemSurfaceGeneration
            )
        }
    }

    func start() {
        guard store.activeTimer == nil else {
            if isPaused { resume() }
            return
        }

        let generation = advanceSystemSurfaceGeneration()
        reconcileIdleSelectedTask()
        let task = store.startableTask(for: selectedTaskID)
        activeTaskStartMode = mode == .focus ? task?.startMode : nil
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
            tintHex: task.map { store.representativeAccentHex(for: $0.category, preferred: $0.accentHex) } ?? mode.tintHex
        )

        store.activeTimer = snapshot
        apply(snapshot)
        startTicker()
        updateIdleTimerPolicy()
        activateSystemSurfaces(for: snapshot, generation: generation)
    }

    func pause() {
        guard var snapshot = store.activeTimer, !snapshot.isPaused else { return }
        let generation = advanceSystemSurfaceGeneration()
        ticker?.invalidate()
        ticker = nil
        let remaining = max(1, Int(ceil(snapshot.endAt.timeIntervalSinceNow)))
        snapshot.remainingWhenPaused = remaining
        snapshot.isPaused = true
        store.activeTimer = snapshot
        apply(snapshot)
        cancelNotification(for: snapshot)
        updateIdleTimerPolicy()
        syncLiveActivity(snapshot: snapshot, remainingSeconds: remaining, generation: generation)
    }

    func resume() {
        guard var snapshot = store.activeTimer, snapshot.isPaused else { return }
        let generation = advanceSystemSurfaceGeneration()
        snapshot.isPaused = false
        snapshot.endAt = Date().addingTimeInterval(TimeInterval(snapshot.remainingWhenPaused))
        store.activeTimer = snapshot
        apply(snapshot)
        startTicker()
        updateIdleTimerPolicy()
        activateSystemSurfaces(for: snapshot, generation: generation)
    }

    func stop(markIncomplete: Bool = true) {
        guard let snapshot = store.activeTimer else { return }
        let generation = advanceSystemSurfaceGeneration()
        ticker?.invalidate()
        ticker = nil
        let actual = activeElapsedSeconds(for: snapshot)
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
        cancelNotification(for: snapshot)
        store.activeTimer = nil
        resetRuntimeState(nextMode: mode)
        updateIdleTimerPolicy()
        enqueueLiveActivityEnd(immediate: true, generation: generation)
    }

    func finishCurrentTask() {
        guard let snapshot = store.activeTimer else { return }
        let generation = advanceSystemSurfaceGeneration()
        ticker?.invalidate()
        ticker = nil
        let endedAt = Date()
        let actual = max(1, activeElapsedSeconds(for: snapshot, at: endedAt))
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
            _ = store.finishActiveTask(snapshot.taskID)
        }
        cancelNotification(for: snapshot)
        store.activeTimer = nil
        resetRuntimeState(nextMode: .focus)
        updateIdleTimerPolicy()
        enqueueLiveActivityEnd(immediate: true, generation: generation)
    }

    func skipToNextSession() {
        guard let snapshot = store.activeTimer else { return }
        let generation = advanceSystemSurfaceGeneration()
        ticker?.invalidate()
        ticker = nil
        cancelNotification(for: snapshot)
        store.activeTimer = nil
        enqueueLiveActivityEnd(immediate: true, generation: generation)

        let nextMode = nextMode(after: snapshot.mode, completedRoundIndex: snapshot.roundIndex)
        if snapshot.mode == .focus {
            roundIndex = snapshot.roundIndex + 1
        }
        resetRuntimeState(nextMode: nextMode)
        updateIdleTimerPolicy()
    }

    private func restoreFromStore() {
        guard var snapshot = store.activeTimer else {
            syncIdleDuration()
            let generation = advanceSystemSurfaceGeneration()
            enqueueLiveActivityEnd(immediate: true, generation: generation)
            return
        }
        let fallbackTint = snapshot.taskID == nil
            ? snapshot.mode.tintHex
            : store.representativeAccentHex(for: snapshot.category)
        let normalizedTint = TaskCategoryPreset.usableAccentHex(snapshot.tintHex) ?? fallbackTint
        if snapshot.tintHex != normalizedTint {
            snapshot.tintHex = normalizedTint
            store.activeTimer = snapshot
        }
        activeTaskStartMode = snapshot.mode == .focus ? store.task(for: snapshot.taskID)?.startMode : nil
        apply(snapshot)
        if !snapshot.isPaused && snapshot.endAt <= Date() {
            completeCurrentSession(playSound: false)
        } else {
            if !snapshot.isPaused {
                startTicker()
            }
            updateIdleTimerPolicy()
            if snapshot.isPaused {
                cancelNotification(for: snapshot)
                syncLiveActivity(
                    snapshot: snapshot,
                    remainingSeconds: snapshot.remainingWhenPaused,
                    generation: systemSurfaceGeneration
                )
            } else {
                activateSystemSurfaces(for: snapshot, generation: systemSurfaceGeneration)
            }
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
        } else if store.settings.liveActivityEnabled && Date().timeIntervalSince(lastLiveActivityUpdate) > 15 {
            lastLiveActivityUpdate = Date()
            let generation = systemSurfaceGeneration
            let remaining = remainingSeconds
            syncLiveActivity(snapshot: snapshot, remainingSeconds: remaining, generation: generation)
        }
    }

    private func completeCurrentSession(playSound: Bool) {
        guard let snapshot = store.activeTimer else { return }
        let generation = advanceSystemSurfaceGeneration()
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
           let updatedTask = store.incrementActiveTaskRound(for: snapshot.taskID),
           updatedTask.isDone {
            notifications.cancelTaskReminder(taskID: updatedTask.id)
        }

        if playSound {
            notifications.playCompletionAlert(
                soundVolume: store.settings.soundEnabled ? store.settings.soundVolume : 0,
                vibrationEnabled: store.settings.vibrationEnabled,
                completionSound: store.settings.completionSound
            )
        }
        cancelNotification(for: snapshot)
        store.activeTimer = nil
        enqueueLiveActivityEnd(immediate: false, generation: generation)

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
        activeTaskStartMode = nil
        mode = nextMode
        reconcileIdleSelectedTask()
        plannedSeconds = store.settings.seconds(for: nextMode)
        remainingSeconds = plannedSeconds
    }

    private func observeTaskChanges() {
        store.$tasks
            .dropFirst()
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.reconcileIdleSelectedTask()
                }
            }
            .store(in: &cancellables)
    }

    private func setIdleSelectedTask(_ task: FocusTask?) {
        selectedTaskID = task?.id
        currentTaskTitle = task?.title ?? "自由专注"
    }

    private func updateIdleTimerPolicy() {
#if os(iOS)
        UIApplication.shared.isIdleTimerDisabled = store.settings.keepScreenAwake && isRunning && !isPaused
#endif
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

    private func activeElapsedSeconds(for snapshot: ActiveTimerSnapshot, at date: Date = Date()) -> Int {
        let remaining = snapshot.isPaused
            ? snapshot.remainingWhenPaused
            : max(0, Int(ceil(snapshot.endAt.timeIntervalSince(date))))
        return min(snapshot.plannedSeconds, max(0, snapshot.plannedSeconds - remaining))
    }

    private func shouldAutoStart(after completedMode: TimerMode) -> Bool {
        switch completedMode {
        case .focus:
            return store.settings.autoStartBreaks
        case .shortBreak, .longBreak:
            return store.settings.autoStartFocus
        }
    }

    private func advanceSystemSurfaceGeneration() -> UInt64 {
        systemSurfaceGeneration &+= 1
        cancellableNotificationTask?.cancel()
        cancellableLiveActivityTask?.cancel()
        cancellableNotificationTask = nil
        cancellableLiveActivityTask = nil
        return systemSurfaceGeneration
    }

    private func isCurrentSystemSurface(snapshot: ActiveTimerSnapshot, generation: UInt64) -> Bool {
        generation == systemSurfaceGeneration && store.activeTimer == snapshot
    }

    private func enqueueNotificationOperation(
        snapshot: ActiveTimerSnapshot? = nil,
        generation: UInt64? = nil,
        cancelOnInvalidation: Bool = true,
        operation: @escaping @MainActor () async -> Void
    ) {
        let previous = notificationTask
        let task = Task { @MainActor [weak self] in
            if let previous {
                await previous.value
            }
            guard let self, !Task.isCancelled else { return }
            if let snapshot, let generation {
                guard self.isCurrentSystemSurface(snapshot: snapshot, generation: generation) else { return }
            } else {
                guard snapshot == nil, generation == nil else { return }
            }
            await operation()
            guard !Task.isCancelled else { return }
            if let snapshot, let generation {
                guard self.isCurrentSystemSurface(snapshot: snapshot, generation: generation) else { return }
            }
        }
        notificationTask = task
        if cancelOnInvalidation {
            cancellableNotificationTask = task
        }
    }

    private func enqueueLiveActivityOperation(
        snapshot: ActiveTimerSnapshot? = nil,
        generation: UInt64? = nil,
        cancelOnInvalidation: Bool = true,
        operation: @escaping @MainActor () async -> Void
    ) {
        let previous = liveActivityTask
        let task = Task { @MainActor [weak self] in
            if let previous {
                await previous.value
            }
            guard let self, !Task.isCancelled else { return }
            if let generation {
                guard self.systemSurfaceGeneration == generation else { return }
                if let snapshot {
                    guard self.isCurrentSystemSurface(snapshot: snapshot, generation: generation) else { return }
                }
            } else {
                guard snapshot == nil else { return }
            }
            await operation()
            guard !Task.isCancelled else { return }
            if let generation {
                guard self.systemSurfaceGeneration == generation else { return }
                if let snapshot {
                    guard self.isCurrentSystemSurface(snapshot: snapshot, generation: generation) else { return }
                }
            } else {
                guard snapshot == nil else { return }
            }
        }
        liveActivityTask = task
        if cancelOnInvalidation {
            cancellableLiveActivityTask = task
        }
    }

    private func cancelNotification(for snapshot: ActiveTimerSnapshot) {
        let identifier = snapshot.sessionID.uuidString
        notifications.cancel(identifier: identifier)
        let notifications = self.notifications
        enqueueNotificationOperation(cancelOnInvalidation: false) {
            notifications.cancel(identifier: identifier)
        }
    }

    private func enqueueLiveActivityEnd(immediate: Bool, generation: UInt64) {
        let liveActivities = self.liveActivities
        enqueueLiveActivityOperation(generation: generation, cancelOnInvalidation: false) {
            await liveActivities.end(immediate: immediate)
        }
    }

    private func syncLiveActivity(snapshot: ActiveTimerSnapshot, remainingSeconds: Int, generation: UInt64) {
        guard store.settings.liveActivityEnabled else {
            enqueueLiveActivityEnd(immediate: true, generation: generation)
            return
        }

        let liveActivities = self.liveActivities
        enqueueLiveActivityOperation(snapshot: snapshot, generation: generation) {
            await liveActivities.update(with: snapshot, remainingSeconds: remainingSeconds)
        }
    }

    private func activateSystemSurfaces(for snapshot: ActiveTimerSnapshot, generation: UInt64) {
        if store.settings.notificationsEnabled && !snapshot.isPaused {
            let notifications = self.notifications
            let nextMode = nextMode(after: snapshot.mode, completedRoundIndex: snapshot.roundIndex)
            let soundEnabled = store.settings.soundEnabled && store.settings.soundVolume > 0
            enqueueNotificationOperation(snapshot: snapshot, generation: generation) {
                await notifications.scheduleCompletion(
                    identifier: snapshot.sessionID.uuidString,
                    mode: snapshot.mode,
                    taskTitle: snapshot.taskTitle,
                    nextMode: nextMode,
                    endDate: snapshot.endAt,
                    soundEnabled: soundEnabled
                )
            }
        }

        if store.settings.liveActivityEnabled {
            let liveActivities = self.liveActivities
            enqueueLiveActivityOperation(snapshot: snapshot, generation: generation) {
                await liveActivities.start(for: snapshot)
            }
        } else {
            enqueueLiveActivityEnd(immediate: true, generation: generation)
        }
    }
}

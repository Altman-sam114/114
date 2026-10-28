import SwiftUI

struct TimerHandoffRequest: Identifiable, Equatable {
    let id: UUID
    let category: String
    let preferredTaskID: UUID?

    init(id: UUID = UUID(), category: String, preferredTaskID: UUID? = nil) {
        self.id = id
        self.category = category
        self.preferredTaskID = preferredTaskID
    }
}

struct DashboardView: View {
    @EnvironmentObject private var store: FocusStore
    @EnvironmentObject private var notifications: NotificationService
    @EnvironmentObject private var premium: PremiumAccessService
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: AppTab = .timer
    @State private var timerHandoffRequest: TimerHandoffRequest?

    // The tab shell issues lifecycle commands but does not render the engine's 1 Hz output.
    let engine: TimerEngine

    var body: some View {
        TabView(selection: $selectedTab) {
            TimerView(
                timerHandoffRequest: timerHandoffRequest,
                onConsumeTimerHandoff: consumeTimerHandoff
            )
                .tabItem { Label("计时", systemImage: "timer") }
                .tag(AppTab.timer)

            ScheduleView(onTimerHandoff: requestTimerHandoff)
                .tabItem { Label("日程", systemImage: "calendar") }
                .tag(AppTab.schedule)

            AnalyticsView()
                .tabItem { Label("分析", systemImage: "chart.xyaxis.line") }
                .tag(AppTab.analytics)

            SettingsView()
                .tabItem { Label("设置", systemImage: "slider.horizontal.3") }
                .tag(AppTab.settings)
        }
        .tint(AppTheme.readableTint(.cyan))
        .background(AppTheme.background.ignoresSafeArea())
        .task {
            await notifications.refreshAuthorizationStatus()
            await premium.refreshEntitlements()
            enforceCompletionSoundAccess()
            engine.checkScheduledAutoStart()
        }
        .onChange(of: premium.isProUnlocked) { _, _ in
            enforceCompletionSoundAccess()
        }
        .onChange(of: store.settings.completionSound) { _, _ in
            enforceCompletionSoundAccess()
        }
        .onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { _ in
            engine.checkScheduledAutoStart()
        }
        .onChange(of: store.settings) { oldSettings, newSettings in
            engine.handleSettingsChange()
            syncTaskDueRemindersIfNeeded(oldSettings: oldSettings, newSettings: newSettings)
            syncPomodoroPlanIfNeeded(oldSettings: oldSettings, newSettings: newSettings)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                engine.refreshFromClock()
                engine.checkScheduledAutoStart()
                Task {
                    await notifications.refreshAuthorizationStatus()
                    await premium.refreshEntitlements()
                    enforceCompletionSoundAccess()
                }
            }
        }
    }

    private func requestTimerHandoff(_ request: TimerHandoffRequest) {
        timerHandoffRequest = request
        selectedTab = .timer
    }

    private func consumeTimerHandoff(id: UUID) {
        guard timerHandoffRequest?.id == id else { return }
        timerHandoffRequest = nil
    }

    private func enforceCompletionSoundAccess() {
        if !premium.isProUnlocked && store.settings.completionSound.isPro {
            store.settings.completionSound = .chime
        }
    }

    private func syncTaskDueRemindersIfNeeded(oldSettings: TimerSettings, newSettings: TimerSettings) {
        let changedReminderPolicy = oldSettings.notificationsEnabled != newSettings.notificationsEnabled
            || oldSettings.taskDueRemindersEnabled != newSettings.taskDueRemindersEnabled
            || oldSettings.soundEnabled != newSettings.soundEnabled
        guard changedReminderPolicy else { return }

        let enabled = newSettings.notificationsEnabled && newSettings.taskDueRemindersEnabled
        Task {
            await notifications.syncTaskDueReminders(
                for: store.tasks,
                enabled: enabled,
                soundEnabled: newSettings.soundEnabled
            )
        }
    }

    private func syncPomodoroPlanIfNeeded(oldSettings: TimerSettings, newSettings: TimerSettings) {
        let changedPlanPolicy = oldSettings.autoGeneratePomodoroPlan != newSettings.autoGeneratePomodoroPlan
            || oldSettings.focusMinutes != newSettings.focusMinutes
            || oldSettings.shortBreakMinutes != newSettings.shortBreakMinutes
            || oldSettings.longBreakMinutes != newSettings.longBreakMinutes
            || oldSettings.roundsBeforeLongBreak != newSettings.roundsBeforeLongBreak
        guard changedPlanPolicy else { return }

        if newSettings.autoGeneratePomodoroPlan {
            store.generatePomodoroPlanFromSchedule()
        } else {
            store.clearPomodoroPlan()
        }
    }
}

private enum AppTab {
    case timer
    case schedule
    case analytics
    case settings
}

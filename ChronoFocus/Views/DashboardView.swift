import SwiftUI
import UIKit

struct DashboardView: View {
    @EnvironmentObject private var store: FocusStore
    @EnvironmentObject private var engine: TimerEngine
    @EnvironmentObject private var notifications: NotificationService
    @EnvironmentObject private var premium: PremiumAccessService
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab: AppTab = .timer

    var body: some View {
        TabView(selection: $selectedTab) {
            TimerView()
                .tabItem { Label("计时", systemImage: "timer") }
                .tag(AppTab.timer)

            ScheduleView()
                .tabItem { Label("日程", systemImage: "calendar") }
                .tag(AppTab.schedule)

            AnalyticsView()
                .tabItem { Label("分析", systemImage: "chart.xyaxis.line") }
                .tag(AppTab.analytics)

            SettingsView()
                .tabItem { Label("设置", systemImage: "slider.horizontal.3") }
                .tag(AppTab.settings)
        }
        .tint(.cyan)
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

enum AppTheme {
    static let background = LinearGradient(
        colors: [
            dynamicColor(dark: UIColor(red: 0.03, green: 0.04, blue: 0.06, alpha: 1), light: UIColor(red: 0.96, green: 0.98, blue: 1.00, alpha: 1)),
            dynamicColor(dark: UIColor(red: 0.02, green: 0.07, blue: 0.09, alpha: 1), light: UIColor(red: 0.91, green: 0.98, blue: 0.97, alpha: 1)),
            dynamicColor(dark: UIColor(red: 0.08, green: 0.06, blue: 0.10, alpha: 1), light: UIColor(red: 0.98, green: 0.96, blue: 1.00, alpha: 1))
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let panel = dynamicColor(dark: UIColor.white.withAlphaComponent(0.075), light: UIColor.white.withAlphaComponent(0.72))
    static let panelStrong = dynamicColor(dark: UIColor.white.withAlphaComponent(0.12), light: UIColor.white.withAlphaComponent(0.92))
    static let border = dynamicColor(dark: UIColor.white.withAlphaComponent(0.12), light: UIColor.black.withAlphaComponent(0.08))
    static let primaryText = dynamicColor(dark: .white, light: UIColor(red: 0.06, green: 0.08, blue: 0.12, alpha: 1))
    static let secondaryText = dynamicColor(dark: UIColor.white.withAlphaComponent(0.64), light: UIColor(red: 0.28, green: 0.33, blue: 0.42, alpha: 1))

    private static func dynamicColor(dark: UIColor, light: UIColor) -> Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? dark : light
        })
    }
}

struct GlassPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(.ultraThinMaterial.opacity(0.55), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            }
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    let symbol: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text(value)
                .font(.system(size: 23, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        }
    }
}

import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject private var store: FocusStore
    @EnvironmentObject private var notifications: NotificationService
    @EnvironmentObject private var premium: PremiumAccessService

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    durationPanel
                    automationPanel
                    premiumPanel
                    systemPanel
                }
                .padding(18)
                .padding(.bottom, 26)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("设置")
        }
    }

    private var durationPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 16) {
                Label("每轮时间", systemImage: "dial.medium")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)

                DurationStepper(title: "专注", value: $store.settings.focusMinutes, range: 1...180, tint: .cyan)
                DurationStepper(title: "短休", value: $store.settings.shortBreakMinutes, range: 1...60, tint: .orange)
                DurationStepper(title: "长休", value: $store.settings.longBreakMinutes, range: 1...90, tint: .purple)
                DurationStepper(title: "长休间隔", value: $store.settings.roundsBeforeLongBreak, range: 2...12, suffix: "轮", tint: .mint)
                DurationStepper(title: "每日目标", value: $store.settings.dailyGoalMinutes, range: 15...720, tint: .blue)
            }
        }
    }

    private var automationPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                Label("自动化", systemImage: "bolt.horizontal.circle.fill")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)

                Toggle(isOn: $store.settings.autoStartBreaks) {
                    Label("专注结束后自动休息", systemImage: "forward.end.fill")
                }
                Toggle(isOn: $store.settings.autoStartFocus) {
                    Label("休息结束后自动专注", systemImage: "repeat")
                }
                Toggle(isOn: $store.settings.autoGeneratePomodoroPlan) {
                    Label("按日程自动生成番茄钟", systemImage: "calendar.badge.plus")
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: .cyan))
            .foregroundStyle(AppTheme.primaryText)
        }
    }

    private var systemPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                Label("后台与提醒", systemImage: "iphone.gen3.radiowaves.left.and.right")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)

                Toggle(isOn: $store.settings.notificationsEnabled) {
                    Label("到点通知", systemImage: "bell.badge.fill")
                }

                Toggle(isOn: $store.settings.soundEnabled) {
                    Label("到点铃声", systemImage: "speaker.wave.3.fill")
                }

                Toggle(isOn: $store.settings.taskDueRemindersEnabled) {
                    Label("日程到期提醒", systemImage: "calendar.badge.clock")
                }

                Toggle(isOn: $store.settings.liveActivityEnabled) {
                    Label("通知栏实时显示", systemImage: "livephoto")
                }

                HStack(spacing: 12) {
                    Image(systemName: notificationStatusIcon)
                        .foregroundStyle(notificationStatusColor)
                    Text(notificationStatusText)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                    Spacer()
                    if notifications.shouldShowAuthorizationAction {
                        Button(notifications.authorizationActionTitle) {
                            handleNotificationAuthorizationAction()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.cyan)
                    }
                }
                .padding(12)
                .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .toggleStyle(SwitchToggleStyle(tint: .cyan))
            .foregroundStyle(AppTheme.primaryText)
        }
    }

    private var premiumPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Pro 统计", systemImage: premium.isProUnlocked ? "checkmark.seal.fill" : "lock.fill")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)
                    Spacer()
                    Text(premium.isProUnlocked ? "已解锁" : premium.priceText)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(premium.isProUnlocked ? .mint : .cyan)
                }

                Text(premium.statusText)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 10) {
                    Button {
                        Task { await premium.purchasePro() }
                    } label: {
                        Label(premium.isProUnlocked ? "已解锁" : "解锁", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan)
                    .disabled(premium.isLoading || premium.isProUnlocked)

                    Button {
                        Task { await premium.restorePurchases() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .frame(width: 44, height: 34)
                    }
                    .buttonStyle(.bordered)
                    .tint(.mint)
                    .disabled(premium.isLoading)
                    .accessibilityLabel("恢复购买")
                }
            }
        }
    }

    private var notificationStatusIcon: String {
        switch notifications.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return "checkmark.circle.fill"
        case .denied: return "xmark.octagon.fill"
        case .notDetermined: return "questionmark.circle.fill"
        @unknown default: return "questionmark.circle.fill"
        }
    }

    private var notificationStatusColor: Color {
        switch notifications.authorizationStatus {
        case .authorized, .provisional, .ephemeral: return .mint
        case .denied: return .red
        case .notDetermined: return .orange
        @unknown default: return .orange
        }
    }

    private var notificationStatusText: String {
        switch notifications.authorizationStatus {
        case .authorized: return "通知权限已开启"
        case .provisional: return "临时通知权限已开启"
        case .ephemeral: return "临时通知可用"
        case .denied: return "系统中已关闭通知"
        case .notDetermined: return "尚未请求通知权限"
        @unknown default: return "通知状态未知"
        }
    }

    private func handleNotificationAuthorizationAction() {
        switch notifications.authorizationStatus {
        case .denied:
            notifications.openSystemSettings()
        case .notDetermined:
            Task { _ = await notifications.requestAuthorization() }
        default:
            break
        }
    }
}

private struct DurationStepper: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var suffix = "分钟"
    let tint: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
                Text("\(value) \(suffix)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }

            Spacer()

            Stepper("", value: $value, in: range)
                .labelsHidden()
                .tint(tint)
        }
        .padding(12)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

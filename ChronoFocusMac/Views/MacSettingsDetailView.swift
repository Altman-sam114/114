import SwiftUI
import UserNotifications

struct MacSettingsDetailView: View {
    @EnvironmentObject private var store: FocusStore
    @EnvironmentObject private var notifications: MacNotificationService
    @EnvironmentObject private var premium: MacPremiumAccessService
    @EnvironmentObject private var calendarSync: MacCalendarSyncService
    @Environment(\.macSnapshotRendering) private var isSnapshotRendering

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            MacPageHeaderView(
                title: "设置",
                subtitle: "Mac 版优先服务状态栏番茄钟和桌面通知体验。",
                symbolName: "slider.horizontal.3"
            )

            HStack(alignment: .top, spacing: 18) {
                MacGlassPanel {
                    VStack(alignment: .leading, spacing: 16) {
                        Label("每轮时间", systemImage: "dial.medium")
                            .font(.headline)
                            .foregroundStyle(MacTheme.primaryText)

                        MacDurationStepper(title: "专注", value: $store.settings.focusMinutes, range: 1...180)
                        MacDurationStepper(title: "短休", value: $store.settings.shortBreakMinutes, range: 1...60)
                        MacDurationStepper(title: "长休", value: $store.settings.longBreakMinutes, range: 1...90)
                        MacDurationStepper(title: "长休间隔", value: $store.settings.roundsBeforeLongBreak, range: 2...12, suffix: "轮")
                        MacDurationStepper(title: "每日目标", value: $store.settings.dailyGoalMinutes, range: 15...720)
                    }
                }

                MacGlassPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        Label("后台与提醒", systemImage: "bell.badge.fill")
                            .font(.headline)
                            .foregroundStyle(MacTheme.primaryText)

                        if isSnapshotRendering {
                            MacStaticToggleRowView(title: "到点通知", isOn: store.settings.notificationsEnabled)
                            MacStaticToggleRowView(title: "到点铃声", isOn: store.settings.soundEnabled)
                            MacStaticToggleRowView(title: "触觉反馈", isOn: store.settings.vibrationEnabled)
                            MacStaticToggleRowView(title: "日程到期提醒", isOn: store.settings.taskDueRemindersEnabled)
                            MacStaticToggleRowView(title: "专注后自动休息", isOn: store.settings.autoStartBreaks)
                            MacStaticToggleRowView(title: "休息后自动专注", isOn: store.settings.autoStartFocus)
                            MacStaticToggleRowView(title: "按日程自动生成番茄钟", isOn: store.settings.autoGeneratePomodoroPlan)
                        } else {
                            Toggle("到点通知", isOn: $store.settings.notificationsEnabled)
                            Toggle("到点铃声", isOn: $store.settings.soundEnabled)
                            Toggle("触觉反馈", isOn: $store.settings.vibrationEnabled)
                            Toggle("日程到期提醒", isOn: $store.settings.taskDueRemindersEnabled)
                            Toggle("专注后自动休息", isOn: $store.settings.autoStartBreaks)
                            Toggle("休息后自动专注", isOn: $store.settings.autoStartFocus)
                            Toggle("按日程自动生成番茄钟", isOn: $store.settings.autoGeneratePomodoroPlan)
                        }

                        Divider().opacity(0.35)

                        HStack {
                            Label(notificationStatusText, systemImage: notificationStatusIcon)
                                .foregroundStyle(notificationStatusColor)
                            Spacer()
                            if notifications.shouldShowAuthorizationAction {
                                Button(notifications.authorizationActionTitle, action: handleNotificationAuthorizationAction)
                                    .buttonStyle(.borderedProminent)
                                    .tint(.cyan)
                            }
                        }

                        if isSnapshotRendering {
                            MacStaticSliderView(title: "铃声音量", value: store.settings.soundVolume)
                        } else {
                            Slider(value: $store.settings.soundVolume, in: 0...1) {
                                Text("铃声音量")
                            } minimumValueLabel: {
                                Image(systemName: "speaker.slash.fill")
                            } maximumValueLabel: {
                                Image(systemName: "speaker.wave.3.fill")
                            }
                        }
                    }
                    .toggleStyle(.switch)
                }
            }

            MacGlassPanel {
                VStack(alignment: .leading, spacing: 12) {
                    Label("高级功能", systemImage: premium.isProUnlocked ? "checkmark.seal.fill" : "lock.fill")
                        .font(.headline)
                        .foregroundStyle(MacTheme.primaryText)

                    LabeledContent("Pro 状态") {
                        Text(premium.isProUnlocked ? "已解锁" : premium.priceText)
                            .foregroundStyle(premium.isProUnlocked ? Color.mint : Color.cyan)
                    }

                    LabeledContent("日历同步") {
                        Text(calendarSync.statusText)
                            .foregroundStyle(MacTheme.secondaryText)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        Button(premium.isProUnlocked ? "已解锁" : "解锁 Pro", systemImage: "sparkles") {
                            Task { await premium.purchasePro() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.cyan)
                        .disabled(premium.isLoading || premium.isProUnlocked)

                        Button("恢复购买", systemImage: "arrow.clockwise") {
                            Task { await premium.restorePurchases() }
                        }
                        .buttonStyle(.bordered)
                        .disabled(premium.isLoading)
                    }
                }
            }
        }
        .padding(24)
        .task {
            await notifications.refreshAuthorizationStatus()
            await premium.refreshEntitlements()
        }
        .onChange(of: store.settings) { oldSettings, newSettings in
            syncTaskDueRemindersIfNeeded(oldSettings: oldSettings, newSettings: newSettings)
            if newSettings.autoGeneratePomodoroPlan != oldSettings.autoGeneratePomodoroPlan {
                if newSettings.autoGeneratePomodoroPlan {
                    store.generatePomodoroPlanFromSchedule()
                } else {
                    store.clearPomodoroPlan()
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
}

private struct MacDurationStepper: View {
    @Environment(\.macSnapshotRendering) private var isSnapshotRendering

    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var suffix = "分钟"

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MacTheme.primaryText)
                Text("\(value) \(suffix)")
                    .font(.caption)
                    .foregroundStyle(MacTheme.secondaryText)
            }
            Spacer()
            if isSnapshotRendering {
                Text("\(value)")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.cyan)
            } else {
                Stepper(title, value: $value, in: range)
                    .labelsHidden()
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
    }
}

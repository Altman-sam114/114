import SwiftUI
import UserNotifications

struct MacSettingsDetailView: View {
    @EnvironmentObject private var store: FocusStore
    @EnvironmentObject private var engine: TimerEngine
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

            MacGlassPanel {
                HStack {
                    Label("外观", systemImage: store.settings.appThemeMode.symbolName)
                        .font(.headline)
                        .foregroundStyle(MacTheme.primaryText)
                    Spacer()
                    if isSnapshotRendering {
                        MacStaticSegmentedView(title: "主题", selectedTitle: store.settings.appThemeMode.title, options: AppThemeMode.allCases.map(\.title))
                    } else {
                        Picker("主题", selection: $store.settings.appThemeMode) {
                            ForEach(AppThemeMode.allCases) { mode in
                                Label(mode.title, systemImage: mode.symbolName).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 180)
                        .accessibilityValue(store.settings.appThemeMode.title)
                    }
                }
            }

            MacAdaptiveColumns {
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
                                .foregroundStyle(MacTheme.readableTint(notificationStatusColor))
                            Spacer()
                            if notifications.shouldShowAuthorizationAction {
                                if isSnapshotRendering {
                                    MacStaticSettingsActionChipView(
                                        title: notifications.authorizationActionTitle,
                                        symbolName: "bell.badge.fill",
                                        tint: .cyan,
                                        isProminent: true
                                    )
                                } else {
                                    Button(notifications.authorizationActionTitle, action: handleNotificationAuthorizationAction)
                                        .buttonStyle(.borderedProminent)
                                        .tint(.cyan)
                                }
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

                        Divider().opacity(0.35)
                        MacCompletionSoundPickerView()
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
                            .foregroundStyle(MacTheme.readableTint(premium.isProUnlocked ? .mint : .cyan))
                    }

                    LabeledContent("日历同步") {
                        Text(calendarSync.statusText)
                            .foregroundStyle(MacTheme.secondaryText)
                            .multilineTextAlignment(.trailing)
                    }

                    HStack {
                        if isSnapshotRendering {
                            MacStaticSettingsActionChipView(
                                title: premium.isProUnlocked ? "已解锁" : "解锁 Pro",
                                symbolName: "sparkles",
                                tint: .cyan,
                                isProminent: true
                            )
                            MacStaticSettingsActionChipView(title: "恢复购买", symbolName: "arrow.clockwise", tint: MacTheme.secondaryText, isProminent: false)
                        } else {
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
                    Text(premium.statusText)
                        .font(.caption)
                        .foregroundStyle(MacTheme.secondaryText)
                }
            }

            MacGlassPanel {
                VStack(alignment: .leading, spacing: 12) {
                    Label("数据与隐私", systemImage: "hand.raised.fill")
                        .font(.headline)
                        .foregroundStyle(MacTheme.primaryText)
                    Text("待办、计时记录和导入的日历内容保存在此设备。App 不会向开发者服务器上传这些内容；系统备份由你的系统设置管理。")
                    Text("桌面通知可能显示任务名称，可在系统设置中管理显示范围。购买和日历授权由 Apple 的系统服务处理。")
                }
                .font(.subheadline)
                .foregroundStyle(MacTheme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(24)
        .task {
            await notifications.refreshAuthorizationStatus()
            await premium.refreshEntitlements()
            if !premium.isProUnlocked && store.settings.completionSound.isPro {
                store.settings.completionSound = .chime
            }
        }
        .onChange(of: store.settings) { oldSettings, newSettings in
            engine.handleSettingsChange()
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

private struct MacStaticSettingsActionChipView: View {
    let title: String
    let symbolName: String
    let tint: Color
    let isProminent: Bool

    var body: some View {
        Label(title, systemImage: symbolName)
            .font(.subheadline.bold())
            .foregroundStyle(isProminent ? Color.black.opacity(0.82) : MacTheme.readableTint(tint))
            .frame(minHeight: 44)
            .padding(.horizontal, 10)
            .background(isProminent ? tint : MacTheme.inset, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(isProminent ? tint.opacity(0.9) : MacTheme.border, lineWidth: 1)
            }
            .accessibilityLabel(title)
    }
}

private struct MacCompletionSoundPickerView: View {
    @EnvironmentObject private var store: FocusStore
    @EnvironmentObject private var premium: MacPremiumAccessService
    @EnvironmentObject private var notifications: MacNotificationService
    @Environment(\.macSnapshotRendering) private var isSnapshotRendering

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Pro 铃声", systemImage: "music.note")
                    .font(.subheadline.bold())
                    .foregroundStyle(MacTheme.primaryText)
                Spacer()
                Text(premium.isProUnlocked ? "已解锁" : "Pro")
                    .font(.caption.bold())
                    .foregroundStyle(MacTheme.readableTint(premium.isProUnlocked ? .mint : .cyan))
            }

            if isSnapshotRendering {
                MacStaticSegmentedView(
                    title: "音色",
                    selectedTitle: store.settings.completionSound.title,
                    options: CompletionSound.allCases.map(\.title)
                )
            } else {
                Picker("音色", selection: $store.settings.completionSound) {
                    ForEach(CompletionSound.allCases) { sound in
                        Text(sound.title).tag(sound)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(!premium.isProUnlocked)
            }

            HStack {
                if isSnapshotRendering {
                    MacStaticSettingsActionChipView(title: "试听", symbolName: "speaker.wave.2.fill", tint: MacTheme.secondaryText, isProminent: false)
                    if !premium.isProUnlocked {
                        MacStaticSettingsActionChipView(title: "解锁 Pro", symbolName: "sparkles", tint: .cyan, isProminent: true)
                    }
                } else {
                    Button("试听", systemImage: "speaker.wave.2.fill", action: previewSound)
                        .buttonStyle(.bordered)
                        .disabled(!premium.isProUnlocked && store.settings.completionSound.isPro)

                    if !premium.isProUnlocked {
                        Button("解锁 Pro", systemImage: "sparkles") {
                            Task { await premium.purchasePro() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.cyan)
                        .disabled(premium.isLoading)
                    }
                }
            }
        }
        .onChange(of: premium.isProUnlocked) { _, isUnlocked in
            if !isUnlocked && store.settings.completionSound.isPro {
                store.settings.completionSound = .chime
            }
        }
    }

    private func previewSound() {
        guard premium.isProUnlocked || !store.settings.completionSound.isPro else { return }
        notifications.playCompletionAlert(
            soundVolume: store.settings.soundVolume,
            vibrationEnabled: false,
            completionSound: store.settings.completionSound
        )
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
                    .foregroundStyle(MacTheme.readableTint(.cyan))
            } else {
                Stepper(title, value: $value, in: range)
                    .labelsHidden()
            }
        }
        .padding(12)
        .background(MacTheme.inset, in: RoundedRectangle(cornerRadius: 8))
    }
}

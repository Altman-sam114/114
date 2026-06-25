import SwiftUI

struct MacMiniTimerView: View {
    @EnvironmentObject private var store: FocusStore
    @EnvironmentObject private var engine: TimerEngine
    @EnvironmentObject private var premium: MacPremiumAccessService
    @EnvironmentObject private var notifications: MacNotificationService
    @Environment(\.macSnapshotShowsQuickPanel) private var snapshotShowsQuickPanel
    @State private var isShowingQuickPanel = false

    let openDetails: () -> Void

    private var currentTint: Color {
        if let task = store.task(for: engine.selectedTaskID) {
            return Color(hex: task.accentHex)
        }
        return Color(hex: engine.mode.tintHex)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 18) {
                MacMiniHeaderView(isShowingQuickPanel: $isShowingQuickPanel)
                MacMiniClockView(currentTint: currentTint)
                MacMiniControlsView(currentTint: currentTint)
                MacMiniTaskPickerView(currentTint: currentTint)
            }

            if isShowingQuickPanel {
                MacMiniQuickPanelView(
                    currentTint: currentTint,
                    openDetails: {
                        isShowingQuickPanel = false
                        openDetails()
                    }
                )
                .padding(.top, 38)
                .transition(.move(edge: .trailing).combined(with: .opacity))
                .zIndex(2)
            }
        }
        .padding(20)
        .frame(width: isShowingQuickPanel ? 560 : 430, height: 500)
        .background(MacTheme.background)
        .animation(.smooth(duration: 0.22), value: isShowingQuickPanel)
        .onAppear {
            if snapshotShowsQuickPanel {
                isShowingQuickPanel = true
            }
        }
    }
}

private struct MacMiniHeaderView: View {
    @EnvironmentObject private var engine: TimerEngine
    @Binding var isShowingQuickPanel: Bool

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(engine.mode.title)
                    .font(.headline)
                    .foregroundStyle(MacTheme.primaryText)
                Text(engine.currentTaskTitle)
                    .font(.subheadline)
                    .foregroundStyle(MacTheme.secondaryText)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                isShowingQuickPanel.toggle()
            } label: {
                Text("...")
                    .font(.headline)
                    .monospaced()
                    .foregroundStyle(MacTheme.primaryText)
                    .frame(width: 28, height: 24)
                    .background(isShowingQuickPanel ? Color.white.opacity(0.18) : MacTheme.panel, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isShowingQuickPanel ? "关闭快捷面板" : "打开快捷面板")
        }
    }
}

private struct MacMiniClockView: View {
    @EnvironmentObject private var engine: TimerEngine

    let currentTint: Color

    var body: some View {
        VStack(spacing: 14) {
            Text(engine.formattedRemaining)
                .font(.system(size: 76, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(MacTheme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            MacMiniFlowProgressView(progress: engine.progress, tint: currentTint)

            Text(engine.isRunning ? (engine.isPaused ? "已暂停" : "专注中") : "准备开始")
                .font(.caption)
                .foregroundStyle(MacTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

}

private struct MacMiniFlowProgressView: View {
    let progress: Double
    let tint: Color

    private var clampedProgress: Double {
        min(1, max(0, progress))
    }

    var body: some View {
        VStack(spacing: 7) {
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.10))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [tint.opacity(0.92), .cyan, tint.opacity(0.72)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(12, proxy.size.width * clampedProgress))
                        .shadow(color: tint.opacity(0.35), radius: 8)
                    Circle()
                        .fill(Color.white.opacity(0.92))
                        .frame(width: 8, height: 8)
                        .offset(x: max(2, proxy.size.width * clampedProgress - 6))
                        .opacity(clampedProgress > 0 ? 1 : 0)
                }
            }
            .frame(width: 170, height: 10)
            .animation(.smooth(duration: 0.35), value: clampedProgress)

            HStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { index in
                    Circle()
                        .fill(dotColor(index: index))
                        .frame(width: 5, height: 5)
                }
            }
        }
    }

    private func dotColor(index: Int) -> Color {
        Double(index + 1) / 4 <= clampedProgress ? tint.opacity(0.9) : Color.white.opacity(0.18)
    }
}

private struct MacMiniControlsView: View {
    @EnvironmentObject private var engine: TimerEngine

    let currentTint: Color

    var body: some View {
        HStack(spacing: 12) {
            Button("停止", systemImage: "stop.fill") {
                engine.stop()
            }
            .labelStyle(.iconOnly)
            .buttonStyle(MacIconButtonStyle(tint: .red, filled: false))
            .disabled(!engine.isRunning)

            Button("跳过", systemImage: "forward.end.fill", action: engine.skipToNextSession)
                .labelStyle(.iconOnly)
                .buttonStyle(MacIconButtonStyle(tint: .orange, filled: false))
                .disabled(!engine.isRunning)

            Button(primaryTitle, systemImage: primarySymbol, action: toggleTimer)
                .labelStyle(.iconOnly)
                .buttonStyle(MacIconButtonStyle(tint: currentTint, filled: true, size: 74))
        }
    }

    private var primaryTitle: String {
        !engine.isRunning || engine.isPaused ? "开始" : "暂停"
    }

    private var primarySymbol: String {
        !engine.isRunning || engine.isPaused ? "play.fill" : "pause.fill"
    }

    private func toggleTimer() {
        if !engine.isRunning {
            engine.start()
        } else if engine.isPaused {
            engine.resume()
        } else {
            engine.pause()
        }
    }
}

private struct MacMiniTaskPickerView: View {
    @EnvironmentObject private var store: FocusStore
    @EnvironmentObject private var engine: TimerEngine

    let currentTint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("当前待办", systemImage: "target")
                    .font(.caption)
                    .foregroundStyle(MacTheme.secondaryText)
                Spacer()
                Text("\(store.upcomingTasks().count) 项")
                    .font(.caption)
                    .foregroundStyle(MacTheme.secondaryText)
            }

            ForEach(store.upcomingTasks().prefix(3)) { task in
                Button {
                    guard !engine.isRunning else { return }
                    engine.selectTask(task)
                } label: {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color(hex: task.accentHex))
                            .frame(width: 8, height: 8)
                        Text(task.title)
                            .font(.subheadline)
                            .foregroundStyle(MacTheme.primaryText)
                            .lineLimit(1)
                        Spacer()
                        Text(task.dueDate?.shortTimeText ?? task.category)
                            .font(.caption)
                            .foregroundStyle(MacTheme.secondaryText)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(rowBackground(for: task), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .disabled(engine.isRunning)
            }
        }
        .padding(12)
        .background(MacTheme.panel, in: RoundedRectangle(cornerRadius: 8))
    }

    private func rowBackground(for task: FocusTask) -> Color {
        engine.selectedTaskID == task.id ? currentTint.opacity(0.18) : Color.white.opacity(0.05)
    }
}

private struct MacMiniQuickPanelView: View {
    @EnvironmentObject private var store: FocusStore
    @EnvironmentObject private var engine: TimerEngine
    @EnvironmentObject private var premium: MacPremiumAccessService
    @EnvironmentObject private var notifications: MacNotificationService

    let currentTint: Color
    let openDetails: () -> Void

    private let quickFocusMinutes = [15, 25, 45]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("快捷操作", systemImage: "bolt.fill")
                .font(.headline)
                .foregroundStyle(MacTheme.primaryText)

            VStack(spacing: 6) {
                ForEach(TimerMode.allCases) { mode in
                    MacMiniQuickButton(
                        title: mode.title,
                        value: mode == engine.mode ? "当前" : "",
                        systemImage: mode.symbolName,
                        tint: Color(hex: mode.tintHex),
                        isSelected: mode == engine.mode
                    ) {
                        engine.selectMode(mode)
                    }
                    .disabled(engine.isRunning)
                }
            }

            Divider().opacity(0.28)

            Text("专注时长")
                .font(.caption.bold())
                .foregroundStyle(MacTheme.secondaryText)
            HStack(spacing: 6) {
                ForEach(quickFocusMinutes, id: \.self) { minute in
                    Button("\(minute)") {
                        store.settings.focusMinutes = minute
                        engine.syncIdleDuration()
                    }
                    .buttonStyle(MacMiniPillButtonStyle(isSelected: store.settings.focusMinutes == minute, tint: currentTint))
                    .disabled(engine.isRunning)
                    .accessibilityLabel("\(minute) 分钟")
                }
            }

            Divider().opacity(0.28)

            VStack(spacing: 6) {
                MacMiniQuickButton(
                    title: "铃声",
                    value: store.settings.completionSound.title,
                    systemImage: "bell.and.waves.left.and.right.fill",
                    tint: .orange,
                    isSelected: false
                ) {
                    cycleCompletionSound()
                }

                MacMiniQuickButton(
                    title: "试听",
                    value: premium.isProUnlocked ? "" : "Pro",
                    systemImage: "speaker.wave.2.fill",
                    tint: .cyan,
                    isSelected: false
                ) {
                    notifications.playCompletionAlert(
                        soundVolume: store.settings.soundVolume,
                        vibrationEnabled: false,
                        completionSound: store.settings.completionSound
                    )
                }
                .disabled(!premium.isProUnlocked && store.settings.completionSound.isPro)
            }

            Divider().opacity(0.28)

            MacMiniQuickButton(title: "日程", value: "", systemImage: "calendar", tint: .blue, isSelected: false, action: openDetails)
            MacMiniQuickButton(title: "统计", value: "", systemImage: "chart.xyaxis.line", tint: .mint, isSelected: false, action: openDetails)
            MacMiniQuickButton(title: "设置", value: "更多", systemImage: "slider.horizontal.3", tint: .purple, isSelected: false, action: openDetails)
        }
        .padding(14)
        .frame(width: 210)
        .background(Color(red: 0.10, green: 0.14, blue: 0.20).opacity(0.98), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(MacTheme.border, lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.35), radius: 18, x: 0, y: 10)
    }

    private func cycleCompletionSound() {
        guard premium.isProUnlocked else {
            store.settings.completionSound = .chime
            return
        }

        let sounds = CompletionSound.allCases
        guard let index = sounds.firstIndex(of: store.settings.completionSound) else {
            store.settings.completionSound = .chime
            return
        }
        store.settings.completionSound = sounds[(index + 1) % sounds.count]
    }
}

private struct MacMiniQuickButton: View {
    let title: String
    let value: String
    let systemImage: String
    let tint: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                Image(systemName: systemImage)
                    .font(.subheadline.bold())
                    .foregroundStyle(tint)
                    .frame(width: 22)
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(MacTheme.primaryText)
                Spacer()
                if !value.isEmpty {
                    Text(value)
                        .font(.caption.bold())
                        .foregroundStyle(isSelected ? Color.black.opacity(0.78) : MacTheme.secondaryText)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 9)
            .background(isSelected ? tint : Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

private struct MacMiniPillButtonStyle: ButtonStyle {
    let isSelected: Bool
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.caption.bold())
            .monospacedDigit()
            .foregroundStyle(isSelected ? Color.black.opacity(0.82) : MacTheme.primaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(isSelected ? tint : Color.white.opacity(configuration.isPressed ? 0.16 : 0.08), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct MacIconButtonStyle: ButtonStyle {
    let tint: Color
    let filled: Bool
    var size: CGFloat = 52

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size > 60 ? 24 : 16, weight: .semibold))
            .foregroundStyle(filled ? Color.black.opacity(0.86) : tint)
            .frame(width: size, height: size)
            .background(
                filled ? tint : tint.opacity(configuration.isPressed ? 0.20 : 0.10),
                in: Circle()
            )
            .overlay {
                Circle()
                    .stroke(tint.opacity(filled ? 0 : 0.35), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.smooth(duration: 0.12), value: configuration.isPressed)
    }
}

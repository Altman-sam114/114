import SwiftUI

struct MacMiniTimerView: View {
    @EnvironmentObject private var store: FocusStore
    @EnvironmentObject private var engine: TimerEngine

    let openDetails: () -> Void

    private var currentTint: Color {
        if let task = store.task(for: engine.selectedTaskID) {
            return Color(hex: task.accentHex)
        }
        return Color(hex: engine.mode.tintHex)
    }

    var body: some View {
        VStack(spacing: 18) {
            MacMiniHeaderView(openDetails: openDetails)
            MacMiniClockView(currentTint: currentTint)
            MacMiniControlsView(currentTint: currentTint)
            MacMiniTaskPickerView(currentTint: currentTint)
        }
        .padding(20)
        .frame(width: 430, height: 500)
        .background(MacTheme.background)
    }
}

private struct MacMiniHeaderView: View {
    @EnvironmentObject private var engine: TimerEngine

    let openDetails: () -> Void

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

            Button(action: openDetails) {
                Text("...")
                    .font(.headline)
                    .monospaced()
                    .foregroundStyle(MacTheme.primaryText)
                    .frame(width: 28, height: 24)
                    .background(MacTheme.panel, in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("高级功能")
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

            HStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { index in
                    Capsule()
                        .fill(segmentColor(index: index))
                        .frame(width: index == activeSegment ? 56 : 16, height: 10)
                }
            }
            .animation(.smooth(duration: 0.2), value: activeSegment)

            Text(engine.isRunning ? (engine.isPaused ? "已暂停" : "专注中") : "准备开始")
                .font(.caption)
                .foregroundStyle(MacTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }

    private var activeSegment: Int {
        min(3, max(0, Int(engine.progress * 4)))
    }

    private func segmentColor(index: Int) -> Color {
        index <= activeSegment ? currentTint.opacity(0.85) : Color.white.opacity(0.12)
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

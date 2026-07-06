import SwiftUI

struct MacTimerDetailView: View {
    @EnvironmentObject private var store: FocusStore
    @EnvironmentObject private var engine: TimerEngine

    private var currentTint: Color {
        if let task = store.task(for: engine.selectedTaskID) {
            return Color(hex: task.accentHex)
        }
        return Color(hex: engine.mode.tintHex)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            MacPageHeaderView(
                title: "专注中枢",
                subtitle: "状态栏小窗保持轻量，详细界面负责计划、复盘和设置。",
                symbolName: "timer"
            )

            HStack(alignment: .top, spacing: 18) {
                MacGlassPanel {
                    VStack(spacing: 18) {
                        MacModePickerView(currentTint: currentTint)
                        MacTimerDialView(currentTint: currentTint)
                        MacTimerActionRowView(currentTint: currentTint)
                    }
                }
                .frame(minWidth: 420)

                VStack(spacing: 18) {
                    MacTodaySummaryView()
                    MacTaskQueueView(currentTint: currentTint)
                }
                .frame(minWidth: 320)
            }
        }
        .padding(24)
    }
}

private struct MacModePickerView: View {
    @EnvironmentObject private var engine: TimerEngine
    @Environment(\.macSnapshotRendering) private var isSnapshotRendering

    let currentTint: Color

    var body: some View {
        if isSnapshotRendering {
            MacStaticSegmentedView(
                title: "模式",
                selectedTitle: engine.mode.title,
                options: TimerMode.allCases.map(\.title)
            )
        } else {
            Picker("模式", selection: Binding(
                get: { engine.mode },
                set: { engine.selectMode($0) }
            )) {
                ForEach(TimerMode.allCases) { mode in
                    Label(mode.title, systemImage: mode.symbolName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .tint(currentTint)
            .disabled(engine.isRunning)
        }
    }
}

private struct MacTimerDialView: View {
    @EnvironmentObject private var engine: TimerEngine

    let currentTint: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.10), lineWidth: 18)
            Circle()
                .trim(from: 0, to: engine.progress)
                .stroke(currentTint, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: currentTint.opacity(0.35), radius: 18)

            VStack(spacing: 10) {
                Image(systemName: engine.mode.symbolName)
                    .font(.title2)
                    .foregroundStyle(currentTint)
                Text(engine.formattedRemaining)
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(MacTheme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                Text(engine.currentTaskTitle)
                    .font(.headline)
                    .foregroundStyle(MacTheme.secondaryText)
                    .lineLimit(1)
                Text("下一步 \(engine.nextModeHint)")
                    .font(.caption)
                    .foregroundStyle(currentTint)
            }
        }
        .frame(maxWidth: 360)
        .aspectRatio(1, contentMode: .fit)
    }
}

private struct MacTimerActionRowView: View {
    @EnvironmentObject private var engine: TimerEngine
    @Environment(\.macSnapshotRendering) private var isSnapshotRendering

    let currentTint: Color

    var body: some View {
        if isSnapshotRendering {
            MacStaticTimerActionRowView(currentTint: currentTint)
        } else {
            interactiveActionRow
        }
    }

    private var interactiveActionRow: some View {
        HStack(spacing: 12) {
            Button("停止", systemImage: "stop.fill") {
                engine.stop()
            }
            .disabled(!engine.isRunning)

            Button("跳过", systemImage: "forward.end.fill", action: engine.skipToNextSession)
                .disabled(!engine.isRunning)

            Button(primaryTitle, systemImage: primarySymbol, action: toggleTimer)
                .buttonStyle(.borderedProminent)
                .tint(currentTint)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
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

private struct MacStaticTimerActionRowView: View {
    let currentTint: Color

    var body: some View {
        HStack(spacing: 12) {
            staticChip(title: "停止", symbolName: "stop.fill", tint: MacTheme.secondaryText, isProminent: false)
            staticChip(title: "跳过", symbolName: "forward.end.fill", tint: MacTheme.secondaryText, isProminent: false)
            staticChip(title: "开始", symbolName: "play.fill", tint: currentTint, isProminent: true)
        }
    }

    private func staticChip(title: String, symbolName: String, tint: Color, isProminent: Bool) -> some View {
        Label(title, systemImage: symbolName)
            .font(.headline)
            .foregroundStyle(isProminent ? Color.black.opacity(0.82) : tint)
            .frame(minWidth: 96, minHeight: 44)
            .background(isProminent ? tint : Color.white.opacity(0.07), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(isProminent ? tint.opacity(0.9) : MacTheme.border, lineWidth: 1)
            }
    }
}

private struct MacTodaySummaryView: View {
    @EnvironmentObject private var store: FocusStore

    var body: some View {
        MacGlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                Label("今日概览", systemImage: "sun.max.fill")
                    .font(.headline)
                    .foregroundStyle(MacTheme.primaryText)

                HStack(spacing: 12) {
                    MacMetricView(title: "今日", value: store.todayFocusSeconds.hourMinuteText, tint: .cyan)
                    MacMetricView(title: "本周", value: store.weekFocusSeconds.hourMinuteText, tint: .mint)
                    MacMetricView(title: "轮次", value: "\(store.completedFocusRounds)", tint: .orange)
                }
            }
        }
    }
}

private struct MacTaskQueueView: View {
    @EnvironmentObject private var store: FocusStore
    @EnvironmentObject private var engine: TimerEngine

    let currentTint: Color

    var body: some View {
        MacGlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("待办队列", systemImage: "checklist")
                        .font(.headline)
                        .foregroundStyle(MacTheme.primaryText)
                    Spacer()
                    Text("\(store.upcomingTasks().count)")
                        .foregroundStyle(MacTheme.secondaryText)
                }

                ForEach(store.upcomingTasks().prefix(7)) { task in
                    Button {
                        guard !engine.isRunning else { return }
                        engine.selectTask(task)
                    } label: {
                        MacTaskRowView(
                            task: task,
                            isSelected: engine.selectedTaskID == task.id,
                            isTimerRunning: engine.isRunning
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(engine.isRunning)
                }
            }
        }
    }
}

struct MacMetricView: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.title2.bold())
                .monospacedDigit()
                .foregroundStyle(MacTheme.primaryText)
            Text(title)
                .font(.caption)
                .foregroundStyle(MacTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct MacTaskRowView: View {
    let task: FocusTask
    var isSelected = false
    var isTimerRunning = false

    private var categoryPreset: TaskCategoryPreset? {
        TaskCategoryPreset.matching(task.category)
    }

    private var categoryTint: Color {
        Color(hex: categoryPreset?.accentHex ?? task.accentHex)
    }

    private var categorySymbolName: String {
        categoryPreset?.symbolName ?? "tag.fill"
    }

    private var selectionStateText: String {
        isSelected ? "已选中当前待办" : "未选中"
    }

    private var selectionHintText: String {
        if isTimerRunning && !isSelected {
            return "计时运行中不可切换当前待办"
        }
        isSelected ? "这是当前番茄钟待办" : "选择此待办作为当前番茄钟任务"
    }

    private var selectionAccessibilityTraits: AccessibilityTraits {
        isSelected ? [.isSelected] : []
    }

    private var selectionInputLabels: [Text] {
        [
            Text(task.title),
            Text("\(task.title)待办"),
            Text("\(task.category)分类待办")
        ]
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle.fill")
                .foregroundStyle(categoryTint)
            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(MacTheme.primaryText)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Label(task.category, systemImage: categorySymbolName)
                        .font(.caption.bold())
                        .foregroundStyle(categoryTint)
                        .lineLimit(1)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(categoryTint.opacity(0.14), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .accessibilityLabel("\(task.category)分类")
                        .accessibilityInputLabels([Text(task.category), Text("\(task.category)分类")])

                    if let dueDate = task.dueDate {
                        Text(dueDate.scheduleTimeText)
                            .font(.caption)
                            .foregroundStyle(MacTheme.secondaryText)
                            .lineLimit(1)
                    }
                }
            }
            Spacer()
            MacLinearProgressView(value: task.progress, tint: categoryTint, height: 6)
                .frame(width: 74)
        }
        .padding(10)
        .background(isSelected ? categoryTint.opacity(0.16) : Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(task.title)，\(task.category)分类，\(selectionStateText)")
        .accessibilityHint(selectionHintText)
        .accessibilityInputLabels(selectionInputLabels)
        .accessibilityAddTraits(selectionAccessibilityTraits)
    }
}

struct MacPageHeaderView: View {
    let title: String
    let subtitle: String
    let symbolName: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: symbolName)
                .font(.title2)
                .foregroundStyle(.cyan)
                .frame(width: 44, height: 44)
                .background(Color.cyan.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.largeTitle.bold())
                    .foregroundStyle(MacTheme.primaryText)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(MacTheme.secondaryText)
            }
            Spacer()
        }
    }
}

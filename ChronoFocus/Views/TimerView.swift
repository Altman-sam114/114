import SwiftUI

struct TimerView: View {
    @EnvironmentObject private var store: FocusStore
    @EnvironmentObject private var engine: TimerEngine

    private var currentTint: Color {
        if let task = store.task(for: engine.selectedTaskID) {
            return Color(hex: task.accentHex)
        }
        return Color(hex: engine.mode.tintHex)
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    header
                    modePicker
                    timerDial
                    actionBar
                    openEndedFinishButton
                    timerControlPanel
                    taskPicker
                    todayStrip
                }
                .padding(18)
                .padding(.bottom, 24)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("ChronoFocus")
            .toolbarColorScheme(store.settings.appThemeMode == .dark ? .dark : .light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.settings.appThemeMode = store.settings.appThemeMode == .dark ? .light : .dark
                    } label: {
                        Image(systemName: store.settings.appThemeMode.symbolName)
                    }
                    .accessibilityLabel("切换亮暗主题")
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("智能专注中枢")
                    .font(.caption)
                    .foregroundStyle(currentTint)
                    .textCase(.uppercase)
                Text(engine.currentTaskTitle)
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.primaryText)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 6) {
                Text("第 \(store.completedFocusRounds + 1) 轮")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
                Text(engine.isRunning ? (engine.isPaused ? "已暂停" : "运行中") : "待启动")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
    }

    private var modePicker: some View {
        Picker("模式", selection: Binding(
            get: { engine.mode },
            set: { engine.selectMode($0) }
        )) {
            ForEach(TimerMode.allCases) { mode in
                Label(mode.title, systemImage: mode.symbolName).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .disabled(engine.isRunning)
    }

    private var timerDial: some View {
        GlassPanel {
            VStack(spacing: 22) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 18)
                    Circle()
                        .trim(from: 0, to: engine.progress)
                        .stroke(
                            AngularGradient(
                                colors: [currentTint, .white, currentTint.opacity(0.62), currentTint],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 18, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .shadow(color: currentTint.opacity(0.38), radius: 18)

                    VStack(spacing: 8) {
                        Image(systemName: engine.mode.symbolName)
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(currentTint)
                        Text(engine.formattedRemaining)
                            .font(.system(size: 62, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundStyle(AppTheme.primaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.55)
                        Text("\(engine.mode.title) · \(engine.plannedSeconds.hourMinuteText)")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.secondaryText)
                        Text("下一步 \(engine.nextModeHint)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(currentTint)
                    }
                    .padding(20)
                }
                .frame(maxWidth: 330)
                .aspectRatio(1, contentMode: .fit)

                HStack(spacing: 10) {
                    MetricPill(title: "今日", value: store.todayFocusSeconds.hourMinuteText, tint: .cyan)
                    MetricPill(title: "本周", value: store.weekFocusSeconds.hourMinuteText, tint: .mint)
                    MetricPill(title: "完成", value: "\(store.completedFocusRounds)", tint: .orange)
                }
            }
        }
    }

    private var actionBar: some View {
        HStack(spacing: 12) {
            Button {
                engine.stop()
            } label: {
                Image(systemName: "stop.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(IconActionButtonStyle(tint: .red.opacity(0.88), filled: false))
            .disabled(!engine.isRunning)
            .accessibilityLabel("停止")

            Button {
                engine.skipToNextSession()
            } label: {
                Image(systemName: "forward.end.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(IconActionButtonStyle(tint: .orange.opacity(0.9), filled: false))
            .disabled(!engine.isRunning)
            .accessibilityLabel("跳过当前轮")

            Button {
                if !engine.isRunning {
                    engine.start()
                } else if engine.isPaused {
                    engine.resume()
                } else {
                    engine.pause()
                }
            } label: {
                Image(systemName: !engine.isRunning || engine.isPaused ? "play.fill" : "pause.fill")
                    .font(.system(size: 26, weight: .bold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(IconActionButtonStyle(tint: currentTint, filled: true))
            .accessibilityLabel(!engine.isRunning || engine.isPaused ? "开始" : "暂停")
        }
        .frame(height: 58)
    }

    @ViewBuilder
    private var openEndedFinishButton: some View {
        if engine.isRunning && engine.isCurrentTaskOpenEnded {
            Button {
                engine.finishCurrentTask()
            } label: {
                Label("完成当前待办", systemImage: "checkmark.seal.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(IconActionButtonStyle(tint: .mint, filled: true))
            .accessibilityLabel("完成当前待办")
        }
    }

    private var timerControlPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("提醒与屏幕", systemImage: "bell.and.waves.left.and.right.fill")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)
                    Spacer()
                    Text(store.settings.soundVolume <= 0 ? "静音" : "\(Int(store.settings.soundVolume * 100))%")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(currentTint)
                }

                HStack(spacing: 12) {
                    Image(systemName: store.settings.soundVolume <= 0 ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .foregroundStyle(currentTint)
                        .frame(width: 28)
                    Slider(
                        value: Binding(
                            get: { store.settings.soundVolume },
                            set: { newValue in
                                store.settings.soundVolume = newValue
                                store.settings.soundEnabled = newValue > 0
                            }
                        ),
                        in: 0...1
                    )
                    .tint(currentTint)
                }

                Toggle(isOn: $store.settings.vibrationEnabled) {
                    Label("到点振动", systemImage: "iphone.radiowaves.left.and.right")
                }

                Toggle(isOn: $store.settings.keepScreenAwake) {
                    Label("运行时屏幕常亮", systemImage: "display")
                }
            }
            .toggleStyle(SwitchToggleStyle(tint: currentTint))
            .foregroundStyle(AppTheme.primaryText)
        }
    }

    private var taskPicker: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("当前日程", systemImage: "target")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)
                    Spacer()
                    Text("\(store.upcomingTasks().count) 项待办")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                if store.upcomingTasks().isEmpty {
                    Text("暂无待办，仍可启动自由专注。")
                        .foregroundStyle(AppTheme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(spacing: 10) {
                        ForEach(store.upcomingTasks().prefix(4)) { task in
                            Button {
                                if !engine.isRunning {
                                    engine.selectTask(task)
                                }
                            } label: {
                                TaskRow(task: task, isSelected: engine.selectedTaskID == task.id)
                            }
                            .buttonStyle(.plain)
                            .disabled(engine.isRunning)
                        }
                    }
                }
            }
        }
    }

    private var todayStrip: some View {
        HStack(spacing: 10) {
            MetricTile(title: "通知栏", value: store.settings.liveActivityEnabled ? "开启" : "关闭", symbol: "iphone.radiowaves.left.and.right", tint: .cyan)
            MetricTile(title: "铃声", value: store.settings.soundVolume > 0 ? "\(Int(store.settings.soundVolume * 100))%" : "静音", symbol: "bell.and.waves.left.and.right.fill", tint: .orange)
        }
    }
}

private struct MetricPill: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(AppTheme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.74)
            Text(title)
                .font(.caption2)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct TaskRow: View {
    let task: FocusTask
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: task.accentHex))
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
                    .lineLimit(1)
                Text(task.dueDate?.scheduleTimeText ?? task.category)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(1)
            }

            Spacer()

            ProgressView(value: task.progress)
                .tint(Color(hex: task.accentHex))
                .frame(width: 58)

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? Color(hex: task.accentHex) : AppTheme.secondaryText)
        }
        .padding(12)
        .background(isSelected ? Color(hex: task.accentHex).opacity(0.13) : AppTheme.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isSelected ? Color(hex: task.accentHex).opacity(0.7) : AppTheme.border, lineWidth: 1)
        }
    }
}

private struct IconActionButtonStyle: ButtonStyle {
    let tint: Color
    let filled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 19, weight: .bold))
            .foregroundStyle(filled ? .black : tint)
            .frame(height: 58)
            .background(filled ? tint : tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(tint.opacity(0.52), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

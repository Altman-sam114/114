import SwiftUI

func resolveMacTimerHandoffTask(
    _ request: MacTimerHandoffRequest,
    from startableTasks: [FocusTask]
) -> FocusTask? {
    if let preferredTaskID = request.preferredTaskID {
        return startableTasks.first {
            $0.id == preferredTaskID && $0.category == request.category
        }
    }
    return startableTasks.first { $0.category == request.category }
}

struct MacTimerDetailView: View {
    @EnvironmentObject private var store: FocusStore
    @EnvironmentObject private var engine: TimerEngine
    let onAddTaskInCategory: (String) -> Void
    let initialTaskCategory: String?
    let timerHandoffRequest: MacTimerHandoffRequest?
    let onConsumeTimerHandoffRequest: (UUID) -> Void

    init(
        onAddTaskInCategory: @escaping (String) -> Void = { _ in },
        initialTaskCategory: String? = nil,
        timerHandoffRequest: MacTimerHandoffRequest? = nil,
        onConsumeTimerHandoffRequest: @escaping (UUID) -> Void = { _ in }
    ) {
        self.onAddTaskInCategory = onAddTaskInCategory
        self.initialTaskCategory = initialTaskCategory
        self.timerHandoffRequest = timerHandoffRequest
        self.onConsumeTimerHandoffRequest = onConsumeTimerHandoffRequest
    }

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
                    MacTaskQueueView(
                        currentTint: currentTint,
                        initialTaskCategory: initialTaskCategory,
                        onAddTaskInCategory: onAddTaskInCategory,
                        timerHandoffRequest: timerHandoffRequest,
                        onConsumeTimerHandoffRequest: onConsumeTimerHandoffRequest
                    )
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
    @EnvironmentObject private var store: FocusStore
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
            .accessibilityLabel("停止\(timerActionContext)计时")
            .accessibilityInputLabels(timerActionInputLabels("停止"))

            Button("跳过", systemImage: "forward.end.fill", action: engine.skipToNextSession)
                .disabled(!engine.isRunning)
                .accessibilityLabel("跳过\(timerActionContext)当前轮")
                .accessibilityInputLabels(timerActionInputLabels("跳过"))

            Button(primaryTitle, systemImage: primarySymbol, action: toggleTimer)
                .buttonStyle(.borderedProminent)
                .tint(currentTint)
                .accessibilityLabel(primaryTimerActionLabel)
                .accessibilityInputLabels(timerActionInputLabels(primaryTimerActionInputCommand))
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }

    private var timerActionTask: FocusTask? {
        store.task(for: engine.selectedTaskID)
    }

    private var timerActionContext: String {
        if let task = timerActionTask {
            return "\(task.title)，\(task.category)分类"
        }
        return engine.currentTaskTitle
    }

    private var primaryTitle: String {
        !engine.isRunning || engine.isPaused ? "开始" : "暂停"
    }

    private var primaryTimerActionLabel: String {
        if !engine.isRunning {
            return "开始\(timerActionContext)计时"
        }
        return engine.isPaused ? "继续\(timerActionContext)计时" : "暂停\(timerActionContext)计时"
    }

    private var primaryTimerActionInputCommand: String {
        if !engine.isRunning {
            return "开始"
        }
        return engine.isPaused ? "继续" : "暂停"
    }

    private var primarySymbol: String {
        !engine.isRunning || engine.isPaused ? "play.fill" : "pause.fill"
    }

    private func timerActionInputLabels(_ action: String) -> [Text] {
        var labels = [
            Text(action),
            Text("\(action)\(engine.currentTaskTitle)")
        ]
        if let task = timerActionTask {
            labels.append(Text("\(action)\(task.title)"))
            labels.append(Text("\(action)\(task.category)分类"))
            labels.append(Text("\(task.category)分类\(action)"))
        }
        return labels
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
    @EnvironmentObject private var store: FocusStore
    @EnvironmentObject private var engine: TimerEngine

    let currentTint: Color

    var body: some View {
        HStack(spacing: 12) {
            staticChip(
                title: "停止",
                symbolName: "stop.fill",
                tint: MacTheme.secondaryText,
                isProminent: false,
                accessibilityLabel: "停止\(timerActionContext)计时",
                inputLabels: timerActionInputLabels("停止")
            )
            staticChip(
                title: "跳过",
                symbolName: "forward.end.fill",
                tint: MacTheme.secondaryText,
                isProminent: false,
                accessibilityLabel: "跳过\(timerActionContext)当前轮",
                inputLabels: timerActionInputLabels("跳过")
            )
            staticChip(
                title: primaryTitle,
                symbolName: primarySymbol,
                tint: currentTint,
                isProminent: true,
                accessibilityLabel: primaryTimerActionLabel,
                inputLabels: timerActionInputLabels(primaryTimerActionInputCommand)
            )
        }
    }

    private var timerActionTask: FocusTask? {
        store.task(for: engine.selectedTaskID)
    }

    private var timerActionContext: String {
        if let task = timerActionTask {
            return "\(task.title)，\(task.category)分类"
        }
        return engine.currentTaskTitle
    }

    private var primaryTitle: String {
        !engine.isRunning || engine.isPaused ? "开始" : "暂停"
    }

    private var primarySymbol: String {
        !engine.isRunning || engine.isPaused ? "play.fill" : "pause.fill"
    }

    private var primaryTimerActionLabel: String {
        if !engine.isRunning {
            return "开始\(timerActionContext)计时"
        }
        return engine.isPaused ? "继续\(timerActionContext)计时" : "暂停\(timerActionContext)计时"
    }

    private var primaryTimerActionInputCommand: String {
        if !engine.isRunning {
            return "开始"
        }
        return engine.isPaused ? "继续" : "暂停"
    }

    private func timerActionInputLabels(_ action: String) -> [Text] {
        var labels = [
            Text(action),
            Text("\(action)\(engine.currentTaskTitle)")
        ]
        if let task = timerActionTask {
            labels.append(Text("\(action)\(task.title)"))
            labels.append(Text("\(action)\(task.category)分类"))
            labels.append(Text("\(task.category)分类\(action)"))
        }
        return labels
    }

    private func staticChip(title: String, symbolName: String, tint: Color, isProminent: Bool, accessibilityLabel: String, inputLabels: [Text]) -> some View {
        Label(title, systemImage: symbolName)
            .font(.headline)
            .foregroundStyle(isProminent ? Color.black.opacity(0.82) : tint)
            .frame(minWidth: 96, minHeight: 44)
            .background(isProminent ? tint : Color.white.opacity(0.07), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(isProminent ? tint.opacity(0.9) : MacTheme.border, lineWidth: 1)
            }
            .accessibilityLabel(accessibilityLabel)
            .accessibilityInputLabels(inputLabels)
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
    @Environment(\.macSnapshotRendering) private var isSnapshotRendering
    @State private var selectedCategory: String?

    let currentTint: Color
    let onAddTaskInCategory: (String) -> Void
    let timerHandoffRequest: MacTimerHandoffRequest?
    let onConsumeTimerHandoffRequest: (UUID) -> Void

    init(
        currentTint: Color,
        initialTaskCategory: String?,
        onAddTaskInCategory: @escaping (String) -> Void,
        timerHandoffRequest: MacTimerHandoffRequest?,
        onConsumeTimerHandoffRequest: @escaping (UUID) -> Void
    ) {
        self.currentTint = currentTint
        self.onAddTaskInCategory = onAddTaskInCategory
        self.timerHandoffRequest = timerHandoffRequest
        self.onConsumeTimerHandoffRequest = onConsumeTimerHandoffRequest
        _selectedCategory = State(initialValue: initialTaskCategory)
    }

    private var startableTasks: [FocusTask] {
        store.startableTasks()
    }

    private var visibleTasks: [FocusTask] {
        guard let selectedCategory else { return startableTasks }
        return startableTasks.filter { $0.category == selectedCategory }
    }

    private var taskQueueCountText: String {
        guard !startableTasks.isEmpty else { return "0 项可启动待办" }
        guard selectedCategory != nil else { return "\(startableTasks.count) 项可启动待办" }
        return "\(visibleTasks.count)/\(startableTasks.count) 项可启动待办"
    }

    var body: some View {
        MacGlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("待办队列", systemImage: "checklist")
                        .font(.headline)
                        .foregroundStyle(MacTheme.primaryText)
                    Spacer()
                    Text(taskQueueCountText)
                        .font(.caption)
                        .foregroundStyle(MacTheme.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }

                if !startableTasks.isEmpty {
                    MacCategoryFilterBar(
                        categories: store.taskCategories,
                        selectedCategory: $selectedCategory,
                        countProvider: taskCount(in:)
                    )
                }

                if startableTasks.isEmpty {
                    Text("暂无可启动待办，仍可启动自由专注。")
                        .font(.caption)
                        .foregroundStyle(MacTheme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if visibleTasks.isEmpty, let selectedCategory {
                    MacTimerCategoryEmptyStateView(
                        category: selectedCategory,
                        isSnapshotRendering: isSnapshotRendering,
                        onAddTask: {
                            onAddTaskInCategory(selectedCategory)
                        },
                        onClear: {
                            self.selectedCategory = nil
                        }
                    )
                } else {
                    if let selectedCategory {
                        MacTimerCategoryContextView(
                            category: selectedCategory,
                            filteredCount: visibleTasks.count,
                            totalCount: startableTasks.count,
                            isSnapshotRendering: isSnapshotRendering,
                            onAddTask: {
                                onAddTaskInCategory(selectedCategory)
                            },
                            onClear: {
                                self.selectedCategory = nil
                            }
                        )
                    }

                    ForEach(visibleTasks.prefix(7)) { task in
                        Button {
                            guard !engine.isRunning else { return }
                            engine.selectTask(task)
                        } label: {
                            MacTaskRowView(
                                task: task,
                                isSelected: engine.selectedTaskID == task.id,
                                isTimerRunning: engine.isRunning,
                                showsCategoryBadge: selectedCategory == nil
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(engine.isRunning)
                        .accessibilityInputLabels([
                            Text(task.title),
                            Text("\(task.title)待办"),
                            Text("\(task.category)分类待办")
                        ])
                    }
                }
            }
        }
        .task(id: timerHandoffRequest?.id) {
            consumeTimerHandoffRequest()
        }
    }

    private func taskCount(in category: String?) -> Int {
        guard let category else { return startableTasks.count }
        return startableTasks.filter { $0.category == category }.count
    }

    private func consumeTimerHandoffRequest() {
        guard let request = timerHandoffRequest else { return }
        defer { onConsumeTimerHandoffRequest(request.id) }

        selectedCategory = request.category
        guard !engine.isRunning else { return }

        let startableTasks = store.startableTasks()
        let targetTask = resolveMacTimerHandoffTask(request, from: startableTasks)

        if let targetTask {
            engine.selectTask(targetTask)
        } else if request.preferredTaskID != nil {
            engine.selectTask(nil)
        } else if store.startableTask(for: engine.selectedTaskID)?.category != request.category {
            engine.selectTask(nil)
        }
    }
}

struct MacTimerCategoryContextView: View {
    let category: String
    let filteredCount: Int
    let totalCount: Int
    let isSnapshotRendering: Bool
    let onAddTask: () -> Void
    let onClear: () -> Void

    private var preset: TaskCategoryPreset? {
        TaskCategoryPreset.matching(category)
    }

    private var tint: Color {
        Color(hex: preset?.accentHex ?? "#3DE8C5")
    }

    private var countText: String {
        "\(filteredCount)/\(totalCount) 项可启动待办"
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            contextLayout(axis: .horizontal)
            contextLayout(axis: .vertical)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.09), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(tint.opacity(0.32), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("当前筛选为\(category)分类，显示\(filteredCount)项，共\(totalCount)项可启动待办")
        .accessibilityHint("可新增\(category)分类待办或清除筛选查看全部可启动待办")
    }

    private func contextLayout(axis: Axis) -> some View {
        let layout = axis == .horizontal
            ? AnyLayout(HStackLayout(alignment: .center, spacing: 8))
            : AnyLayout(VStackLayout(alignment: .leading, spacing: 8))

        return layout {
            categorySummary
                .frame(maxWidth: axis == .vertical ? .infinity : nil, alignment: .leading)

            if axis == .horizontal {
                Spacer(minLength: 0)
            }

            MacTimerCategoryContextActions(
                category: category,
                tint: tint,
                isSnapshotRendering: isSnapshotRendering,
                axis: axis,
                onAddTask: onAddTask,
                onClear: onClear
            )
        }
    }

    private var categorySummary: some View {
        VStack(alignment: .leading, spacing: 3) {
            Label(category, systemImage: preset?.symbolName ?? "tag.fill")
                .font(.caption.bold())
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Text(countText)
                .font(.caption)
                .foregroundStyle(MacTheme.secondaryText)
                .monospacedDigit()
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("已选择\(category)分类，显示\(filteredCount)项，共\(totalCount)项可启动待办")
    }
}

private struct MacTimerCategoryContextActions: View {
    let category: String
    let tint: Color
    let isSnapshotRendering: Bool
    let axis: Axis
    let onAddTask: () -> Void
    let onClear: () -> Void

    var body: some View {
        let layout = axis == .horizontal
            ? AnyLayout(HStackLayout(spacing: 6))
            : AnyLayout(VStackLayout(spacing: 6))

        layout {
            action(
                title: "新增此分类",
                symbolName: "plus.circle.fill",
                isProminent: true,
                minWidth: 100,
                action: onAddTask,
                accessibilityLabel: "新增\(category)分类待办",
                accessibilityHint: "转到日程并预填\(category)分类",
                inputLabels: ["新增此分类", "新增\(category)分类待办", "新增\(category)分类"]
            )

            action(
                title: "清除筛选",
                symbolName: "xmark.circle.fill",
                isProminent: false,
                minWidth: 88,
                action: onClear,
                accessibilityLabel: "清除\(category)分类筛选",
                accessibilityHint: "显示全部分类的待办",
                inputLabels: ["清除筛选", "清除\(category)分类筛选", "查看全部分类"]
            )
        }
        .frame(maxWidth: axis == .vertical ? .infinity : nil)
    }

    @ViewBuilder
    private func action(
        title: String,
        symbolName: String,
        isProminent: Bool,
        minWidth: CGFloat,
        action: @escaping () -> Void,
        accessibilityLabel: String,
        accessibilityHint: String,
        inputLabels: [String]
    ) -> some View {
        let label = Label(title, systemImage: symbolName)
            .font(.caption.bold())
            .foregroundStyle(isProminent ? Color.black.opacity(0.82) : tint)
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .padding(.horizontal, 9)
            .frame(minWidth: minWidth, maxWidth: axis == .vertical ? .infinity : nil, minHeight: 36)
            .background(isProminent ? tint : Color.white.opacity(0.07), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(tint.opacity(isProminent ? 0.9 : 0.36), lineWidth: 1)
            }

        if isSnapshotRendering {
            label
                .accessibilityLabel(accessibilityLabel)
                .accessibilityHint(accessibilityHint)
                .accessibilityInputLabels(inputLabels.map { Text($0) })
                .accessibilityAddTraits(.isButton)
        } else {
            Button(action: action) {
                label
            }
            .buttonStyle(.plain)
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint(accessibilityHint)
            .accessibilityInputLabels(inputLabels.map { Text($0) })
        }
    }
}

struct MacTimerCategoryEmptyStateView: View {
    let category: String
    let isSnapshotRendering: Bool
    let onAddTask: () -> Void
    let onClear: () -> Void

    private var preset: TaskCategoryPreset? {
        TaskCategoryPreset.matching(category)
    }

    private var tint: Color {
        Color(hex: preset?.accentHex ?? "#3DE8C5")
    }

    private var addButtonInputLabels: [Text] {
        [Text("新增此分类"), Text("新增\(category)分类待办"), Text("新增\(category)分类")]
    }

    private var clearButtonInputLabels: [Text] {
        [Text("清除筛选"), Text("清除\(category)分类"), Text("查看全部分类")]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("暂无\(category)分类可启动待办", systemImage: preset?.symbolName ?? "tag.slash")
                .font(.subheadline.bold())
                .foregroundStyle(MacTheme.primaryText)

            Text("可转到日程快速新增此分类待办，或清除筛选查看全部可启动待办。")
                .font(.caption)
                .foregroundStyle(MacTheme.secondaryText)

            ViewThatFits(in: .horizontal) {
                MacTimerCategoryEmptyActions(
                    category: category,
                    tint: tint,
                    addButtonInputLabels: addButtonInputLabels,
                    clearButtonInputLabels: clearButtonInputLabels,
                    isSnapshotRendering: isSnapshotRendering,
                    axis: .horizontal,
                    onAddTask: onAddTask,
                    onClear: onClear
                )

                MacTimerCategoryEmptyActions(
                    category: category,
                    tint: tint,
                    addButtonInputLabels: addButtonInputLabels,
                    clearButtonInputLabels: clearButtonInputLabels,
                    isSnapshotRendering: isSnapshotRendering,
                    axis: .vertical,
                    onAddTask: onAddTask,
                    onClear: onClear
                )
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(tint.opacity(0.32), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(category)分类暂无可启动待办，可转到日程新增此分类待办或清除筛选")
    }
}

private struct MacTimerCategoryEmptyActions: View {
    let category: String
    let tint: Color
    let addButtonInputLabels: [Text]
    let clearButtonInputLabels: [Text]
    let isSnapshotRendering: Bool
    let axis: Axis
    let onAddTask: () -> Void
    let onClear: () -> Void

    var body: some View {
        let layout = axis == .horizontal
            ? AnyLayout(HStackLayout(spacing: 8))
            : AnyLayout(VStackLayout(spacing: 8))

        layout {
            if isSnapshotRendering {
                staticAction(title: "新增此分类", isProminent: true)
                staticAction(title: "清除筛选", isProminent: false)
            } else {
                Button("新增此分类", systemImage: "plus.circle.fill", action: onAddTask)
                    .font(.caption.bold())
                    .foregroundStyle(Color.black.opacity(0.82))
                    .buttonStyle(.plain)
                    .padding(.horizontal, 10)
                    .frame(minWidth: 104, maxWidth: .infinity, minHeight: 36)
                    .background(tint, in: Capsule())
                    .accessibilityLabel("新增\(category)分类待办")
                    .accessibilityInputLabels(addButtonInputLabels)

                Button("清除筛选", systemImage: "xmark.circle.fill", action: onClear)
                    .font(.caption.bold())
                    .foregroundStyle(tint)
                    .buttonStyle(.plain)
                    .padding(.horizontal, 10)
                    .frame(minWidth: 88, maxWidth: .infinity, minHeight: 36)
                    .background(Color.white.opacity(0.07), in: Capsule())
                    .overlay {
                        Capsule()
                            .stroke(tint.opacity(0.36), lineWidth: 1)
                    }
                    .accessibilityLabel("清除\(category)分类筛选")
                    .accessibilityInputLabels(clearButtonInputLabels)
            }
        }
        .fixedSize(horizontal: axis == .horizontal, vertical: false)
    }

    private func staticAction(title: String, isProminent: Bool) -> some View {
        Text(title)
            .font(.caption.bold())
            .foregroundStyle(isProminent ? Color.black.opacity(0.82) : tint)
            .frame(minWidth: isProminent ? 104 : 88, maxWidth: .infinity, minHeight: 36)
            .padding(.horizontal, 10)
            .background(isProminent ? tint : Color.white.opacity(0.07), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(tint.opacity(isProminent ? 0.9 : 0.36), lineWidth: 1)
            }
            .accessibilityLabel(title)
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
    var showsCategoryBadge = true

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
        return isSelected ? "这是当前番茄钟待办" : "选择此待办作为当前番茄钟任务"
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
                    if showsCategoryBadge {
                        Label(task.category, systemImage: categorySymbolName)
                            .font(.caption.bold())
                            .foregroundStyle(categoryTint)
                            .lineLimit(1)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(categoryTint.opacity(0.14), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                            .accessibilityLabel("\(task.category)分类")
                            .accessibilityInputLabels([Text(task.category), Text("\(task.category)分类")])
                    }

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

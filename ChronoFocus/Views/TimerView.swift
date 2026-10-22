import SwiftUI

struct TimerView: View {
    @EnvironmentObject private var store: FocusStore
    @EnvironmentObject private var engine: TimerEngine
    @EnvironmentObject private var notifications: NotificationService
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .largeTitle) private var timerFontSize = 58
    @State private var selectedTaskCategory: String?
    @State private var showingCategoryEditor = false
    @State private var isTaskQueueExpanded = false
    @State private var isReminderExpanded = false
    @State private var viewportHeight: CGFloat = 600
    let timerHandoffRequest: TimerHandoffRequest?
    let onConsumeTimerHandoff: (UUID) -> Void

    private let collapsedTaskLimit = 4

    init(
        timerHandoffRequest: TimerHandoffRequest? = nil,
        onConsumeTimerHandoff: @escaping (UUID) -> Void = { _ in }
    ) {
        self.timerHandoffRequest = timerHandoffRequest
        self.onConsumeTimerHandoff = onConsumeTimerHandoff
    }

    private var currentTintHex: String {
        if let snapshot = store.activeTimer {
            return snapshot.tintHex
        }
        if let task = store.task(for: engine.selectedTaskID) {
            return store.representativeAccentHex(for: task.category)
        }
        return engine.mode.tintHex
    }

    private var currentTint: Color {
        Color(hex: currentTintHex)
    }

    private var upcomingTasks: [FocusTask] {
        store.startableTasks()
    }

    private var filteredUpcomingTasks: [FocusTask] {
        guard let selectedTaskCategory else { return upcomingTasks }
        return upcomingTasks.filter { store.categoryMatches($0.category, selectedTaskCategory) }
    }

    private var visibleUpcomingTasks: [FocusTask] {
        isTaskQueueExpanded
            ? filteredUpcomingTasks
            : Array(filteredUpcomingTasks.prefix(collapsedTaskLimit))
    }

    private var filteredUpcomingTaskIDs: [UUID] {
        filteredUpcomingTasks.map(\.id)
    }

    private var hiddenTaskCount: Int {
        max(filteredUpcomingTasks.count - collapsedTaskLimit, 0)
    }

    private var taskQueueToggleTitle: String {
        isTaskQueueExpanded ? "收起" : "显示其余 \(hiddenTaskCount) 项"
    }

    private var taskQueueToggleAccessibilityLabel: String {
        isTaskQueueExpanded ? "收起待办列表" : "显示其余\(hiddenTaskCount)项待办"
    }

    private var taskQueueToggleAccessibilityValue: String {
        if isTaskQueueExpanded {
            return "已展开，显示全部 \(filteredUpcomingTasks.count) 项"
        }
        return "已收起，显示 \(collapsedTaskLimit) 项，共 \(filteredUpcomingTasks.count) 项"
    }

    private var taskQueueToggleAccessibilityHint: String {
        if isTaskQueueExpanded {
            return "收起后仅显示前 \(collapsedTaskLimit) 项待办"
        }

        let browsingHint = "展开后可查看其余 \(hiddenTaskCount) 项待办"
        return engine.isRunning ? "\(browsingHint)，计时运行中待办仍不可切换" : browsingHint
    }

    private var taskQueueToggleInputLabels: [Text] {
        if isTaskQueueExpanded {
            return [
                Text(taskQueueToggleTitle),
                Text("收起待办"),
                Text("收起待办列表")
            ]
        }
        return [
            Text(taskQueueToggleTitle),
            Text("显示更多待办"),
            Text("显示更多"),
            Text("展开待办")
        ]
    }

    private var taskPickerCountText: String {
        if selectedTaskCategory != nil {
            return "\(filteredUpcomingTasks.count)/\(upcomingTasks.count) 项可启动待办"
        }
        return "\(upcomingTasks.count) 项可启动待办"
    }

    private func taskCount(in category: String?) -> Int {
        guard let category else { return upcomingTasks.count }
        return upcomingTasks.filter { store.categoryMatches($0.category, category) }.count
    }

    private func clearTaskCategoryFilter() {
        selectedTaskCategory = nil
    }

    private var timerActionTask: FocusTask? {
        store.task(for: engine.selectedTaskID)
    }

    private var timerActionTitle: String {
        store.activeTimer?.taskTitle ?? timerActionTask?.title ?? engine.currentTaskTitle
    }

    private var timerActionCategory: String? {
        store.activeTimer?.category ?? timerActionTask?.category
    }

    private var timerActionContext: String {
        if let category = timerActionCategory {
            return "\(timerActionTitle)，\(category)分类"
        }
        return timerActionTitle
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

    private var primaryActionTitle: String {
        if engine.isRunning { return engine.isPaused ? "继续" : "暂停" }
        return engine.mode == .focus ? "开始专注" : "开始休息"
    }

    private var reminderSummary: String {
        let volume = store.settings.soundEnabled && store.settings.soundVolume > 0
            ? "音量 \(Int(store.settings.soundVolume * 100))%" : "静音"
        return store.settings.keepScreenAwake ? "\(volume) · 屏幕常亮" : volume
    }

    private func timerActionInputLabels(_ action: String) -> [Text] {
        var labels = [
            Text(action),
            Text("\(action)\(timerActionTitle)")
        ]
        if let category = timerActionCategory {
            labels.append(Text("\(action)\(category)分类"))
            labels.append(Text("\(category)分类\(action)"))
        }
        return labels
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
                    taskPicker
                    timerControlPanel
                    todayStrip
                }
                .padding(18)
                .padding(.bottom, 24)
            }
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { height in
                viewportHeight = height
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("ChronoFocus")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(store.settings.appThemeMode == .dark ? .dark : .light, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        store.settings.appThemeMode = store.settings.appThemeMode == .dark ? .light : .dark
                    } label: {
                        Image(systemName: store.settings.appThemeMode.symbolName)
                    }
                    .accessibilityIdentifier("theme.toggle")
                    .accessibilityLabel("切换亮暗主题")
                    .accessibilityValue(store.settings.appThemeMode.title)
                    .accessibilityHint("切换整个应用的亮色和暗色外观")
                }
            }
            .sheet(isPresented: $showingCategoryEditor) {
                TaskEditorView(
                    initialDueDate: Date().addingTimeInterval(3600),
                    initialCategory: selectedTaskCategory
                )
                .environmentObject(store)
                .environmentObject(notifications)
                .presentationDetents([.medium, .large])
            }
            .task(id: timerHandoffRequest?.id) {
                consumeTimerHandoffRequest()
            }
        }
    }

    private func consumeTimerHandoffRequest() {
        guard let request = timerHandoffRequest else { return }

        selectedTaskCategory = request.category
        isTaskQueueExpanded = false

        let startableTasks = store.startableTasks()
        let categoryTasks = startableTasks.filter { store.categoryMatches($0.category, request.category) }
        let targetTask: FocusTask?
        if let preferredTaskID = request.preferredTaskID {
            targetTask = store.startableTask(for: preferredTaskID).flatMap { task in
                store.categoryMatches(task.category, request.category) ? task : nil
            }
        } else {
            targetTask = categoryTasks.first
        }

        if !engine.isRunning {
            if let targetTask {
                engine.selectTask(targetTask)
            } else if request.preferredTaskID != nil {
                engine.selectTask(nil)
            } else if let selectedTaskID = engine.selectedTaskID,
                      !(store.startableTask(for: selectedTaskID).map { store.categoryMatches($0.category, request.category) } ?? false) {
                engine.selectTask(nil)
            }
        }

        onConsumeTimerHandoff(request.id)
    }

    private var header: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 12))
        return layout {
            VStack(alignment: .leading, spacing: 6) {
                Text(engine.isRunning ? "当前专注" : "准备好，专注当下")
                    .font(.caption)
                    .foregroundStyle(AppTheme.readableTint(currentTint))
                Text(timerActionTitle)
                    .font(.system(.title2, design: .rounded).bold())
                    .foregroundStyle(AppTheme.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("timer.task-title")
                if let category = timerActionCategory {
                    Label(category, systemImage: "tag.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.readableTint(currentTint))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

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
            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 12) {
                    countdownText
                    ProgressView(value: engine.progress)
                        .tint(currentTint)
                    timerPhaseCaption
                }
            } else {
                ZStack {
                    Circle()
                        .stroke(AppTheme.border, lineWidth: 12)
                    Circle()
                        .trim(from: 0, to: engine.progress)
                        .stroke(
                            currentTint,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .shadow(color: currentTint.opacity(0.22), radius: 12)

                    VStack(spacing: 8) {
                        Image(systemName: engine.mode.symbolName)
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(AppTheme.readableTint(currentTint))
                        countdownText
                        timerPhaseCaption
                    }
                    .padding(18)
                }
                .frame(maxWidth: viewportHeight < 560 ? 210 : 280)
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var countdownText: some View {
        Text(engine.formattedRemaining)
            .font(dynamicTypeSize.isAccessibilitySize
                  ? .system(.title, design: .rounded).bold()
                  : .system(size: timerFontSize, weight: .bold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(AppTheme.primaryText)
            .contentTransition(.numericText(countsDown: true))
            .accessibilityLabel("剩余时间")
            .accessibilityValue(engine.formattedRemaining)
            .accessibilityIdentifier("timer.remaining")
    }

    private var timerPhaseCaption: some View {
        VStack(spacing: 6) {
            Text("\(engine.mode.title) · \(engine.plannedSeconds.hourMinuteText)")
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
            Text("下一步 \(engine.nextModeHint)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.readableTint(currentTint))
        }
    }

    private var actionBar: some View {
        VStack(spacing: 10) {
            Button {
                if !engine.isRunning {
                    engine.start()
                } else if engine.isPaused {
                    engine.resume()
                } else {
                    engine.pause()
                }
            } label: {
                Label(primaryActionTitle, systemImage: !engine.isRunning || engine.isPaused ? "play.fill" : "pause.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(IconActionButtonStyle(tint: currentTint, filled: true, tintHex: currentTintHex))
            .accessibilityIdentifier("timer.primary")
            .accessibilityLabel(primaryTimerActionLabel)
            .accessibilityInputLabels(timerActionInputLabels(primaryTimerActionInputCommand))

            ViewThatFits(in: .horizontal) {
                secondaryActionLayout(axis: .horizontal)
                secondaryActionLayout(axis: .vertical)
            }
        }
    }

    private func secondaryActionLayout(axis: Axis) -> some View {
        let layout = axis == .horizontal
            ? AnyLayout(HStackLayout(spacing: 12))
            : AnyLayout(VStackLayout(spacing: 8))
        return layout {
            Button {
                engine.stop()
            } label: {
                Label("停止", systemImage: "stop.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(IconActionButtonStyle(tint: AppTheme.secondaryText, filled: false))
            .disabled(!engine.isRunning)
            .accessibilityIdentifier("timer.stop")
            .accessibilityLabel("停止\(timerActionContext)计时")
            .accessibilityInputLabels(timerActionInputLabels("停止"))

            Button {
                engine.skipToNextSession()
            } label: {
                Label("跳过", systemImage: "forward.end.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(IconActionButtonStyle(tint: AppTheme.secondaryText, filled: false))
            .disabled(!engine.isRunning)
            .accessibilityIdentifier("timer.skip")
            .accessibilityLabel("跳过\(timerActionContext)当前轮")
            .accessibilityInputLabels(timerActionInputLabels("跳过"))
        }
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
            .buttonStyle(IconActionButtonStyle(tint: .mint, filled: true, tintHex: "#00C7BE"))
            .accessibilityLabel("完成\(timerActionContext)待办")
            .accessibilityInputLabels(timerActionInputLabels("完成"))
        }
    }

    private var timerControlPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                Button {
                    isReminderExpanded.toggle()
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Label("提醒与屏幕", systemImage: "bell.and.waves.left.and.right.fill")
                                .font(.headline)
                                .foregroundStyle(AppTheme.primaryText)
                            Spacer(minLength: 8)
                            Image(systemName: isReminderExpanded ? "chevron.up" : "chevron.down")
                        }
                        Text(reminderSummary)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("timer.reminders")
                .accessibilityLabel("提醒与屏幕")
                .accessibilityValue("\(isReminderExpanded ? "已展开" : "已收起")，\(reminderSummary)")
                .accessibilityHint("展开或收起音量、振动和屏幕常亮设置")

                if isReminderExpanded {
                    HStack(spacing: 12) {
                        Image(systemName: store.settings.soundVolume <= 0 ? "speaker.slash.fill" : "speaker.wave.2.fill")
                            .foregroundStyle(AppTheme.readableTint(currentTint))
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
                    Text(taskPickerCountText)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }

                if !upcomingTasks.isEmpty {
                    TimerTaskCategoryFilterBar(
                        categories: store.taskCategories,
                        selectedCategory: $selectedTaskCategory,
                        countProvider: taskCount(in:)
                    )
                }

                if let selectedTaskCategory, !filteredUpcomingTasks.isEmpty {
                    TimerSelectedTaskCategorySummaryView(
                        category: selectedTaskCategory,
                        filteredCount: filteredUpcomingTasks.count,
                        totalCount: upcomingTasks.count,
                        onAddTask: {
                            showingCategoryEditor = true
                        },
                        onClear: clearTaskCategoryFilter
                    )
                }

                if filteredUpcomingTasks.isEmpty, let selectedTaskCategory {
                    TimerTaskCategoryEmptyView(
                        category: selectedTaskCategory,
                        onAddTask: {
                            showingCategoryEditor = true
                        },
                        onClear: clearTaskCategoryFilter
                    )
                } else if upcomingTasks.isEmpty {
                    Text("暂无可启动待办，仍可启动自由专注。")
                        .foregroundStyle(AppTheme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(spacing: 10) {
                        ForEach(visibleUpcomingTasks) { task in
                            Button {
                                if !engine.isRunning {
                                    engine.selectTask(task)
                                }
                            } label: {
                                TaskRow(
                                    task: task,
                                    isSelected: engine.selectedTaskID == task.id,
                                    isTimerRunning: engine.isRunning,
                                    showsCategoryBadge: selectedTaskCategory == nil
                                )
                            }
                            .buttonStyle(.plain)
                            .disabled(engine.isRunning)
                        }

                        if filteredUpcomingTasks.count > collapsedTaskLimit {
                            Button {
                                isTaskQueueExpanded.toggle()
                            } label: {
                                Label(
                                    taskQueueToggleTitle,
                                    systemImage: isTaskQueueExpanded ? "chevron.up" : "chevron.down"
                                )
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .fixedSize(horizontal: false, vertical: true)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(AppTheme.readableTint(currentTint))
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .contentShape(Rectangle())
                            .accessibilityLabel(taskQueueToggleAccessibilityLabel)
                            .accessibilityValue(taskQueueToggleAccessibilityValue)
                            .accessibilityHint(taskQueueToggleAccessibilityHint)
                            .accessibilityInputLabels(taskQueueToggleInputLabels)
                        }
                    }
                }
            }
        }
        .onChange(of: selectedTaskCategory) { _, _ in
            isTaskQueueExpanded = false
        }
        .onChange(of: filteredUpcomingTaskIDs) { _, _ in
            isTaskQueueExpanded = false
        }
    }

    private var todayStrip: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 8))
            : AnyLayout(HStackLayout(spacing: 10))
        return layout {
            MetricPill(title: "今日", value: store.todayFocusSeconds.hourMinuteText, tint: .cyan)
            MetricPill(title: "本周", value: store.weekFocusSeconds.hourMinuteText, tint: .mint)
            MetricPill(title: "完成轮次", value: "\(store.completedFocusRounds)", tint: .orange)
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
                .font(.system(.headline, design: .rounded).bold())
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
    @EnvironmentObject private var store: FocusStore

    let task: FocusTask
    let isSelected: Bool
    let isTimerRunning: Bool
    var showsCategoryBadge = true

    private var categoryTint: Color {
        Color(hex: store.representativeAccentHex(for: task.category))
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
        HStack(spacing: 12) {
            Circle()
                .fill(categoryTint)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
                    .lineLimit(1)
                if showsCategoryBadge || task.dueDate != nil {
                    HStack(spacing: 6) {
                        if showsCategoryBadge {
                            TimerTaskCategoryBadge(task: task)
                        }
                        if let dueDate = task.dueDate {
                            Text(dueDate.scheduleTimeText)
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                                .lineLimit(1)
                        }
                    }
                }
            }

            Spacer()

            ProgressView(value: task.progress)
                .tint(categoryTint)
                .frame(width: 58)

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? AppTheme.readableTint(categoryTint) : AppTheme.secondaryText)
        }
        .padding(12)
        .background(isSelected ? categoryTint.opacity(0.13) : AppTheme.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isSelected ? categoryTint.opacity(0.7) : AppTheme.border, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(task.title)，\(task.category)分类，\(selectionStateText)")
        .accessibilityHint(selectionHintText)
        .accessibilityInputLabels(selectionInputLabels)
        .accessibilityAddTraits(selectionAccessibilityTraits)
    }
}

private struct TimerTaskCategoryFilterBar: View {
    @EnvironmentObject private var store: FocusStore
    @State private var searchQuery = ""

    let categories: [String]
    @Binding var selectedCategory: String?
    let countProvider: (String?) -> Int

    private var categoryOptions: [TaskCategoryFilterOption] {
        TaskCategoryPreset.prioritizedFilterOptions(
            categories: categories,
            countProvider: { category in countProvider(category) },
            accentProvider: { category in store.representativeAccentHex(for: category) }
        )
    }

    private var searchResult: TaskCategorySearchResult {
        TaskCategorySearchResult(options: categoryOptions, query: searchQuery, selectedCategory: selectedCategory)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if searchResult.showsSearch {
                CategoryFilterSearchField(query: $searchQuery, matchedCount: searchResult.matches.count, totalCount: searchResult.totalCount)
            }
            categoryStrip
            if let option = searchResult.pinnedSelection {
                Text("当前已选")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                TimerTaskCategoryFilterChip(title: option.category, symbolName: option.symbolName, count: option.count, isSelected: true, tintHex: option.accentHex) {
                    toggleCategory(option.category)
                }
            }
        }
    }

    private var categoryStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                TimerTaskCategoryFilterChip(
                    title: "全部",
                    symbolName: "tray.full.fill",
                    count: countProvider(nil),
                    isSelected: selectedCategory == nil,
                    tintHex: TaskCategoryPreset.fallbackAccentHex
                ) {
                    selectedCategory = nil
                }

                ForEach(searchResult.matches) { option in
                    TimerTaskCategoryFilterChip(
                        title: option.category,
                        symbolName: option.symbolName,
                        count: option.count,
                        isSelected: selectedCategory.map { store.categoryMatches($0, option.category) } ?? false,
                        tintHex: option.accentHex
                    ) {
                        toggleCategory(option.category)
                    }
                }
            }
            .padding(.vertical, 1)
        }
    }

    private func toggleCategory(_ category: String) {
        selectedCategory = selectedCategory.map { store.categoryMatches($0, category) ? nil : category } ?? category
    }
}

private struct TimerTaskCategoryFilterChip: View {
    let title: String
    let symbolName: String
    let count: Int
    let isSelected: Bool
    let tintHex: String
    let action: () -> Void

    private var tint: Color {
        Color(hex: tintHex)
    }

    private var selectedText: Color {
        Color(hex: TaskCategoryPreset.contrastTextHex(on: tintHex))
    }

    private var accessibilityStateText: String {
        isSelected ? "，已选中" : ""
    }

    private var accessibilityHintText: String {
        if isSelected {
            return title == "全部" ? "当前显示全部分类" : "再次点击清除筛选"
        }
        return title == "全部" ? "显示全部分类" : "筛选\(title)分类"
    }

    private var accessibilityTraits: AccessibilityTraits {
        isSelected ? .isSelected : []
    }

    private var voiceControlInputLabels: [Text] {
        [Text(title), Text("\(title)分类")]
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: symbolName)
                Text(title)
                Text("\(count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isSelected ? selectedText.opacity(0.82) : AppTheme.readableTint(tint))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.black.opacity(0.08) : tint.opacity(0.16), in: Capsule())
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(isSelected ? selectedText : AppTheme.primaryText)
            .frame(minHeight: 44)
            .padding(.horizontal, 10)
            .background(isSelected ? tint : AppTheme.panel, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(isSelected ? tint.opacity(0.9) : AppTheme.border, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title)分类，\(count)项\(accessibilityStateText)")
        .accessibilityHint(accessibilityHintText)
        .accessibilityAddTraits(accessibilityTraits)
        .accessibilityInputLabels(voiceControlInputLabels)
    }
}

private struct TimerSelectedTaskCategorySummaryView: View {
    @EnvironmentObject private var store: FocusStore

    let category: String
    let filteredCount: Int
    let totalCount: Int
    let onAddTask: () -> Void
    let onClear: () -> Void

    private var preset: TaskCategoryPreset? {
        TaskCategoryPreset.matching(category)
    }

    private var tint: Color {
        Color(hex: store.representativeAccentHex(for: category))
    }

    private var tintText: Color {
        Color(hex: TaskCategoryPreset.contrastTextHex(on: store.representativeAccentHex(for: category)))
    }

    private var addButtonInputLabels: [Text] {
        [
            Text("新增此分类"),
            Text("新增\(category)分类待办"),
            Text("新增\(category)分类")
        ]
    }

    private var clearButtonInputLabels: [Text] {
        [
            Text("清除筛选"),
            Text("清除\(category)分类"),
            Text("查看全部分类")
        ]
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            TimerSelectedTaskCategorySummaryContent(
                category: category,
                symbolName: preset?.symbolName ?? "tag.fill",
                filteredCount: filteredCount,
                totalCount: totalCount,
                tint: tint,
                tintText: tintText,
                addButtonInputLabels: addButtonInputLabels,
                clearButtonInputLabels: clearButtonInputLabels,
                axis: .horizontal,
                onAddTask: onAddTask,
                onClear: onClear
            )

            TimerSelectedTaskCategorySummaryContent(
                category: category,
                symbolName: preset?.symbolName ?? "tag.fill",
                filteredCount: filteredCount,
                totalCount: totalCount,
                tint: tint,
                tintText: tintText,
                addButtonInputLabels: addButtonInputLabels,
                clearButtonInputLabels: clearButtonInputLabels,
                axis: .vertical,
                onAddTask: onAddTask,
                onClear: onClear
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(tint.opacity(0.36), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("当前筛选\(category)分类，\(filteredCount)/\(totalCount)项可启动待办，可新增此分类待办或清除筛选")
    }
}

private struct TimerSelectedTaskCategorySummaryContent: View {
    let category: String
    let symbolName: String
    let filteredCount: Int
    let totalCount: Int
    let tint: Color
    let tintText: Color
    let addButtonInputLabels: [Text]
    let clearButtonInputLabels: [Text]
    let axis: Axis
    let onAddTask: () -> Void
    let onClear: () -> Void

    var body: some View {
        let layout = axis == .horizontal
            ? AnyLayout(HStackLayout(spacing: 10))
            : AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
        let actionsLayout = axis == .horizontal
            ? AnyLayout(HStackLayout(spacing: 8))
            : AnyLayout(VStackLayout(spacing: 8))
        let titleLayout = axis == .horizontal
            ? AnyLayout(HStackLayout(spacing: 8))
            : AnyLayout(VStackLayout(alignment: .leading, spacing: 6))

        layout {
            titleLayout {
                Label(category, systemImage: symbolName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)
                    .lineLimit(axis == .horizontal ? 1 : 2)

                Text("\(filteredCount)/\(totalCount) 项")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.readableTint(tint))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(tint.opacity(0.14), in: Capsule())
                    .fixedSize()
            }
            .frame(maxWidth: axis == .vertical ? .infinity : nil, alignment: .leading)

            if axis == .horizontal {
                Spacer(minLength: 0)
            }

            actionsLayout {
                Button("新增此分类", systemImage: "plus.circle.fill", action: onAddTask)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(tintText)
                    .buttonStyle(.plain)
                    .frame(maxWidth: axis == .vertical ? .infinity : nil)
                    .frame(minHeight: 44)
                    .padding(.horizontal, 10)
                    .background(tint, in: Capsule())
                    .accessibilityLabel("新增\(category)分类待办")
                    .accessibilityHint("打开待办编辑器并预填\(category)分类")
                    .accessibilityInputLabels(addButtonInputLabels)

                Button("清除筛选", systemImage: "xmark.circle.fill", action: onClear)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.readableTint(tint))
                    .buttonStyle(.plain)
                    .frame(minWidth: 72)
                    .frame(maxWidth: axis == .vertical ? .infinity : nil)
                    .frame(minHeight: 44)
                    .accessibilityLabel("清除\(category)分类筛选")
                    .accessibilityHint("显示全部分类的待办")
                    .accessibilityInputLabels(clearButtonInputLabels)
            }
            .frame(maxWidth: axis == .vertical ? .infinity : nil, alignment: .trailing)
        }
        .fixedSize(horizontal: axis == .horizontal, vertical: false)
    }
}

private struct TimerTaskCategoryEmptyView: View {
    @EnvironmentObject private var store: FocusStore

    let category: String
    let onAddTask: () -> Void
    let onClear: () -> Void

    private var preset: TaskCategoryPreset? {
        TaskCategoryPreset.matching(category)
    }

    private var tint: Color {
        Color(hex: store.representativeAccentHex(for: category))
    }

    private var tintHex: String {
        store.representativeAccentHex(for: category)
    }

    private var addButtonInputLabels: [Text] {
        [
            Text("新增此分类"),
            Text("新增\(category)分类待办"),
            Text("新增\(category)分类")
        ]
    }

    private var clearButtonInputLabels: [Text] {
        [
            Text("清除筛选"),
            Text("清除\(category)分类"),
            Text("查看全部分类")
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "tag.slash")
                    .foregroundStyle(AppTheme.readableTint(tint))
                Text("\(category) 分类暂无可启动待办")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(2)
                Spacer(minLength: 0)
            }

            Text("可新增此分类待办，或清除筛选查看全部。")
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)

            ViewThatFits(in: .horizontal) {
                TimerTaskCategoryEmptyActions(
                    category: category,
                    tint: tint,
                    tintHex: tintHex,
                    addButtonInputLabels: addButtonInputLabels,
                    clearButtonInputLabels: clearButtonInputLabels,
                    axis: .horizontal,
                    onAddTask: onAddTask,
                    onClear: onClear
                )

                TimerTaskCategoryEmptyActions(
                    category: category,
                    tint: tint,
                    tintHex: tintHex,
                    addButtonInputLabels: addButtonInputLabels,
                    clearButtonInputLabels: clearButtonInputLabels,
                    axis: .vertical,
                    onAddTask: onAddTask,
                    onClear: onClear
                )
            }
        }
        .padding(12)
        .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(category)分类暂无可启动待办，可新增此分类待办或清除筛选")
    }
}

private struct TimerTaskCategoryEmptyActions: View {
    let category: String
    let tint: Color
    let tintHex: String
    let addButtonInputLabels: [Text]
    let clearButtonInputLabels: [Text]
    let axis: Axis
    let onAddTask: () -> Void
    let onClear: () -> Void

    private var tintText: Color {
        Color(hex: TaskCategoryPreset.contrastTextHex(on: tintHex))
    }

    var body: some View {
        let layout = axis == .horizontal
            ? AnyLayout(HStackLayout(spacing: 8))
            : AnyLayout(VStackLayout(spacing: 8))

        layout {
            Button("新增此分类", systemImage: "plus.circle.fill", action: onAddTask)
                .font(.caption.weight(.bold))
                .foregroundStyle(tintText)
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .padding(.horizontal, 10)
                .background(tint, in: Capsule())
                .accessibilityLabel("新增\(category)分类待办")
                .accessibilityInputLabels(addButtonInputLabels)

            Button("清除", systemImage: "xmark.circle.fill", action: onClear)
                .font(.caption.weight(.bold))
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.readableTint(tint))
                .frame(minWidth: 72)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .accessibilityLabel("清除\(category)分类筛选")
                .accessibilityInputLabels(clearButtonInputLabels)
        }
        .fixedSize(horizontal: axis == .horizontal, vertical: false)
    }
}

private struct TimerTaskCategoryBadge: View {
    @EnvironmentObject private var store: FocusStore

    let task: FocusTask

    private var preset: TaskCategoryPreset? {
        TaskCategoryPreset.matching(task.category)
    }

    private var tint: Color {
        Color(hex: store.representativeAccentHex(for: task.category))
    }

    private var categorySymbolName: String {
        preset?.symbolName ?? "tag.fill"
    }

    var body: some View {
        Label(task.category, systemImage: categorySymbolName)
            .lineLimit(1)
            .font(.caption.weight(.bold))
            .foregroundStyle(AppTheme.readableTint(tint))
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(tint.opacity(0.14), in: Capsule())
            .accessibilityLabel("\(task.category)分类")
            .accessibilityInputLabels([Text(task.category), Text("\(task.category)分类")])
    }
}

private struct IconActionButtonStyle: ButtonStyle {
    let tint: Color
    let filled: Bool
    let tintHex: String?

    init(tint: Color, filled: Bool, tintHex: String? = nil) {
        self.tint = tint
        self.filled = filled
        self.tintHex = tintHex
    }

    func makeBody(configuration: Configuration) -> some View {
        let foreground = filled
            ? Color(hex: TaskCategoryPreset.contrastTextHex(on: tintHex))
            : AppTheme.readableTint(tint)

        configuration.label
            .font(.headline)
            .foregroundStyle(foreground)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 48)
            .contentShape(Rectangle())
            .background(filled ? tint : tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(tint.opacity(0.52), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

import SwiftUI

struct ScheduleView: View {
    @EnvironmentObject private var store: FocusStore
    @EnvironmentObject private var engine: TimerEngine
    @EnvironmentObject private var notifications: NotificationService
    @EnvironmentObject private var premium: PremiumAccessService
    @EnvironmentObject private var calendarSync: CalendarSyncService
    @State private var selectedDate = Date()
    @State private var calendarMode: CalendarDisplayMode = .week
    @State private var selectedCategory: String?
    @State private var showingEditor = false
    @State private var editingTask: FocusTask?

    private let calendar = Calendar.current

    private var visibleTasks: [FocusTask] {
        store.tasks
            .filter { task in
                isTaskInSelectedRange(task) && matchesSelectedCategory(task)
            }
            .sorted {
                switch ($0.dueDate, $1.dueDate) {
                case let (left?, right?): return left < right
                case (_?, nil): return true
                case (nil, _?): return false
                case (nil, nil): return $0.createdAt > $1.createdAt
                }
            }
    }

    private var taskListCountText: String {
        let totalCount = taskCount(in: nil)
        guard totalCount > 0 else {
            return "0 项"
        }
        guard selectedCategory != nil else {
            return "\(totalCount) 项"
        }
        return "\(visibleTasks.count)/\(totalCount) 项"
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    calendarPanel
                    calendarSyncPanel
                    pomodoroPlanPanel
                    taskList
                }
                .padding(18)
                .padding(.bottom, 26)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("日程")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("新增待办")
                }
            }
            .sheet(isPresented: $showingEditor) {
                TaskEditorView(initialDueDate: defaultNewTaskDate, initialCategory: selectedCategory)
                    .environmentObject(store)
                    .environmentObject(notifications)
                    .presentationDetents([.medium, .large])
            }
            .sheet(item: $editingTask) { task in
                TaskEditorView(task: task, initialDueDate: selectedDate)
                    .environmentObject(store)
                    .environmentObject(notifications)
                    .presentationDetents([.medium, .large])
            }
        }
    }

    private var defaultNewTaskDate: Date {
        let base = calendar.startOfDay(for: selectedDate)
        let hour = max(9, calendar.component(.hour, from: Date()) + 1)
        return calendar.date(byAdding: .hour, value: min(hour, 22), to: base) ?? selectedDate
    }

    private var calendarPanel: some View {
        GlassPanel {
            VStack(spacing: 14) {
                HStack {
                    Label(calendarTitle, systemImage: "calendar")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)
                    Spacer()
                    Picker("范围", selection: $calendarMode) {
                        ForEach(CalendarDisplayMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                }

                HStack {
                    Button {
                        moveSelection(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("上一段")

                    Spacer()

                    Button("今天") {
                        selectedDate = Date()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan)

                    Spacer()

                    Button {
                        moveSelection(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                    .buttonStyle(.bordered)
                    .accessibilityLabel("下一段")
                }

                if calendarMode == .month {
                    monthGrid
                } else {
                    weekStrip
                }
            }
        }
    }

    private var calendarSyncPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("iPhone 日历同步", systemImage: "calendar.badge.plus")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)
                    Spacer()
                    Text("Pro")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.cyan)
                }

                Text("支持同步 iPhone 日历；通过 Siri 语音创建的日程，进入 App 后一键同步为待办。")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)

                if premium.isProUnlocked {
                    Button {
                        Task { await calendarSync.syncUpcomingEvents(into: store) }
                    } label: {
                        Label(calendarSync.isSyncing ? "同步中" : "同步近期日程", systemImage: "arrow.triangle.2.circlepath")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan)
                    .disabled(calendarSync.isSyncing)

                    Text(calendarSync.statusText)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                } else {
                    Button {
                        Task { await premium.purchasePro() }
                    } label: {
                        Label("解锁 Pro 同步日历", systemImage: "lock.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan)
                }
            }
        }
    }

    private var pomodoroPlanPanel: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("自动番茄钟计划", systemImage: "calendar.badge.plus")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)
                    Spacer()
                    Text("\(store.pomodoroPlan.filter { !$0.isCompleted }.count) 轮")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.cyan)
                }

                HStack(spacing: 10) {
                    Button {
                        store.generatePomodoroPlanFromSchedule()
                    } label: {
                        Label("按日程生成", systemImage: "wand.and.stars")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan)

                    Button {
                        store.clearPomodoroPlan()
                    } label: {
                        Image(systemName: "trash")
                            .frame(width: 44, height: 34)
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .disabled(store.pomodoroPlan.isEmpty)
                    .accessibilityLabel("清空番茄钟计划")
                }

                if !store.pomodoroPlan.isEmpty {
                    VStack(spacing: 10) {
                        ForEach(store.pomodoroPlan.prefix(5)) { item in
                            PomodoroPlanRow(item: item, isRunning: engine.isRunning) {
                                engine.startPlanItem(item)
                            }
                        }
                    }
                }
            }
        }
    }

    private var taskList: some View {
        GlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("待办事项", systemImage: "checklist")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)
                    Spacer()
                    Text(taskListCountText)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }

                TaskCategoryFilterBar(
                    categories: store.taskCategories,
                    selectedCategory: $selectedCategory,
                    countProvider: taskCount(in:)
                )

                if let selectedCategoryName = selectedCategory {
                    SelectedCategorySummaryView(
                        category: selectedCategoryName,
                        count: taskCount(in: selectedCategoryName),
                        onAddTask: {
                            showingEditor = true
                        },
                        onClear: {
                            selectedCategory = nil
                        }
                    )
                }

                if visibleTasks.isEmpty {
                    Text(emptyTaskListText)
                        .foregroundStyle(AppTheme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    VStack(spacing: 10) {
                        ForEach(visibleTasks) { task in
                            ScheduleTaskCell(task: task) {
                                toggleTask(task)
                            } onEnable: {
                                setTask(task, enabled: !task.isEnabled)
                            } onEdit: {
                                editingTask = task
                            }
                            .swipeActions {
                                Button {
                                    editingTask = task
                                } label: {
                                    Label("编辑", systemImage: "pencil")
                                }
                                .tint(.cyan)

                                Button(role: .destructive) {
                                    notifications.cancelTaskReminder(taskID: task.id)
                                    store.deleteTasks(ids: [task.id])
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private var calendarTitle: String {
        switch calendarMode {
        case .day:
            return selectedDate.scheduleTimeText
        case .week:
            return "本周安排"
        case .month:
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.dateFormat = "yyyy年M月"
            return formatter.string(from: selectedDate)
        }
    }

    private var weekStrip: some View {
        HStack(spacing: 8) {
            ForEach(daysInSelectedWeek, id: \.self) { date in
                CalendarDayButton(
                    date: date,
                    isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                    taskCount: taskCount(on: date)
                ) {
                    selectedDate = date
                }
            }
        }
    }

    private var monthGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
            ForEach(monthGridDates, id: \.self) { date in
                CalendarDayButton(
                    date: date,
                    isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                    isMuted: !calendar.isDate(date, equalTo: selectedDate, toGranularity: .month),
                    taskCount: taskCount(on: date)
                ) {
                    selectedDate = date
                }
            }
        }
    }

    private var daysInSelectedWeek: [Date] {
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else { return [selectedDate] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: interval.start) }
    }

    private var monthGridDates: [Date] {
        guard
            let month = calendar.dateInterval(of: .month, for: selectedDate),
            let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: month.start)
        else { return [] }
        return (0..<42).compactMap { calendar.date(byAdding: .day, value: $0, to: firstWeek.start) }
    }

    private func taskCount(on date: Date) -> Int {
        store.tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: date)
        }.count
    }

    private func taskCount(in category: String?) -> Int {
        guard let category else {
            return store.tasks.filter(isTaskInSelectedRange).count
        }
        return store.tasks.filter { task in
            isTaskInSelectedRange(task) && task.category == category
        }.count
    }

    private func isTaskInSelectedRange(_ task: FocusTask) -> Bool {
        guard let date = task.dueDate else {
            return calendarMode == .day && calendar.isDate(task.createdAt, inSameDayAs: selectedDate)
        }
        switch calendarMode {
        case .day:
            return calendar.isDate(date, inSameDayAs: selectedDate)
        case .week:
            return calendar.isDate(date, equalTo: selectedDate, toGranularity: .weekOfYear)
        case .month:
            return calendar.isDate(date, equalTo: selectedDate, toGranularity: .month)
        }
    }

    private func matchesSelectedCategory(_ task: FocusTask) -> Bool {
        guard let selectedCategory else { return true }
        return task.category == selectedCategory
    }

    private var emptyTaskListText: String {
        if let selectedCategory {
            return "当前时间范围没有「\(selectedCategory)」分类待办。可清除筛选查看全部，或点击新增此分类创建待办。"
        }
        return "这个时间范围还没有待办。点击右上角添加，或用 Pro 同步 iPhone 日历。"
    }

    private func moveSelection(by value: Int) {
        let component: Calendar.Component
        switch calendarMode {
        case .day: component = .day
        case .week: component = .weekOfYear
        case .month: component = .month
        }
        selectedDate = calendar.date(byAdding: component, value: value, to: selectedDate) ?? selectedDate
    }

    private func toggleTask(_ task: FocusTask) {
        if let updatedTask = store.toggleTaskDone(task) {
            syncTaskReminder(for: updatedTask, store: store, notifications: notifications)
        }
    }

    private func setTask(_ task: FocusTask, enabled: Bool) {
        if let updatedTask = store.setTaskEnabled(task, enabled: enabled) {
            syncTaskReminder(for: updatedTask, store: store, notifications: notifications)
        }
    }
}

private struct SelectedCategorySummaryView: View {
    let category: String
    let count: Int
    let onAddTask: () -> Void
    let onClear: () -> Void

    private var preset: TaskCategoryPreset? {
        TaskCategoryPreset.matching(category)
    }

    private var tint: Color {
        Color(hex: preset?.accentHex ?? "#3DE8C5")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Label(category, systemImage: preset?.symbolName ?? "tag.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryText)

                Text("\(count) 项")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(tint)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(tint.opacity(0.14), in: Capsule())

                Spacer()
            }

            HStack(spacing: 8) {
                Button("新增此分类", systemImage: "plus.circle.fill", action: onAddTask)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.black.opacity(0.82))
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .padding(.horizontal, 10)
                    .background(tint, in: Capsule())

                Button("清除", systemImage: "xmark.circle.fill", action: onClear)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(tint)
                    .buttonStyle(.plain)
                    .frame(minWidth: 72)
                    .frame(minHeight: 44)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(tint.opacity(0.36), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("当前筛选\(category)分类，\(count)项，可新增此分类待办或清除筛选")
    }
}

private struct CalendarDayButton: View {
    let date: Date
    let isSelected: Bool
    var isMuted = false
    let taskCount: Int
    let action: () -> Void

    private var dayText: String {
        "\(Calendar.current.component(.day, from: date))"
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Text(dayText)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(isSelected ? .black : (isMuted ? AppTheme.secondaryText : AppTheme.primaryText))
                Circle()
                    .fill(taskCount > 0 ? (isSelected ? .black : .cyan) : .clear)
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(isSelected ? Color.cyan : AppTheme.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isSelected ? Color.cyan.opacity(0.8) : AppTheme.border, lineWidth: 1)
            }
            .opacity(isMuted ? 0.55 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(date.scheduleTimeText)，\(taskCount)项待办")
    }
}

private struct TaskCategoryFilterBar: View {
    let categories: [String]
    @Binding var selectedCategory: String?
    let countProvider: (String?) -> Int

    private var categoryOptions: [TaskCategoryFilterOption] {
        TaskCategoryPreset.prioritizedFilterOptions(categories: categories) { category in
            countProvider(category)
        }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                TaskCategoryFilterChip(
                    title: "全部",
                    symbolName: "tray.full.fill",
                    count: countProvider(nil),
                    isSelected: selectedCategory == nil,
                    tintHex: "#3DE8C5"
                ) {
                    selectedCategory = nil
                }

                ForEach(categoryOptions) { option in
                    TaskCategoryFilterChip(
                        title: option.category,
                        symbolName: option.symbolName,
                        count: option.count,
                        isSelected: selectedCategory == option.category,
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
        selectedCategory = selectedCategory == category ? nil : category
    }
}

private struct TaskCategoryFilterChip: View {
    let title: String
    let symbolName: String
    let count: Int
    let isSelected: Bool
    let tintHex: String
    let action: () -> Void

    private var tint: Color {
        Color(hex: tintHex)
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
                    .foregroundStyle(isSelected ? Color.black.opacity(0.72) : tint)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.black.opacity(0.08) : tint.opacity(0.16), in: Capsule())
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(isSelected ? Color.black.opacity(0.82) : AppTheme.primaryText)
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

private struct ScheduleTaskCell: View {
    let task: FocusTask
    let onToggle: () -> Void
    let onEnable: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(task.isDone ? .mint : Color(hex: task.accentHex))
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.isDone ? "标记待办未完成" : "完成待办")

            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text(task.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(task.isDone ? AppTheme.secondaryText : AppTheme.primaryText)
                        .lineLimit(1)
                    Spacer()
                    Text(task.startMode.title)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color(hex: task.accentHex))
                }

                ProgressView(value: task.progress)
                    .tint(Color(hex: task.accentHex))

                HStack(spacing: 8) {
                    Text(task.category)
                    if let dueDate = task.dueDate {
                        Text(dueDate.scheduleTimeText)
                    }
                    if task.recurrence != .none {
                        Text(task.recurrence.title)
                    }
                    if task.autoStartPomodoro {
                        Text("自动开始")
                    }
                }
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
                .lineLimit(1)
            }

            VStack(spacing: 8) {
                Button(action: onEnable) {
                    Image(systemName: task.isEnabled ? "bolt.circle.fill" : "bolt.slash.circle")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(task.isEnabled ? .cyan : AppTheme.secondaryText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(task.isEnabled ? "停用待办" : "启用待办")

                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.secondaryText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("编辑待办")
            }
            .frame(width: 34)
        }
        .padding(12)
        .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct TaskEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: FocusStore
    @EnvironmentObject private var notifications: NotificationService
    @State private var title = ""
    @State private var category = "工作"
    @State private var dueDate: Date
    @State private var usesDueDate = true
    @State private var estimatedRounds = 2
    @State private var accentHex = "#3DE8C5"
    @State private var isEnabled = true
    @State private var autoStartPomodoro = false
    @State private var startMode: TaskStartMode = .plannedRounds
    @State private var recurrence: TaskRecurrence = .none

    private let task: FocusTask?
    private let colors = ["#3DE8C5", "#A78BFA", "#FFB84D", "#FF6B6B", "#54A0FF"]

    init(task: FocusTask? = nil, initialDueDate: Date, initialCategory: String? = nil) {
        self.task = task
        let startingCategory = task?.category ?? initialCategory ?? "工作"
        _title = State(initialValue: task?.title ?? "")
        _category = State(initialValue: startingCategory)
        _dueDate = State(initialValue: task?.dueDate ?? initialDueDate)
        _usesDueDate = State(initialValue: task?.dueDate != nil || task == nil)
        _estimatedRounds = State(initialValue: task?.estimatedRounds ?? 2)
        _accentHex = State(initialValue: task?.accentHex ?? TaskCategoryPreset.matching(startingCategory)?.accentHex ?? "#3DE8C5")
        _isEnabled = State(initialValue: task?.isEnabled ?? true)
        _autoStartPomodoro = State(initialValue: task?.autoStartPomodoro ?? false)
        _startMode = State(initialValue: task?.startMode ?? .plannedRounds)
        _recurrence = State(initialValue: task?.recurrence ?? .none)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("待办") {
                    TextField("标题", text: $title)
                    TextField("分类", text: $category)
                    TaskCategoryPresetPicker(category: $category, accentHex: $accentHex)
                    Toggle("启用", isOn: $isEnabled)
                    Toggle("设置开始时间", isOn: $usesDueDate)
                    if usesDueDate {
                        DatePicker("开始", selection: $dueDate)
                    }
                    Picker("模式", selection: $startMode) {
                        ForEach(TaskStartMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    Picker("循环", selection: $recurrence) {
                        ForEach(TaskRecurrence.allCases) { recurrence in
                            Text(recurrence.title).tag(recurrence)
                        }
                    }
                    Toggle("到时间自动开启番茄钟", isOn: $autoStartPomodoro)
                }

                Section("番茄钟") {
                    if startMode == .plannedRounds {
                        Stepper("\(estimatedRounds) 轮", value: $estimatedRounds, in: 1...12)
                    } else {
                        Text("只创建开始时间，完成时手动结束并计入统计。")
                            .foregroundStyle(AppTheme.secondaryText)
                    }

                    HStack {
                        ForEach(colors, id: \.self) { hex in
                            Button {
                                accentHex = hex
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 30, height: 30)
                                    .overlay {
                                        if accentHex == hex {
                                            Image(systemName: "checkmark")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(.black)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle(task == nil ? "新增待办" : "编辑待办")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func save() {
        let savedTask: FocusTask?
        let cleanRounds = startMode == .openEnded ? 1 : estimatedRounds
        if let task {
            savedTask = store.updateTask(
                task,
                title: title,
                category: category,
                dueDate: usesDueDate ? dueDate : nil,
                estimatedRounds: cleanRounds,
                accentHex: accentHex,
                isEnabled: isEnabled,
                autoStartPomodoro: autoStartPomodoro,
                startMode: startMode,
                recurrence: recurrence
            )
        } else {
            savedTask = store.addTask(
                title: title,
                category: category,
                dueDate: usesDueDate ? dueDate : nil,
                estimatedRounds: cleanRounds,
                accentHex: accentHex,
                isEnabled: isEnabled,
                autoStartPomodoro: autoStartPomodoro,
                startMode: startMode,
                recurrence: recurrence
            )
        }

        if let savedTask {
            syncTaskReminder(for: savedTask, store: store, notifications: notifications)
        }
    }
}

private struct TaskCategoryPresetPicker: View {
    @Binding var category: String
    @Binding var accentHex: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TaskCategoryPreset.defaults) { preset in
                    Button {
                        category = preset.title
                        accentHex = preset.accentHex
                    } label: {
                        Label(preset.title, systemImage: preset.symbolName)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(isSelected(preset) ? Color.black.opacity(0.82) : AppTheme.primaryText)
                            .frame(minHeight: 44)
                            .padding(.horizontal, 10)
                            .background(isSelected(preset) ? Color(hex: preset.accentHex) : AppTheme.panel, in: Capsule())
                            .overlay {
                                Capsule()
                                    .stroke(Color(hex: preset.accentHex).opacity(isSelected(preset) ? 0.9 : 0.42), lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(preset.title)分类\(accessibilityStateText(for: preset))")
                    .accessibilityHint(accessibilityHintText(for: preset))
                    .accessibilityAddTraits(accessibilityTraits(for: preset))
                    .accessibilityInputLabels(voiceControlInputLabels(for: preset))
                }
            }
            .padding(.vertical, 2)
        }
        .accessibilityLabel("常用分类")
    }

    private func isSelected(_ preset: TaskCategoryPreset) -> Bool {
        category.trimmingCharacters(in: .whitespacesAndNewlines) == preset.title
    }

    private func accessibilityStateText(for preset: TaskCategoryPreset) -> String {
        isSelected(preset) ? "，已选中" : ""
    }

    private func accessibilityHintText(for preset: TaskCategoryPreset) -> String {
        isSelected(preset) ? "当前使用\(preset.title)分类" : "选择\(preset.title)分类"
    }

    private func accessibilityTraits(for preset: TaskCategoryPreset) -> AccessibilityTraits {
        isSelected(preset) ? .isSelected : []
    }

    private func voiceControlInputLabels(for preset: TaskCategoryPreset) -> [Text] {
        [Text(preset.title), Text("\(preset.title)分类")]
    }
}

@MainActor
private func syncTaskReminder(for task: FocusTask, store: FocusStore, notifications: NotificationService) {
    guard task.isEnabled, store.settings.notificationsEnabled && store.settings.taskDueRemindersEnabled else {
        notifications.cancelTaskReminder(taskID: task.id)
        return
    }

    Task {
        await notifications.scheduleTaskReminder(for: task, soundEnabled: store.settings.soundEnabled && store.settings.soundVolume > 0)
    }
}

private struct PomodoroPlanRow: View {
    let item: PomodoroPlanItem
    let isRunning: Bool
    let onStart: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "timer")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(item.isCompleted ? .mint : Color(hex: item.accentHex))
                .frame(width: 34, height: 34)
                .background(Color(hex: item.accentHex).opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.taskTitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(item.isCompleted ? AppTheme.secondaryText : AppTheme.primaryText)
                    .lineLimit(1)
                Text("\(item.timeRangeText) · 第 \(item.roundNumber) 轮 · \(item.category)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onStart) {
                Image(systemName: "play.fill")
                    .font(.caption.weight(.bold))
                    .frame(width: 34, height: 34)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: item.accentHex))
            .disabled(item.isCompleted || isRunning)
            .accessibilityLabel("开始计划番茄钟")
        }
        .padding(12)
        .background(AppTheme.panel, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

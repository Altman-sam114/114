import SwiftUI

struct MacScheduleDetailView: View {
    @EnvironmentObject private var store: FocusStore
    @EnvironmentObject private var engine: TimerEngine
    @EnvironmentObject private var premium: MacPremiumAccessService
    @EnvironmentObject private var calendarSync: MacCalendarSyncService
    @EnvironmentObject private var notifications: MacNotificationService
    @State private var taskTitle = ""
    @State private var category = "工作"
    @State private var dueDate = Date().addingTimeInterval(3600)
    @State private var estimatedRounds = 2
    @State private var accentHex = "#3DE8C5"
    @Environment(\.macSnapshotRendering) private var isSnapshotRendering

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            MacPageHeaderView(
                title: "日程计划",
                subtitle: "先把 Mac 版基础待办、计划生成和启动流程跑通。",
                symbolName: "calendar"
            )

            HStack(alignment: .top, spacing: 18) {
                MacGlassPanel {
                    VStack(alignment: .leading, spacing: 14) {
                        Label("快速新增", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .foregroundStyle(MacTheme.primaryText)

                        if isSnapshotRendering {
                            MacStaticInputRowView(title: "任务名称", value: "新的专注任务")
                            MacStaticInputRowView(title: "分类", value: category)
                            MacStaticCategoryPresetStrip(selectedCategory: category)
                            MacStaticInputRowView(title: "截止时间", value: dueDate.scheduleTimeText)
                            MacStaticInputRowView(title: "预计轮次", value: "\(estimatedRounds) 轮")
                        } else {
                            TextField("任务名称", text: $taskTitle)
                                .textFieldStyle(.roundedBorder)
                            TextField("分类", text: $category)
                                .textFieldStyle(.roundedBorder)
                            MacCategoryPresetPicker(category: $category, accentHex: $accentHex)
                            DatePicker("截止时间", selection: $dueDate)
                            Stepper("预计 \(estimatedRounds) 轮", value: $estimatedRounds, in: 1...12)
                        }

                        Button("新增待办", systemImage: "plus", action: addTask)
                            .buttonStyle(.borderedProminent)
                            .tint(.cyan)
                            .disabled(taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .frame(width: 320)

                VStack(spacing: 18) {
                    MacCalendarPanelView()
                    MacCalendarSyncPanelView()
                    MacPlanPanelView()
                    MacTaskListPanelView()
                }
            }
        }
        .padding(24)
    }

    private func addTask() {
        let task = store.addTask(
            title: taskTitle,
            category: category,
            dueDate: dueDate,
            estimatedRounds: estimatedRounds,
            accentHex: accentHex
        )
        if let task {
            syncMacTaskReminder(for: task, store: store, notifications: notifications)
        }
        taskTitle = ""
        estimatedRounds = 2
        category = "工作"
        accentHex = TaskCategoryPreset.matching(category)?.accentHex ?? "#3DE8C5"
    }
}

private struct MacStaticCategoryPresetStrip: View {
    let selectedCategory: String

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(TaskCategoryPreset.defaults.prefix(3))) { preset in
                Label(preset.title, systemImage: preset.symbolName)
                    .font(.caption.bold())
                    .foregroundStyle(preset.title == selectedCategory ? Color.black.opacity(0.82) : MacTheme.primaryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(
                        preset.title == selectedCategory ? Color(hex: preset.accentHex) : Color.white.opacity(0.06),
                        in: Capsule()
                    )
                    .overlay {
                        Capsule()
                            .stroke(Color(hex: preset.accentHex).opacity(preset.title == selectedCategory ? 0.9 : 0.42), lineWidth: 1)
                    }
            }

            Text("更多")
                .font(.caption.bold())
                .foregroundStyle(MacTheme.secondaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(Color.white.opacity(0.06), in: Capsule())
        }
        .padding(.vertical, 1)
    }
}

private struct MacCalendarPanelView: View {
    @EnvironmentObject private var store: FocusStore
    @State private var selectedDate = Date()
    @State private var calendarMode: CalendarDisplayMode = .week
    @Environment(\.macSnapshotRendering) private var isSnapshotRendering

    private let calendar = Calendar.current

    private var visibleTasks: [FocusTask] {
        store.tasks
            .filter { task in
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
            .sorted {
                switch ($0.dueDate, $1.dueDate) {
                case let (left?, right?): return left < right
                case (_?, nil): return true
                case (nil, _?): return false
                case (nil, nil): return $0.createdAt > $1.createdAt
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

    private var displayedDates: [Date] {
        switch calendarMode {
        case .day:
            return [selectedDate]
        case .week:
            guard let interval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else { return [selectedDate] }
            return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: interval.start) }
        case .month:
            guard
                let month = calendar.dateInterval(of: .month, for: selectedDate),
                let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: month.start)
            else { return [] }
            return (0..<42).compactMap { calendar.date(byAdding: .day, value: $0, to: firstWeek.start) }
        }
    }

    var body: some View {
        MacGlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label(calendarTitle, systemImage: "calendar")
                        .font(.headline)
                        .foregroundStyle(MacTheme.primaryText)
                    Spacer()
                    if isSnapshotRendering {
                        MacStaticSegmentedView(
                            title: "范围",
                            selectedTitle: calendarMode.title,
                            options: CalendarDisplayMode.allCases.map(\.title)
                        )
                    } else {
                        Picker("范围", selection: $calendarMode) {
                            ForEach(CalendarDisplayMode.allCases) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 150)
                    }
                }

                HStack {
                    Button("上一段", systemImage: "chevron.left") {
                        moveSelection(by: -1)
                    }
                    .labelStyle(.iconOnly)

                    Button("今天") {
                        selectedDate = Date()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan)

                    Button("下一段", systemImage: "chevron.right") {
                        moveSelection(by: 1)
                    }
                    .labelStyle(.iconOnly)

                    Spacer()
                    Text("\(visibleTasks.count) 项")
                        .font(.caption)
                        .foregroundStyle(MacTheme.secondaryText)
                }
                .buttonStyle(.bordered)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                    ForEach(displayedDates, id: \.self) { date in
                        MacCalendarDayCell(
                            date: date,
                            isSelected: calendar.isDate(date, inSameDayAs: selectedDate),
                            isMuted: calendarMode == .month && !calendar.isDate(date, equalTo: selectedDate, toGranularity: .month),
                            taskCount: taskCount(on: date)
                        ) {
                            selectedDate = date
                            calendarMode = .day
                        }
                    }
                }

                if visibleTasks.isEmpty {
                    Text("当前范围暂无待办。")
                        .font(.caption)
                        .foregroundStyle(MacTheme.secondaryText)
                } else {
                    ForEach(visibleTasks.prefix(4)) { task in
                        MacTaskRowView(task: task)
                    }
                }
            }
        }
    }

    private func taskCount(on date: Date) -> Int {
        store.tasks.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: date)
        }.count
    }

    private func moveSelection(by value: Int) {
        let component: Calendar.Component
        switch calendarMode {
        case .day:
            component = .day
        case .week:
            component = .weekOfYear
        case .month:
            component = .month
        }
        selectedDate = calendar.date(byAdding: component, value: value, to: selectedDate) ?? selectedDate
    }
}

private struct MacCalendarDayCell: View {
    let date: Date
    let isSelected: Bool
    let isMuted: Bool
    let taskCount: Int
    let action: () -> Void

    private var dayText: String {
        "\(Calendar.current.component(.day, from: date))"
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(dayText)
                    .font(.subheadline.bold())
                    .monospacedDigit()
                Circle()
                    .fill(taskCount > 0 ? (isSelected ? Color.black.opacity(0.8) : Color.cyan) : Color.clear)
                    .frame(width: 5, height: 5)
            }
            .foregroundStyle(isSelected ? Color.black.opacity(0.82) : (isMuted ? MacTheme.secondaryText : MacTheme.primaryText))
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .background(isSelected ? Color.cyan : Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.cyan.opacity(0.75) : MacTheme.border, lineWidth: 1)
            }
            .opacity(isMuted ? 0.48 : 1)
        }
        .buttonStyle(.plain)
    }
}

private struct MacCalendarSyncPanelView: View {
    @EnvironmentObject private var store: FocusStore
    @EnvironmentObject private var premium: MacPremiumAccessService
    @EnvironmentObject private var calendarSync: MacCalendarSyncService
    @EnvironmentObject private var notifications: MacNotificationService

    var body: some View {
        MacGlassPanel {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Mac 日历同步", systemImage: "calendar.badge.plus")
                        .font(.headline)
                        .foregroundStyle(MacTheme.primaryText)
                    Spacer()
                    Text(premium.isProUnlocked ? "Pro 已解锁" : "Pro")
                        .font(.caption.bold())
                        .foregroundStyle(premium.isProUnlocked ? .mint : .cyan)
                }

                Text("同步未来 45 天的非全天日程，并按专注时长估算番茄钟轮次。")
                    .font(.subheadline)
                    .foregroundStyle(MacTheme.secondaryText)

                if premium.isProUnlocked {
                    Button(calendarSync.isSyncing ? "同步中" : "同步近期日程", systemImage: "arrow.triangle.2.circlepath") {
                        Task {
                            await calendarSync.syncUpcomingEvents(into: store)
                            await syncAllMacTaskReminders(store: store, notifications: notifications)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan)
                    .disabled(calendarSync.isSyncing)

                    Text(calendarSync.statusText)
                        .font(.caption)
                        .foregroundStyle(MacTheme.secondaryText)
                } else {
                    HStack {
                        Button("解锁 Pro 同步日历", systemImage: "lock.fill") {
                            Task { await premium.purchasePro() }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.cyan)
                        .disabled(premium.isLoading)

                        Button("恢复购买", systemImage: "arrow.clockwise") {
                            Task { await premium.restorePurchases() }
                        }
                        .buttonStyle(.bordered)
                        .disabled(premium.isLoading)
                    }

                    Text(premium.statusText)
                        .font(.caption)
                        .foregroundStyle(MacTheme.secondaryText)
                }
            }
        }
    }
}

private struct MacPlanPanelView: View {
    @EnvironmentObject private var store: FocusStore
    @EnvironmentObject private var engine: TimerEngine

    var body: some View {
        MacGlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("自动番茄钟计划", systemImage: "wand.and.stars")
                        .font(.headline)
                        .foregroundStyle(MacTheme.primaryText)
                    Spacer()
                    Text("\(store.pomodoroPlan.filter { !$0.isCompleted }.count) 轮")
                        .foregroundStyle(MacTheme.secondaryText)
                }

                HStack {
                    Button("按日程生成", systemImage: "calendar.badge.plus") {
                        store.generatePomodoroPlanFromSchedule()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan)

                    Button("清空", systemImage: "trash", action: store.clearPomodoroPlan)
                        .buttonStyle(.bordered)
                        .disabled(store.pomodoroPlan.isEmpty)
                }

                ForEach(store.pomodoroPlan.prefix(6)) { item in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color(hex: item.accentHex))
                            .frame(width: 9, height: 9)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.taskTitle)
                                .foregroundStyle(MacTheme.primaryText)
                                .lineLimit(1)
                            Text("\(item.timeRangeText) · 第 \(item.roundNumber) 轮")
                                .font(.caption)
                                .foregroundStyle(MacTheme.secondaryText)
                        }
                        Spacer()
                        Button("开始", systemImage: "play.fill") {
                            engine.startPlanItem(item)
                        }
                        .labelStyle(.iconOnly)
                        .disabled(engine.isRunning || item.isCompleted)
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }
}

private struct MacTaskListPanelView: View {
    @EnvironmentObject private var store: FocusStore
    @EnvironmentObject private var notifications: MacNotificationService
    @State private var selectedCategory: String?

    private var visibleTasks: [FocusTask] {
        let tasks = store.upcomingTasks()
        guard let selectedCategory else { return tasks }
        return tasks.filter { $0.category == selectedCategory }
    }

    var body: some View {
        MacGlassPanel {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("待办事项", systemImage: "checklist")
                        .font(.headline)
                        .foregroundStyle(MacTheme.primaryText)
                    Spacer()
                    Text("\(store.upcomingTasks().count) 项未完成")
                        .foregroundStyle(MacTheme.secondaryText)
                }

                MacCategoryFilterBar(
                    categories: store.taskCategories,
                    selectedCategory: $selectedCategory,
                    countProvider: taskCount(in:)
                )

                if visibleTasks.isEmpty {
                    Text(emptyText)
                        .font(.caption)
                        .foregroundStyle(MacTheme.secondaryText)
                }

                ForEach(visibleTasks) { task in
                    HStack(spacing: 12) {
                        Button(task.isDone ? "标记未完成" : "完成", systemImage: task.isDone ? "arrow.uturn.backward.circle" : "checkmark.circle") {
                            toggleTask(task)
                        }
                        .labelStyle(.iconOnly)

                        MacTaskRowView(task: task)

                        Toggle("启用", isOn: Binding(
                            get: { task.isEnabled },
                            set: { setTask(task, enabled: $0) }
                        ))
                        .labelsHidden()

                        Button("删除", systemImage: "trash") {
                            notifications.cancelTaskReminder(taskID: task.id)
                            store.deleteTasks(ids: [task.id])
                        }
                        .labelStyle(.iconOnly)
                    }
                }
            }
        }
    }

    private func taskCount(in category: String?) -> Int {
        guard let category else { return store.upcomingTasks().count }
        return store.upcomingTasks().filter { $0.category == category }.count
    }

    private var emptyText: String {
        if let selectedCategory {
            return "当前没有「\(selectedCategory)」分类的未完成待办。"
        }
        return "当前没有未完成待办。"
    }

    private func toggleTask(_ task: FocusTask) {
        if let updatedTask = store.toggleTaskDone(task) {
            syncMacTaskReminder(for: updatedTask, store: store, notifications: notifications)
        }
    }

    private func setTask(_ task: FocusTask, enabled: Bool) {
        if let updatedTask = store.setTaskEnabled(task, enabled: enabled) {
            syncMacTaskReminder(for: updatedTask, store: store, notifications: notifications)
        }
    }
}

private struct MacCategoryPresetPicker: View {
    @Binding var category: String
    @Binding var accentHex: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(TaskCategoryPreset.defaults) { preset in
                    Button(preset.title, systemImage: preset.symbolName) {
                        category = preset.title
                        accentHex = preset.accentHex
                    }
                    .font(.caption.bold())
                    .foregroundStyle(isSelected(preset) ? Color.black.opacity(0.82) : MacTheme.primaryText)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(isSelected(preset) ? Color(hex: preset.accentHex) : Color.white.opacity(0.06), in: Capsule())
                    .overlay {
                        Capsule()
                            .stroke(Color(hex: preset.accentHex).opacity(isSelected(preset) ? 0.9 : 0.42), lineWidth: 1)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 1)
        }
        .accessibilityLabel("常用分类")
    }

    private func isSelected(_ preset: TaskCategoryPreset) -> Bool {
        category.trimmingCharacters(in: .whitespacesAndNewlines) == preset.title
    }
}

private struct MacCategoryFilterBar: View {
    let categories: [String]
    @Binding var selectedCategory: String?
    let countProvider: (String?) -> Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                MacCategoryFilterChip(
                    title: "全部",
                    symbolName: "tray.full.fill",
                    count: countProvider(nil),
                    isSelected: selectedCategory == nil,
                    tintHex: "#3DE8C5"
                ) {
                    selectedCategory = nil
                }

                ForEach(categories, id: \.self) { category in
                    let preset = TaskCategoryPreset.matching(category)
                    MacCategoryFilterChip(
                        title: category,
                        symbolName: preset?.symbolName ?? "tag.fill",
                        count: countProvider(category),
                        isSelected: selectedCategory == category,
                        tintHex: preset?.accentHex ?? "#3DE8C5"
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.vertical, 1)
        }
    }
}

private struct MacCategoryFilterChip: View {
    let title: String
    let symbolName: String
    let count: Int
    let isSelected: Bool
    let tintHex: String
    let action: () -> Void

    private var tint: Color {
        Color(hex: tintHex)
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: symbolName)
                Text(title)
                Text("\(count)")
                    .font(.caption.bold())
                    .foregroundStyle(isSelected ? Color.black.opacity(0.72) : tint)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.black.opacity(0.08) : tint.opacity(0.16), in: Capsule())
            }
            .font(.caption.bold())
            .foregroundStyle(isSelected ? Color.black.opacity(0.82) : MacTheme.primaryText)
            .frame(minHeight: 34)
            .padding(.horizontal, 10)
            .background(isSelected ? tint : Color.white.opacity(0.06), in: Capsule())
            .overlay {
                Capsule()
                    .stroke(isSelected ? tint.opacity(0.9) : MacTheme.border, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title)分类，\(count)项")
    }
}

@MainActor
private func syncMacTaskReminder(for task: FocusTask, store: FocusStore, notifications: MacNotificationService) {
    guard task.isEnabled, store.settings.notificationsEnabled && store.settings.taskDueRemindersEnabled else {
        notifications.cancelTaskReminder(taskID: task.id)
        return
    }

    Task {
        await notifications.scheduleTaskReminder(
            for: task,
            soundEnabled: store.settings.soundEnabled && store.settings.soundVolume > 0
        )
    }
}

@MainActor
private func syncAllMacTaskReminders(store: FocusStore, notifications: MacNotificationService) async {
    await notifications.syncTaskDueReminders(
        for: store.tasks,
        enabled: store.settings.notificationsEnabled && store.settings.taskDueRemindersEnabled,
        soundEnabled: store.settings.soundEnabled && store.settings.soundVolume > 0
    )
}

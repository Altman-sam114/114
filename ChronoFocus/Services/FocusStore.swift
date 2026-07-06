import Combine
import Foundation

@MainActor
final class FocusStore: ObservableObject {
    @Published var settings: TimerSettings = TimerSettings() {
        didSet { save(settings, key: Keys.settings) }
    }

    @Published var tasks: [FocusTask] = [] {
        didSet { save(tasks, key: Keys.tasks) }
    }

    @Published var sessions: [FocusSession] = [] {
        didSet { save(sessions, key: Keys.sessions) }
    }

    @Published var pomodoroPlan: [PomodoroPlanItem] = [] {
        didSet { save(pomodoroPlan, key: Keys.pomodoroPlan) }
    }

    @Published var activeTimer: ActiveTimerSnapshot? {
        didSet { save(activeTimer, key: Keys.activeTimer) }
    }

    private let defaults: UserDefaults
    private let calendar = Calendar.current

    private enum Keys {
        static let settings = "chrono.focus.settings"
        static let tasks = "chrono.focus.tasks"
        static let sessions = "chrono.focus.sessions"
        static let pomodoroPlan = "chrono.focus.pomodoroPlan"
        static let activeTimer = "chrono.focus.activeTimer"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        settings = Self.load(TimerSettings.self, key: Keys.settings, defaults: defaults) ?? TimerSettings()
        tasks = Self.load([FocusTask].self, key: Keys.tasks, defaults: defaults) ?? []
        sessions = Self.load([FocusSession].self, key: Keys.sessions, defaults: defaults) ?? []
        pomodoroPlan = Self.load([PomodoroPlanItem].self, key: Keys.pomodoroPlan, defaults: defaults) ?? []
        activeTimer = Self.load(ActiveTimerSnapshot.self, key: Keys.activeTimer, defaults: defaults)

        if tasks.isEmpty && sessions.isEmpty {
            tasks = [
                FocusTask(title: "产品原型整理", category: "工作", dueDate: Date().addingTimeInterval(3600 * 5), estimatedRounds: 4, completedRounds: 1, accentHex: "#3DE8C5"),
                FocusTask(title: "SwiftUI 学习", category: "成长", dueDate: Date().addingTimeInterval(3600 * 28), estimatedRounds: 3, accentHex: "#A78BFA"),
                FocusTask(title: "晚间复盘", category: "生活", dueDate: Date().addingTimeInterval(3600 * 10), estimatedRounds: 1, accentHex: "#FF6B6B")
            ]
            save(tasks, key: Keys.tasks)
        }

        if settings.autoGeneratePomodoroPlan && pomodoroPlan.isEmpty {
            generatePomodoroPlanFromSchedule()
        }
    }

    func task(for id: UUID?) -> FocusTask? {
        guard let id else { return nil }
        return tasks.first { $0.id == id }
    }

    var taskCategories: [String] {
        let presetCategories = TaskCategoryPreset.defaults.map(\.title)
        let usedCategories = tasks.map(\.category) + sessions.map(\.category)
        return Self.uniqueCategories(from: presetCategories + usedCategories)
    }

    @discardableResult
    func addTask(
        title: String,
        category: String,
        dueDate: Date?,
        estimatedRounds: Int,
        accentHex: String,
        isEnabled: Bool = true,
        autoStartPomodoro: Bool = false,
        startMode: TaskStartMode = .plannedRounds,
        recurrence: TaskRecurrence = .none,
        externalCalendarIdentifier: String? = nil
    ) -> FocusTask? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return nil }
        let task = FocusTask(
            title: trimmedTitle,
            category: Self.normalizedCategory(category),
            dueDate: dueDate,
            estimatedRounds: max(1, estimatedRounds),
            isEnabled: isEnabled,
            autoStartPomodoro: autoStartPomodoro,
            startMode: startMode,
            recurrence: recurrence,
            externalCalendarIdentifier: externalCalendarIdentifier,
            accentHex: accentHex
        )
        tasks.insert(task, at: 0)
        regeneratePlanIfNeeded()
        return task
    }

    @discardableResult
    func updateTask(
        _ task: FocusTask,
        title: String,
        category: String,
        dueDate: Date?,
        estimatedRounds: Int,
        accentHex: String,
        isEnabled: Bool? = nil,
        autoStartPomodoro: Bool? = nil,
        startMode: TaskStartMode? = nil,
        recurrence: TaskRecurrence? = nil
    ) -> FocusTask? {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, let index = tasks.firstIndex(where: { $0.id == task.id }) else { return nil }
        tasks[index].title = trimmedTitle
        tasks[index].category = Self.normalizedCategory(category)
        tasks[index].dueDate = dueDate
        tasks[index].estimatedRounds = max(1, estimatedRounds)
        tasks[index].accentHex = accentHex
        if let isEnabled { tasks[index].isEnabled = isEnabled }
        if let autoStartPomodoro { tasks[index].autoStartPomodoro = autoStartPomodoro }
        if let startMode { tasks[index].startMode = startMode }
        if let recurrence { tasks[index].recurrence = recurrence }
        syncPlanMetadata(for: tasks[index])
        regeneratePlanIfNeeded()
        return tasks[index]
    }

    @discardableResult
    func toggleTaskDone(_ task: FocusTask) -> FocusTask? {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return nil }
        tasks[index].isDone.toggle()
        setPlanCompletion(for: tasks[index].id, completed: tasks[index].isDone)
        if tasks[index].isDone {
            createNextRecurrenceIfNeeded(from: tasks[index])
        }
        regeneratePlanIfNeeded()
        return tasks[index]
    }

    func deleteTasks(ids: [UUID]) {
        tasks.removeAll { ids.contains($0.id) }
        pomodoroPlan.removeAll { ids.contains($0.taskID) }
        regeneratePlanIfNeeded()
    }

    @discardableResult
    func upsertExternalTask(
        externalCalendarIdentifier: String,
        title: String,
        category: String,
        dueDate: Date?,
        estimatedRounds: Int,
        accentHex: String,
        autoStartPomodoro: Bool
    ) -> FocusTask? {
        if let existing = tasks.first(where: { $0.externalCalendarIdentifier == externalCalendarIdentifier }) {
            return updateTask(
                existing,
                title: title,
                category: category,
                dueDate: dueDate,
                estimatedRounds: estimatedRounds,
                accentHex: accentHex,
                isEnabled: existing.isEnabled,
                autoStartPomodoro: autoStartPomodoro,
                startMode: existing.startMode,
                recurrence: existing.recurrence
            )
        }

        return addTask(
            title: title,
            category: category,
            dueDate: dueDate,
            estimatedRounds: estimatedRounds,
            accentHex: accentHex,
            isEnabled: true,
            autoStartPomodoro: autoStartPomodoro,
            startMode: .plannedRounds,
            recurrence: .none,
            externalCalendarIdentifier: externalCalendarIdentifier
        )
    }

    @discardableResult
    func setTaskEnabled(_ task: FocusTask, enabled: Bool) -> FocusTask? {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return nil }
        tasks[index].isEnabled = enabled
        if !enabled {
            tasks[index].autoStartPomodoro = false
        }
        regeneratePlanIfNeeded()
        return tasks[index]
    }

    @discardableResult
    func markTaskAutoStarted(_ taskID: UUID, at date: Date = Date()) -> FocusTask? {
        guard let index = tasks.firstIndex(where: { $0.id == taskID }) else { return nil }
        tasks[index].lastAutoStartedAt = date
        return tasks[index]
    }

    @discardableResult
    func finishTask(_ taskID: UUID?) -> FocusTask? {
        guard let taskID, let index = tasks.firstIndex(where: { $0.id == taskID }) else { return nil }
        tasks[index].completedRounds = max(tasks[index].completedRounds, tasks[index].estimatedRounds)
        tasks[index].isDone = true
        setPlanCompletion(for: taskID, completed: true)
        createNextRecurrenceIfNeeded(from: tasks[index])
        return tasks[index]
    }

    @discardableResult
    func incrementRound(for taskID: UUID?) -> FocusTask? {
        guard let taskID, let index = tasks.firstIndex(where: { $0.id == taskID }) else { return nil }
        tasks[index].completedRounds += 1
        markNextPlanItemCompleted(for: taskID)
        if tasks[index].completedRounds >= tasks[index].estimatedRounds {
            tasks[index].isDone = true
            setPlanCompletion(for: taskID, completed: true)
            createNextRecurrenceIfNeeded(from: tasks[index])
        }
        return tasks[index]
    }

    func recordSession(_ session: FocusSession) {
        sessions.insert(session, at: 0)
        if sessions.count > 600 {
            sessions.removeLast(sessions.count - 600)
        }
    }

    var todayFocusSeconds: Int {
        focusSeconds(on: Date())
    }

    var weekFocusSeconds: Int {
        weekBuckets().reduce(0) { $0 + $1.focusSeconds }
    }

    var completedFocusRounds: Int {
        sessions.filter { $0.mode == .focus && $0.completed }.count
    }

    func focusSeconds(on date: Date) -> Int {
        sessions
            .filter { $0.mode == .focus && $0.completed && calendar.isDate($0.startedAt, inSameDayAs: date) }
            .reduce(0) { $0 + $1.actualSeconds }
    }

    func weekBuckets(referenceDate: Date = Date()) -> [DailyFocus] {
        let startOfToday = calendar.startOfDay(for: referenceDate)
        return (0..<7).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: startOfToday) else { return nil }
            return DailyFocus(date: day, focusSeconds: focusSeconds(on: day))
        }
    }

    func categoryBreakdown() -> [CategoryFocus] {
        let completedFocus = sessions.filter { $0.mode == .focus && $0.completed }
        let grouped = Dictionary(grouping: completedFocus, by: \.category)
        return grouped.map { category, sessions in
            let seconds = sessions.reduce(0) { $0 + $1.actualSeconds }
            let accent = tasks.first(where: { $0.category == category })?.accentHex ?? "#3DE8C5"
            return CategoryFocus(category: category, seconds: seconds, sessionCount: sessions.count, accentHex: accent)
        }
        .sorted { $0.seconds > $1.seconds }
    }

    func upcomingTasks() -> [FocusTask] {
        tasks
            .filter { !$0.isDone }
            .sorted {
                switch ($0.dueDate, $1.dueDate) {
                case let (left?, right?): return left < right
                case (_?, nil): return true
                case (nil, _?): return false
                case (nil, nil): return $0.createdAt > $1.createdAt
                }
            }
    }

    @discardableResult
    func generatePomodoroPlanFromSchedule(referenceDate: Date = Date()) -> [PomodoroPlanItem] {
        let sortedTasks = upcomingTasks().filter(\.isEnabled)
        let focusSeconds = settings.seconds(for: .focus)
        var cursor = nextWholeMinute(from: referenceDate)
        var generated: [PomodoroPlanItem] = []
        var generatedRoundIndex = completedFocusRounds

        for task in sortedTasks {
            let remainingRounds = task.startMode == .openEnded ? 1 : max(0, task.estimatedRounds - task.completedRounds)
            guard remainingRounds > 0 else { continue }

            for roundOffset in 0..<remainingRounds {
                let start = cursor
                let end = start.addingTimeInterval(TimeInterval(focusSeconds))
                generated.append(
                    PomodoroPlanItem(
                        taskID: task.id,
                        taskTitle: task.title,
                        category: task.category,
                        roundNumber: task.startMode == .openEnded ? 1 : task.completedRounds + roundOffset + 1,
                        scheduledStart: start,
                        scheduledEnd: end,
                        accentHex: task.accentHex
                    )
                )

                if task.startMode == .openEnded {
                    cursor = end
                } else {
                    generatedRoundIndex += 1
                    let breakMode: TimerMode = generatedRoundIndex % max(1, settings.roundsBeforeLongBreak) == 0
                        ? .longBreak
                        : .shortBreak
                    cursor = end.addingTimeInterval(TimeInterval(settings.seconds(for: breakMode)))
                }
            }
        }

        pomodoroPlan = generated
        return generated
    }

    func clearPomodoroPlan() {
        pomodoroPlan.removeAll()
    }

    func markPlanItemStarted(_ item: PomodoroPlanItem) {
        guard let index = pomodoroPlan.firstIndex(where: { $0.id == item.id }) else { return }
        pomodoroPlan[index].scheduledStart = Date()
        pomodoroPlan[index].scheduledEnd = Date().addingTimeInterval(TimeInterval(settings.seconds(for: .focus)))
    }

    func workloadAnalysis(referenceDate: Date = Date()) -> WorkloadAnalysis {
        let pending = tasks.filter { !$0.isDone }
        let overdue = pending.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return dueDate < referenceDate
        }
        let dueToday = pending.filter { task in
            guard let dueDate = task.dueDate else { return false }
            return calendar.isDate(dueDate, inSameDayAs: referenceDate)
        }
        let remainingRounds = pending.reduce(0) { total, task in
            total + max(0, task.estimatedRounds - task.completedRounds)
        }
        let plannedRounds = pomodoroPlan.filter { !$0.isCompleted }.count
        let estimatedFocusSeconds = remainingRounds * settings.seconds(for: .focus)
        let plannedFocusSeconds = plannedRounds * settings.seconds(for: .focus)
        let pressureLevel: String
        let recommendation: String

        if overdue.count > 0 {
            pressureLevel = "高"
            recommendation = "优先处理已逾期任务，并压缩低优先级日程。"
        } else if dueToday.count >= 3 || remainingRounds >= max(1, settings.roundsBeforeLongBreak * 2) {
            pressureLevel = "中"
            recommendation = "建议先生成今日番茄钟计划，按截止时间顺序推进。"
        } else if remainingRounds == 0 {
            pressureLevel = "低"
            recommendation = "当前没有未完成轮次，可安排复盘或休息。"
        } else {
            pressureLevel = "低"
            recommendation = "工作量可控，保持当前节奏即可。"
        }

        return WorkloadAnalysis(
            pendingTasks: pending.count,
            overdueTasks: overdue.count,
            dueTodayTasks: dueToday.count,
            remainingRounds: remainingRounds,
            plannedRounds: plannedRounds,
            estimatedFocusSeconds: estimatedFocusSeconds,
            plannedFocusSeconds: plannedFocusSeconds,
            pressureLevel: pressureLevel,
            recommendation: recommendation
        )
    }

    func autoStartCandidate(referenceDate: Date = Date()) -> FocusTask? {
        upcomingTasks()
            .first { task in
                guard task.isEnabled, task.autoStartPomodoro, let dueDate = task.dueDate else { return false }
                guard dueDate <= referenceDate else { return false }
                if let lastAutoStartedAt = task.lastAutoStartedAt,
                   calendar.isDate(lastAutoStartedAt, inSameDayAs: referenceDate) {
                    return false
                }
                return true
            }
    }

    private func syncPlanMetadata(for task: FocusTask) {
        for index in pomodoroPlan.indices where pomodoroPlan[index].taskID == task.id {
            pomodoroPlan[index].taskTitle = task.title
            pomodoroPlan[index].category = task.category
            pomodoroPlan[index].accentHex = task.accentHex
        }
    }

    private func markNextPlanItemCompleted(for taskID: UUID) {
        guard let index = pomodoroPlan.firstIndex(where: { $0.taskID == taskID && !$0.isCompleted }) else { return }
        pomodoroPlan[index].isCompleted = true
    }

    private func setPlanCompletion(for taskID: UUID, completed: Bool) {
        for index in pomodoroPlan.indices where pomodoroPlan[index].taskID == taskID {
            pomodoroPlan[index].isCompleted = completed
        }
    }

    private func createNextRecurrenceIfNeeded(from task: FocusTask) {
        guard task.recurrence != .none, let dueDate = task.dueDate else { return }
        let component: Calendar.Component
        switch task.recurrence {
        case .none:
            return
        case .daily:
            component = .day
        case .weekly:
            component = .weekOfYear
        case .monthly:
            component = .month
        }
        guard let nextDate = calendar.date(byAdding: component, value: 1, to: dueDate) else { return }
        let alreadyExists = tasks.contains {
            $0.title == task.title
                && $0.recurrence == task.recurrence
                && ($0.dueDate.map { calendar.isDate($0, inSameDayAs: nextDate) } ?? false)
        }
        guard !alreadyExists else { return }

        tasks.insert(
            FocusTask(
                title: task.title,
                category: task.category,
                dueDate: nextDate,
                estimatedRounds: task.estimatedRounds,
                isEnabled: task.isEnabled,
                autoStartPomodoro: task.autoStartPomodoro,
                startMode: task.startMode,
                recurrence: task.recurrence,
                accentHex: task.accentHex
            ),
            at: 0
        )
    }

    private func nextWholeMinute(from date: Date) -> Date {
        let seconds = calendar.component(.second, from: date)
        guard seconds > 0 else { return date }
        return calendar.date(byAdding: .second, value: 60 - seconds, to: date) ?? date
    }

    private func regeneratePlanIfNeeded() {
        guard settings.autoGeneratePomodoroPlan else { return }
        generatePomodoroPlanFromSchedule()
    }

    private static func normalizedCategory(_ category: String) -> String {
        let cleanCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanCategory.isEmpty ? "未分类" : cleanCategory
    }

    private static func uniqueCategories(from categories: [String]) -> [String] {
        var seen: Set<String> = []
        return categories.compactMap { category in
            let cleanCategory = normalizedCategory(category)
            guard !seen.contains(cleanCategory) else { return nil }
            seen.insert(cleanCategory)
            return cleanCategory
        }
    }

    private func save<T: Encodable>(_ value: T, key: String) {
        do {
            let data = try JSONEncoder().encode(value)
            defaults.set(data, forKey: key)
        } catch {
            assertionFailure("Failed to save \(key): \(error)")
        }
    }

    private static func load<T: Decodable>(_ type: T.Type, key: String, defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

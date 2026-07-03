import Foundation
import SwiftUI

enum TimerMode: String, CaseIterable, Codable, Identifiable {
    case focus
    case shortBreak
    case longBreak

    var id: String { rawValue }

    var title: String {
        switch self {
        case .focus: return "专注"
        case .shortBreak: return "短休"
        case .longBreak: return "长休"
        }
    }

    var notificationTitle: String {
        switch self {
        case .focus: return "专注完成"
        case .shortBreak: return "短休结束"
        case .longBreak: return "长休结束"
        }
    }

    var symbolName: String {
        switch self {
        case .focus: return "scope"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak: return "sparkles"
        }
    }

    var tintHex: String {
        switch self {
        case .focus: return "#3DE8C5"
        case .shortBreak: return "#FFB84D"
        case .longBreak: return "#A78BFA"
        }
    }
}

enum AppThemeMode: String, CaseIterable, Codable, Identifiable {
    case dark
    case light

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dark: return "暗色"
        case .light: return "亮色"
        }
    }

    var symbolName: String {
        switch self {
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        }
    }
}

enum CalendarDisplayMode: String, CaseIterable, Codable, Identifiable {
    case day
    case week
    case month

    var id: String { rawValue }

    var title: String {
        switch self {
        case .day: return "日"
        case .week: return "周"
        case .month: return "月"
        }
    }
}

enum ReportRange: String, CaseIterable, Codable, Identifiable {
    case day
    case week
    case month

    var id: String { rawValue }

    var title: String {
        switch self {
        case .day: return "日"
        case .week: return "周"
        case .month: return "月"
        }
    }
}

enum TaskStartMode: String, CaseIterable, Codable, Identifiable {
    case plannedRounds
    case openEnded

    var id: String { rawValue }

    var title: String {
        switch self {
        case .plannedRounds: return "按轮次"
        case .openEnded: return "只设开始"
        }
    }
}

enum TaskRecurrence: String, CaseIterable, Codable, Identifiable {
    case none
    case daily
    case weekly
    case monthly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .none: return "不循环"
        case .daily: return "每天"
        case .weekly: return "每周"
        case .monthly: return "每月"
        }
    }
}

enum CompletionSound: String, CaseIterable, Codable, Identifiable {
    case chime
    case bell
    case ripple
    case softPulse

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chime: return "清亮"
        case .bell: return "铃音"
        case .ripple: return "水波"
        case .softPulse: return "柔和"
        }
    }

    var isPro: Bool {
        self != .chime
    }
}

struct TaskCategoryPreset: Identifiable, Hashable {
    var id: String { title }

    let title: String
    let accentHex: String
    let symbolName: String

    static let defaults: [TaskCategoryPreset] = [
        TaskCategoryPreset(title: "工作", accentHex: "#3DE8C5", symbolName: "briefcase.fill"),
        TaskCategoryPreset(title: "成长", accentHex: "#A78BFA", symbolName: "book.fill"),
        TaskCategoryPreset(title: "生活", accentHex: "#FF6B6B", symbolName: "house.fill"),
        TaskCategoryPreset(title: "工程", accentHex: "#54A0FF", symbolName: "hammer.fill"),
        TaskCategoryPreset(title: "复盘", accentHex: "#FFB84D", symbolName: "checklist.checked")
    ]

    static func matching(_ category: String) -> TaskCategoryPreset? {
        defaults.first { $0.title == category }
    }
}

struct TimerSettings: Codable, Equatable {
    var focusMinutes: Int = 25
    var shortBreakMinutes: Int = 5
    var longBreakMinutes: Int = 15
    var roundsBeforeLongBreak: Int = 4
    var dailyGoalMinutes: Int = 120
    var notificationsEnabled: Bool = true
    var liveActivityEnabled: Bool = true
    var soundEnabled: Bool = true
    var soundVolume: Double = 0.8
    var completionSound: CompletionSound = .chime
    var vibrationEnabled: Bool = true
    var keepScreenAwake: Bool = false
    var taskDueRemindersEnabled: Bool = true
    var autoGeneratePomodoroPlan: Bool = true
    var autoStartBreaks: Bool = true
    var autoStartFocus: Bool = true
    var appThemeMode: AppThemeMode = .dark

    private enum CodingKeys: String, CodingKey {
        case focusMinutes
        case shortBreakMinutes
        case longBreakMinutes
        case roundsBeforeLongBreak
        case dailyGoalMinutes
        case notificationsEnabled
        case liveActivityEnabled
        case soundEnabled
        case soundVolume
        case completionSound
        case vibrationEnabled
        case keepScreenAwake
        case taskDueRemindersEnabled
        case autoGeneratePomodoroPlan
        case autoStartBreaks
        case autoStartFocus
        case appThemeMode
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        focusMinutes = try container.decodeIfPresent(Int.self, forKey: .focusMinutes) ?? 25
        shortBreakMinutes = try container.decodeIfPresent(Int.self, forKey: .shortBreakMinutes) ?? 5
        longBreakMinutes = try container.decodeIfPresent(Int.self, forKey: .longBreakMinutes) ?? 15
        roundsBeforeLongBreak = try container.decodeIfPresent(Int.self, forKey: .roundsBeforeLongBreak) ?? 4
        dailyGoalMinutes = try container.decodeIfPresent(Int.self, forKey: .dailyGoalMinutes) ?? 120
        notificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .notificationsEnabled) ?? true
        liveActivityEnabled = try container.decodeIfPresent(Bool.self, forKey: .liveActivityEnabled) ?? true
        soundEnabled = try container.decodeIfPresent(Bool.self, forKey: .soundEnabled) ?? true
        soundVolume = min(1, max(0, try container.decodeIfPresent(Double.self, forKey: .soundVolume) ?? 0.8))
        completionSound = try container.decodeIfPresent(CompletionSound.self, forKey: .completionSound) ?? .chime
        vibrationEnabled = try container.decodeIfPresent(Bool.self, forKey: .vibrationEnabled) ?? true
        keepScreenAwake = try container.decodeIfPresent(Bool.self, forKey: .keepScreenAwake) ?? false
        taskDueRemindersEnabled = try container.decodeIfPresent(Bool.self, forKey: .taskDueRemindersEnabled) ?? true
        autoGeneratePomodoroPlan = try container.decodeIfPresent(Bool.self, forKey: .autoGeneratePomodoroPlan) ?? true
        autoStartBreaks = try container.decodeIfPresent(Bool.self, forKey: .autoStartBreaks) ?? true
        autoStartFocus = try container.decodeIfPresent(Bool.self, forKey: .autoStartFocus) ?? true
        appThemeMode = try container.decodeIfPresent(AppThemeMode.self, forKey: .appThemeMode) ?? .dark
    }

    func seconds(for mode: TimerMode) -> Int {
        switch mode {
        case .focus: return focusMinutes * 60
        case .shortBreak: return shortBreakMinutes * 60
        case .longBreak: return longBreakMinutes * 60
        }
    }

    var dailyGoalSeconds: Int {
        dailyGoalMinutes * 60
    }
}

struct FocusTask: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var title: String
    var category: String
    var dueDate: Date?
    var estimatedRounds: Int
    var completedRounds: Int = 0
    var isDone: Bool = false
    var isEnabled: Bool = true
    var autoStartPomodoro: Bool = false
    var startMode: TaskStartMode = .plannedRounds
    var recurrence: TaskRecurrence = .none
    var externalCalendarIdentifier: String?
    var lastAutoStartedAt: Date?
    var accentHex: String = "#3DE8C5"
    var createdAt: Date = Date()

    var progress: Double {
        guard estimatedRounds > 0 else { return isDone ? 1 : 0 }
        return min(1, Double(completedRounds) / Double(estimatedRounds))
    }

    var remainingRounds: Int {
        max(0, estimatedRounds - completedRounds)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case category
        case dueDate
        case estimatedRounds
        case completedRounds
        case isDone
        case isEnabled
        case autoStartPomodoro
        case startMode
        case recurrence
        case externalCalendarIdentifier
        case lastAutoStartedAt
        case accentHex
        case createdAt
    }

    init(
        id: UUID = UUID(),
        title: String,
        category: String,
        dueDate: Date?,
        estimatedRounds: Int,
        completedRounds: Int = 0,
        isDone: Bool = false,
        isEnabled: Bool = true,
        autoStartPomodoro: Bool = false,
        startMode: TaskStartMode = .plannedRounds,
        recurrence: TaskRecurrence = .none,
        externalCalendarIdentifier: String? = nil,
        lastAutoStartedAt: Date? = nil,
        accentHex: String = "#3DE8C5",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.dueDate = dueDate
        self.estimatedRounds = estimatedRounds
        self.completedRounds = completedRounds
        self.isDone = isDone
        self.isEnabled = isEnabled
        self.autoStartPomodoro = autoStartPomodoro
        self.startMode = startMode
        self.recurrence = recurrence
        self.externalCalendarIdentifier = externalCalendarIdentifier
        self.lastAutoStartedAt = lastAutoStartedAt
        self.accentHex = accentHex
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? "未分类"
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        estimatedRounds = try container.decodeIfPresent(Int.self, forKey: .estimatedRounds) ?? 1
        completedRounds = try container.decodeIfPresent(Int.self, forKey: .completedRounds) ?? 0
        isDone = try container.decodeIfPresent(Bool.self, forKey: .isDone) ?? false
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        autoStartPomodoro = try container.decodeIfPresent(Bool.self, forKey: .autoStartPomodoro) ?? false
        startMode = try container.decodeIfPresent(TaskStartMode.self, forKey: .startMode) ?? .plannedRounds
        recurrence = try container.decodeIfPresent(TaskRecurrence.self, forKey: .recurrence) ?? .none
        externalCalendarIdentifier = try container.decodeIfPresent(String.self, forKey: .externalCalendarIdentifier)
        lastAutoStartedAt = try container.decodeIfPresent(Date.self, forKey: .lastAutoStartedAt)
        accentHex = try container.decodeIfPresent(String.self, forKey: .accentHex) ?? "#3DE8C5"
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
    }
}

struct FocusSession: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var taskID: UUID?
    var taskTitle: String
    var category: String
    var mode: TimerMode
    var startedAt: Date
    var endedAt: Date
    var plannedSeconds: Int
    var actualSeconds: Int
    var completed: Bool
}

struct ActiveTimerSnapshot: Codable, Equatable {
    var sessionID: UUID
    var mode: TimerMode
    var taskID: UUID?
    var taskTitle: String
    var category: String
    var startedAt: Date
    var endAt: Date
    var plannedSeconds: Int
    var remainingWhenPaused: Int
    var isPaused: Bool
    var roundIndex: Int
    var tintHex: String
}

struct PomodoroPlanItem: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var taskID: UUID
    var taskTitle: String
    var category: String
    var roundNumber: Int
    var scheduledStart: Date
    var scheduledEnd: Date
    var accentHex: String
    var isCompleted: Bool = false
    var generatedAt: Date = Date()

    var timeRangeText: String {
        "\(scheduledStart.shortTimeText)-\(scheduledEnd.shortTimeText)"
    }
}

struct DailyFocus: Identifiable {
    var id: Date { date }
    var date: Date
    var focusSeconds: Int

    var weekdayLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}

struct CategoryFocus: Identifiable {
    var id: String { category }
    var category: String
    var seconds: Int
    var accentHex: String
}

struct WorkloadAnalysis: Equatable {
    var pendingTasks: Int
    var overdueTasks: Int
    var dueTodayTasks: Int
    var remainingRounds: Int
    var plannedRounds: Int
    var estimatedFocusSeconds: Int
    var plannedFocusSeconds: Int
    var pressureLevel: String
    var recommendation: String

    var planCoverage: Double {
        guard remainingRounds > 0 else { return 1 }
        return min(1, Double(plannedRounds) / Double(remainingRounds))
    }
}

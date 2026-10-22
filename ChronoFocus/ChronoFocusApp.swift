import SwiftUI

@main
struct ChronoFocusApp: App {
    @StateObject private var store: FocusStore
    @StateObject private var notifications: NotificationService
    @StateObject private var premium: PremiumAccessService
    @StateObject private var calendarSync: CalendarSyncService
    @StateObject private var engine: TimerEngine

    @MainActor
    init() {
        let store = Self.makeStore()
        let notifications = NotificationService()
        let premium = PremiumAccessService()
        let calendarSync = CalendarSyncService()
        let liveActivities = LiveActivityService()
        let engine = TimerEngine(store: store, notifications: notifications, liveActivities: liveActivities)
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-testing"),
           ProcessInfo.processInfo.arguments.contains("--ui-fixture=long") {
            engine.selectTask(store.startableTasks().first)
        }
        #endif
        _store = StateObject(wrappedValue: store)
        _notifications = StateObject(wrappedValue: notifications)
        _premium = StateObject(wrappedValue: premium)
        _calendarSync = StateObject(wrappedValue: calendarSync)
        _engine = StateObject(wrappedValue: engine)
    }

    @MainActor
    private static func makeStore() -> FocusStore {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--ui-testing") {
            let suite = "ChronoFocusUITests"
            guard let defaults = UserDefaults(suiteName: suite) else {
                preconditionFailure("Could not create isolated UI test defaults")
            }
            defaults.removePersistentDomain(forName: suite)
            let store = FocusStore(defaults: defaults)
            store.settings.notificationsEnabled = false
            store.settings.taskDueRemindersEnabled = false
            store.settings.liveActivityEnabled = false
            store.settings.soundEnabled = false
            store.settings.vibrationEnabled = false
            store.settings.autoStartFocus = false
            store.settings.autoStartBreaks = false
            store.settings.autoGeneratePomodoroPlan = false
            if arguments.contains("--ui-fixture=tasks") || arguments.contains("--ui-fixture=long") {
                let title = arguments.contains("--ui-fixture=long")
                    ? "整理跨团队产品体验评审中的问题，完成下一阶段的可访问性与发布准备"
                    : "云端分类验收任务"
                _ = store.addTask(title: title, category: "产品", dueDate: nil, estimatedRounds: 2, accentHex: "#3DE8C5")
            }
            return store
        }
        #endif
        return FocusStore()
    }

    var body: some Scene {
        WindowGroup {
            DashboardView()
                .environmentObject(store)
                .environmentObject(engine)
                .environmentObject(notifications)
                .environmentObject(premium)
                .environmentObject(calendarSync)
                .preferredColorScheme(store.settings.appThemeMode == .light ? .light : .dark)
        }
    }
}

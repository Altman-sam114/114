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
            if arguments.contains("--ui-fixture=editor-active") {
                _ = store.addTask(title: "计时保护验收任务", category: "产品", dueDate: Date(), estimatedRounds: 2, accentHex: "#3DE8C5")
            } else if arguments.contains("--ui-fixture=management") {
                let dueDate = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())
                _ = store.addTask(title: "准备发布检查", category: "产品", dueDate: dueDate, estimatedRounds: 2, accentHex: "#3DE8C5")
                _ = store.addTask(title: "保留的日常安排", category: "生活", dueDate: dueDate, estimatedRounds: 1, accentHex: "#FF6B6B")
                if let task = store.addTask(title: "已完成的界面评审", category: "产品", dueDate: dueDate, estimatedRounds: 1, accentHex: "#3DE8C5") {
                    _ = store.finishTask(task.id)
                }
            } else if arguments.contains("--ui-fixture=schedule-long") {
                let dueDate = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())
                _ = store.addTask(title: "整理产品体验评审与下一阶段任务", category: "跨团队产品体验与可访问性改进", dueDate: dueDate, estimatedRounds: 2, accentHex: "#3DE8C5")
            } else if arguments.contains("--ui-fixture=tasks") || arguments.contains("--ui-fixture=long") {
                let title = arguments.contains("--ui-fixture=long")
                    ? "整理跨团队产品体验评审中的问题，完成下一阶段的可访问性与发布准备"
                    : "云端分类验收任务"
                let dueDate = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())
                _ = store.addTask(title: title, category: "产品", dueDate: dueDate, estimatedRounds: 2, accentHex: "#3DE8C5")
            }
            return store
        }
        #endif
        return FocusStore()
    }

    var body: some Scene {
        WindowGroup {
            rootView
                .environmentObject(store)
                .environmentObject(engine)
                .environmentObject(notifications)
                .environmentObject(premium)
                .environmentObject(calendarSync)
                .preferredColorScheme(store.settings.appThemeMode == .light ? .light : .dark)
        }
    }

    @ViewBuilder
    private var rootView: some View {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-testing"),
           ProcessInfo.processInfo.arguments.contains("--ui-fixture=editor-active") {
            EditingProtectionUITestView()
        } else if ProcessInfo.processInfo.arguments.contains("--ui-testing"),
           ProcessInfo.processInfo.arguments.contains("--ui-large-type") {
            DashboardView().dynamicTypeSize(.accessibility5)
        } else {
            DashboardView()
        }
        #else
        DashboardView()
        #endif
    }
}

#if DEBUG
private struct EditingProtectionUITestView: View {
    @EnvironmentObject private var store: FocusStore
    @EnvironmentObject private var engine: TimerEngine
    @State private var showsEditor = true

    var body: some View {
        DashboardView()
            .sheet(isPresented: $showsEditor) {
                if let task = store.tasks.first {
                    TaskEditorView(task: task, initialDueDate: task.dueDate ?? Date())
                        .task {
                            // Enter the protected state after the real editor is presented.
                            engine.selectTask(task)
                            engine.start()
                        }
                }
            }
    }
}
#endif

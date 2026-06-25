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
        let store = FocusStore()
        let notifications = NotificationService()
        let premium = PremiumAccessService()
        let calendarSync = CalendarSyncService()
        let liveActivities = LiveActivityService()
        _store = StateObject(wrappedValue: store)
        _notifications = StateObject(wrappedValue: notifications)
        _premium = StateObject(wrappedValue: premium)
        _calendarSync = StateObject(wrappedValue: calendarSync)
        _engine = StateObject(wrappedValue: TimerEngine(store: store, notifications: notifications, liveActivities: liveActivities))
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

import AppKit
import SwiftUI

@main
struct ChronoFocusMacApp: App {
    @NSApplicationDelegateAdaptor(MacAppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
final class MacAppDelegate: NSObject, NSApplicationDelegate {
    private var store: FocusStore?
    private var engine: TimerEngine?
    private var notifications: MacNotificationService?
    private var premium: MacPremiumAccessService?
    private var calendarSync: MacCalendarSyncService?
    private var statusBarController: MacStatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let store = FocusStore()
        let notifications = MacNotificationService()
        let premium = MacPremiumAccessService()
        let calendarSync = MacCalendarSyncService()
        let liveActivities = MacLiveActivityService()
        let engine = TimerEngine(store: store, notifications: notifications, liveActivities: liveActivities)

        self.store = store
        self.notifications = notifications
        self.premium = premium
        self.calendarSync = calendarSync
        self.engine = engine
        statusBarController = MacStatusBarController(
            store: store,
            engine: engine,
            notifications: notifications,
            premium: premium,
            calendarSync: calendarSync
        )

        Task { await notifications.refreshAuthorizationStatus() }
        engine.checkScheduledAutoStart()

        if ProcessInfo.processInfo.environment["CHRONOFOCUS_MAC_OPEN_DETAILS"] == "1" {
            Task { @MainActor in
                statusBarController?.showDetails()
            }
        }

        if ProcessInfo.processInfo.environment["CHRONOFOCUS_MAC_OPEN_POPOVER"] == "1" {
            Task { @MainActor in
                statusBarController?.showMiniTimerForValidation()
            }
        }
    }
}

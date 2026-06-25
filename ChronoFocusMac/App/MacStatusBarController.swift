import AppKit
import SwiftUI

@MainActor
final class MacStatusBarController: NSObject, ObservableObject {
    private let store: FocusStore
    private let engine: TimerEngine
    private let notifications: MacNotificationService
    private let premium: MacPremiumAccessService
    private let calendarSync: MacCalendarSyncService
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var popover: NSPopover?
    private var detailWindow: NSWindow?
    private var ticker: Timer?

    init(
        store: FocusStore,
        engine: TimerEngine,
        notifications: MacNotificationService,
        premium: MacPremiumAccessService,
        calendarSync: MacCalendarSyncService
    ) {
        self.store = store
        self.engine = engine
        self.notifications = notifications
        self.premium = premium
        self.calendarSync = calendarSync
        super.init()
        configureStatusItem()
        startStatusTicker()
    }

    func showDetails() {
        if let detailWindow {
            detailWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let rootView = MacDetailView()
            .environmentObject(store)
            .environmentObject(engine)
            .environmentObject(notifications)
            .environmentObject(premium)
            .environmentObject(calendarSync)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1100, height: 720),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "ChronoFocus"
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: 920, height: 620)
        window.center()
        window.contentView = NSHostingView(rootView: rootView)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        detailWindow = window
    }

    func showMiniTimerForValidation() {
        guard let button = statusItem.button else { return }
        showPopover(relativeTo: button)
    }

    private func configureStatusItem() {
        statusItem.button?.target = self
        statusItem.button?.action = #selector(togglePopover(_:))
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        updateStatusTitle()
    }

    private func startStatusTicker() {
        ticker?.invalidate()
        ticker = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateStatusTitle()
            }
        }
        if let ticker {
            RunLoop.main.add(ticker, forMode: .common)
        }
    }

    private func updateStatusTitle() {
        statusItem.button?.title = engine.formattedRemaining
        statusItem.button?.font = .monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
        statusItem.button?.toolTip = "\(engine.mode.title) · \(engine.currentTaskTitle)"
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        if let event = NSApp.currentEvent, event.type == .rightMouseUp {
            showContextMenu()
            return
        }

        if popover?.isShown == true {
            popover?.performClose(sender)
        } else {
            showPopover(relativeTo: sender)
        }
    }

    private func showPopover(relativeTo button: NSStatusBarButton) {
        let popover = NSPopover()
        popover.behavior = .transient
        popover.animates = true
        popover.contentSize = NSSize(width: 430, height: 500)
        popover.contentViewController = NSHostingController(
            rootView: MacMiniTimerView(openDetails: { [weak self] in
                self?.popover?.performClose(nil)
                self?.showDetails()
            })
            .environmentObject(store)
            .environmentObject(engine)
            .environmentObject(notifications)
            .environmentObject(premium)
        )
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        self.popover = popover
    }

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: engine.isRunning ? "暂停/继续" : "开始", action: #selector(toggleTimer), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "打开详细界面", action: #selector(openDetailsFromMenu), keyEquivalent: ""))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "退出 ChronoFocus", action: #selector(quit), keyEquivalent: "q"))
        menu.items.forEach { $0.target = self }
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func toggleTimer() {
        if !engine.isRunning {
            engine.start()
        } else if engine.isPaused {
            engine.resume()
        } else {
            engine.pause()
        }
    }

    @objc private func openDetailsFromMenu() {
        showDetails()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

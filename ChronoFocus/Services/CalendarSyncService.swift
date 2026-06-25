import Combine
import EventKit
import Foundation

@MainActor
final class CalendarSyncService: ObservableObject {
    @Published private(set) var authorizationStatus: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)
    @Published private(set) var statusText = "Pro 可同步 iPhone 日历，Siri 创建的日程也会在同步后加入待办。"
    @Published private(set) var isSyncing = false

    private let eventStore = EKEventStore()

    func syncUpcomingEvents(into store: FocusStore) async {
        isSyncing = true
        defer { isSyncing = false }

        do {
            guard try await requestAccessIfNeeded() else {
                statusText = "未获得日历访问权限。"
                return
            }

            let startDate = Calendar.current.startOfDay(for: Date())
            let endDate = Calendar.current.date(byAdding: .day, value: 45, to: startDate) ?? startDate
            let predicate = eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
            let events = eventStore.events(matching: predicate)
                .filter { !$0.isAllDay }
                .sorted { $0.startDate < $1.startDate }

            var importedCount = 0
            for event in events {
                let duration = max(1, Int(event.endDate.timeIntervalSince(event.startDate)))
                let rounds = max(1, Int(ceil(Double(duration) / Double(max(1, store.settings.seconds(for: .focus))))))
                store.upsertExternalTask(
                    externalCalendarIdentifier: event.eventIdentifier,
                    title: event.title,
                    category: event.calendar.title,
                    dueDate: event.startDate,
                    estimatedRounds: rounds,
                    accentHex: "#54A0FF",
                    autoStartPomodoro: false
                )
                importedCount += 1
            }

            statusText = importedCount == 0
                ? "未发现可同步的近期日程。"
                : "已同步 \(importedCount) 条 iPhone 日历日程。"
        } catch {
            statusText = "日历同步失败，请稍后重试。"
        }
    }

    private func requestAccessIfNeeded() async throws -> Bool {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        switch authorizationStatus {
        case .fullAccess, .writeOnly, .authorized:
            return true
        case .notDetermined:
            let granted: Bool
            if #available(iOS 17.0, *) {
                granted = try await eventStore.requestFullAccessToEvents()
            } else {
                granted = try await withCheckedThrowingContinuation { continuation in
                    eventStore.requestAccess(to: .event) { granted, error in
                        if let error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume(returning: granted)
                        }
                    }
                }
            }
            authorizationStatus = EKEventStore.authorizationStatus(for: .event)
            return granted
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
}

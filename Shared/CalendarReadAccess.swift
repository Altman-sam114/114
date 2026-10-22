import Foundation

enum CalendarReadAuthorization: Equatable {
    case fullAccess
    case writeOnly
    case notDetermined
    case denied
    case restricted
    case unknown
}

@MainActor
enum CalendarReadAccessGate {
    static func ensureAccess(
        currentStatus: () -> CalendarReadAuthorization,
        requestFullAccess: () async throws -> Bool
    ) async throws -> Bool {
        switch currentStatus() {
        case .fullAccess:
            return true
        case .notDetermined, .writeOnly:
            let granted = try await requestFullAccess()
            let refreshedStatus = currentStatus()
            return granted && refreshedStatus == .fullAccess
        case .denied, .restricted, .unknown:
            return false
        }
    }
}

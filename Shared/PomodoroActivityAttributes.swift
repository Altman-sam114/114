import ActivityKit
import Foundation

public struct PomodoroActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var modeName: String
        public var taskTitle: String
        public var endDate: Date
        public var tintHex: String
        public var isPaused: Bool
        public var remainingSeconds: Int

        public init(
            modeName: String,
            taskTitle: String,
            endDate: Date,
            tintHex: String,
            isPaused: Bool,
            remainingSeconds: Int
        ) {
            self.modeName = modeName
            self.taskTitle = taskTitle
            self.endDate = endDate
            self.tintHex = tintHex
            self.isPaused = isPaused
            self.remainingSeconds = remainingSeconds
        }
    }

    public var sessionID: String
    public var startedAt: Date

    public init(sessionID: String, startedAt: Date) {
        self.sessionID = sessionID
        self.startedAt = startedAt
    }
}

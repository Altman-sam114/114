import AppKit
import AVFoundation
import Foundation
import UserNotifications

@MainActor
final class MacNotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate, TimerNotificationServicing {
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private let center: UNUserNotificationCenter?
    private let taskReminderPrefix = "mac-task-due-"
    private var alertPlayer: AVAudioPlayer?

    init(disabledForSnapshots: Bool = false) {
        center = disabledForSnapshots ? nil : UNUserNotificationCenter.current()
        super.init()
        center?.delegate = self
        if !disabledForSnapshots {
            Task { await refreshAuthorizationStatus() }
        }
    }

    func refreshAuthorizationStatus() async {
        guard let center else { return }
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        guard let center else { return false }
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            await refreshAuthorizationStatus()
            return granted
        } catch {
            await refreshAuthorizationStatus()
            return false
        }
    }

    func openSystemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") else { return }
        NSWorkspace.shared.open(url)
    }

    func scheduleCompletion(
        identifier: String,
        mode: TimerMode,
        taskTitle: String,
        nextMode: TimerMode,
        endDate: Date,
        soundEnabled: Bool
    ) async {
        guard let center else { return }
        guard await canScheduleUserNotifications() else { return }
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = mode.notificationTitle
        content.body = mode == .focus
            ? "\(taskTitle) 已完成一轮。下一步：\(nextMode.title)。"
            : "\(mode.title)结束。下一步：\(nextMode.title)。"
        content.sound = soundEnabled ? .default : nil

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, endDate.timeIntervalSinceNow), repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await center.add(request)
            await refreshAuthorizationStatus()
        } catch {
            await refreshAuthorizationStatus()
        }
    }

    func scheduleTaskReminder(for task: FocusTask, soundEnabled: Bool) async {
        guard let center else { return }
        let identifier = taskReminderIdentifier(for: task.id)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard !task.isDone, let dueDate = task.dueDate, dueDate > Date() else { return }
        guard await canScheduleUserNotifications() else { return }

        let content = UNMutableNotificationContent()
        content.title = "日程到期"
        content.body = "\(task.title) 即将到期。预计 \(task.estimatedRounds) 轮 · \(task.category)"
        content.sound = soundEnabled ? .default : nil

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: dueDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        do {
            try await center.add(request)
            await refreshAuthorizationStatus()
        } catch {
            await refreshAuthorizationStatus()
        }
    }

    func cancel(identifier: String?) {
        guard let center else { return }
        guard let identifier else { return }
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func cancelTaskReminder(taskID: UUID) {
        guard let center else { return }
        center.removePendingNotificationRequests(withIdentifiers: [taskReminderIdentifier(for: taskID)])
    }

    func syncTaskDueReminders(for tasks: [FocusTask], enabled: Bool, soundEnabled: Bool) async {
        guard enabled else {
            await cancelAllTaskReminders()
            return
        }

        for task in tasks {
            if task.isDone || task.dueDate == nil {
                cancelTaskReminder(taskID: task.id)
            } else {
                await scheduleTaskReminder(for: task, soundEnabled: soundEnabled)
            }
        }
    }

    func playCompletionAlert(soundVolume: Double, vibrationEnabled: Bool) {
        if soundVolume > 0 {
            playGeneratedTone(volume: Float(min(1, max(0, soundVolume))))
        }
        if vibrationEnabled {
            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
        }
    }

    var shouldShowAuthorizationAction: Bool {
        authorizationStatus == .notDetermined || authorizationStatus == .denied
    }

    var authorizationActionTitle: String {
        authorizationStatus == .denied ? "去设置" : "授权"
    }

    private func playGeneratedTone(volume: Float) {
        do {
            let data = makeToneWavData()
            let player = try AVAudioPlayer(data: data)
            player.volume = volume
            player.prepareToPlay()
            player.play()
            alertPlayer = player
        } catch {
            NSSound.beep()
        }
    }

    private func makeToneWavData() -> Data {
        let sampleRate = 44_100
        let duration = 0.55
        let sampleCount = Int(Double(sampleRate) * duration)
        let dataByteCount = sampleCount * MemoryLayout<Int16>.size
        var data = Data()

        func appendString(_ value: String) {
            data.append(value.data(using: .ascii) ?? Data())
        }

        func appendUInt32(_ value: UInt32) {
            var littleEndian = value.littleEndian
            data.append(Data(bytes: &littleEndian, count: MemoryLayout<UInt32>.size))
        }

        func appendUInt16(_ value: UInt16) {
            var littleEndian = value.littleEndian
            data.append(Data(bytes: &littleEndian, count: MemoryLayout<UInt16>.size))
        }

        appendString("RIFF")
        appendUInt32(UInt32(36 + dataByteCount))
        appendString("WAVE")
        appendString("fmt ")
        appendUInt32(16)
        appendUInt16(1)
        appendUInt16(1)
        appendUInt32(UInt32(sampleRate))
        appendUInt32(UInt32(sampleRate * MemoryLayout<Int16>.size))
        appendUInt16(UInt16(MemoryLayout<Int16>.size))
        appendUInt16(16)
        appendString("data")
        appendUInt32(UInt32(dataByteCount))

        for sampleIndex in 0..<sampleCount {
            let progress = Double(sampleIndex) / Double(sampleCount)
            let envelope = min(1, min(progress * 12, (1 - progress) * 8))
            let wave = sin(2 * Double.pi * 880 * Double(sampleIndex) / Double(sampleRate))
            var sample = Int16(wave * envelope * 22_000).littleEndian
            data.append(Data(bytes: &sample, count: MemoryLayout<Int16>.size))
        }

        return data
    }

    private func canScheduleUserNotifications() async -> Bool {
        guard let center else { return false }
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            await refreshAuthorizationStatus()
            return true
        case .notDetermined:
            return await requestAuthorization()
        case .denied:
            await refreshAuthorizationStatus()
            return false
        @unknown default:
            await refreshAuthorizationStatus()
            return false
        }
    }

    private func taskReminderIdentifier(for taskID: UUID) -> String {
        "\(taskReminderPrefix)\(taskID.uuidString)"
    }

    private func cancelAllTaskReminders() async {
        guard let center else { return }
        let requests = await center.pendingNotificationRequests()
        let identifiers = requests
            .map(\.identifier)
            .filter { $0.hasPrefix(taskReminderPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}

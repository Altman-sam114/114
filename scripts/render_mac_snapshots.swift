import AppKit
import Foundation
import SwiftUI

@main
struct MacSnapshotRenderer {
    static func main() async throws {
        try await MainActor.run {
            try renderSnapshots()
        }
    }

    @MainActor
    private static func renderSnapshots() throws {
        let outputDirectory = URL(fileURLWithPath: "/tmp/chronofocus-mac-snapshots", isDirectory: true)
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

        let suiteName = "ChronoFocusMacSnapshot-\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw SnapshotError("Could not create snapshot UserDefaults suite")
        }
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let store = FocusStore(defaults: defaults)
        seedSnapshotData(into: store)

        let notifications = MacNotificationService(disabledForSnapshots: true)
        let liveActivities = MacLiveActivityService()
        let engine = TimerEngine(store: store, notifications: notifications, liveActivities: liveActivities)
        let premium = MacPremiumAccessService(loadProductsOnInit: false, isProUnlockedForSnapshots: true)
        let calendarSync = MacCalendarSyncService()

        let miniView = MacMiniTimerView(openDetails: {})
            .environmentObject(store)
            .environmentObject(engine)
            .environmentObject(notifications)
            .environmentObject(premium)
            .environment(\.macSnapshotRendering, true)
            .environment(\.macSnapshotShowsQuickPanel, true)
            .frame(width: 560, height: 500)

        let miniURL = outputDirectory.appendingPathComponent("mini-timer.png")
        try render(miniView, to: miniURL)
        try assertNonBlankImage(at: miniURL)
        try assertNoMissingControlPlaceholders(at: miniURL)
        var snapshotMetadata = [try metadata(for: miniURL)]

        print("Mac snapshots rendered:")
        print(miniURL.path)

        let detailPages: [(fileName: String, section: SnapshotDetailSection, content: AnyView)] = [
            ("detail-timer.png", .timer, AnyView(MacTimerDetailView())),
            ("detail-schedule.png", .schedule, AnyView(MacScheduleDetailView())),
            ("detail-analytics.png", .analytics, AnyView(MacAnalyticsDetailView())),
            ("detail-settings.png", .settings, AnyView(MacSettingsDetailView()))
        ]

        for detailPage in detailPages {
            let detailURL = outputDirectory.appendingPathComponent(detailPage.fileName)
            let detailView = SnapshotDetailView(
                selectedSection: detailPage.section,
                content: detailPage.content
            )
            .environmentObject(store)
            .environmentObject(engine)
            .environmentObject(notifications)
            .environmentObject(premium)
            .environmentObject(calendarSync)
            .environment(\.macSnapshotRendering, true)
            .frame(width: 1100, height: 720)

            try render(detailView, to: detailURL)
            try assertNonBlankImage(at: detailURL)
            try assertForegroundContent(at: detailURL, minimumXRatio: 0.22)
            try assertNoMissingControlPlaceholders(at: detailURL)
            snapshotMetadata.append(try metadata(for: detailURL))
            print(detailURL.path)
        }

        let manifestURL = outputDirectory.appendingPathComponent("manifest.json")
        try writeManifest(snapshotMetadata, to: manifestURL)
        try assertSnapshotManifest(at: manifestURL)
        print(manifestURL.path)
    }

    @MainActor
    private static func seedSnapshotData(into store: FocusStore) {
        store.tasks.removeAll()
        store.sessions.removeAll()
        store.pomodoroPlan.removeAll()
        store.activeTimer = nil
        store.settings.focusMinutes = 25
        store.settings.shortBreakMinutes = 5
        store.settings.longBreakMinutes = 15
        store.settings.dailyGoalMinutes = 120

        let now = Date()
        _ = store.addTask(
            title: "整理 Mac 版番茄钟界面",
            category: "产品",
            dueDate: now.addingTimeInterval(3600),
            estimatedRounds: 3,
            accentHex: "#3DE8C5",
            isEnabled: true,
            autoStartPomodoro: true
        )
        _ = store.addTask(
            title: "接入日历同步验收",
            category: "工程",
            dueDate: now.addingTimeInterval(7200),
            estimatedRounds: 2,
            accentHex: "#54A0FF"
        )
        _ = store.addTask(
            title: "统计报表视觉检查",
            category: "复盘",
            dueDate: now.addingTimeInterval(10800),
            estimatedRounds: 1,
            accentHex: "#A78BFA"
        )

        for offset in 0..<5 {
            let start = Calendar.current.date(byAdding: .day, value: -offset, to: now) ?? now
            store.recordSession(
                FocusSession(
                    taskID: nil,
                    taskTitle: offset == 0 ? "整理 Mac 版番茄钟界面" : "专注记录 \(offset)",
                    category: offset.isMultiple(of: 2) ? "产品" : "工程",
                    mode: .focus,
                    startedAt: start,
                    endedAt: start.addingTimeInterval(1500),
                    plannedSeconds: 1500,
                    actualSeconds: 1500,
                    completed: true
                )
            )
        }

        _ = store.generatePomodoroPlanFromSchedule(referenceDate: now)
    }

    @MainActor
    private static func render<V: View>(_ view: V, to url: URL) throws {
        let renderer = ImageRenderer(content: view.preferredColorScheme(.dark))
        renderer.scale = 2

        guard let image = renderer.nsImage else {
            throw SnapshotError("ImageRenderer produced no NSImage for \(url.lastPathComponent)")
        }
        guard
            let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData),
            let pngData = bitmap.representation(using: .png, properties: [:])
        else {
            throw SnapshotError("Could not encode PNG for \(url.lastPathComponent)")
        }

        try pngData.write(to: url)
    }

    private static func assertNonBlankImage(at url: URL) throws {
        guard
            let image = NSImage(contentsOf: url),
            let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData)
        else {
            throw SnapshotError("Could not read rendered image at \(url.path)")
        }

        var sampledColors = Set<String>()
        let width = max(bitmap.pixelsWide, 1)
        let height = max(bitmap.pixelsHigh, 1)
        let stepX = max(1, width / 16)
        let stepY = max(1, height / 16)

        for x in stride(from: 0, to: width, by: stepX) {
            for y in stride(from: 0, to: height, by: stepY) {
                guard let color = bitmap.colorAt(x: x, y: y) else { continue }
                sampledColors.insert(
                    "\(Int(color.redComponent * 255))-\(Int(color.greenComponent * 255))-\(Int(color.blueComponent * 255))-\(Int(color.alphaComponent * 255))"
                )
            }
        }

        if sampledColors.count < 6 {
            throw SnapshotError("Rendered image appears blank: \(url.path)")
        }
    }

    private static func assertForegroundContent(at url: URL, minimumXRatio: Double) throws {
        guard
            let image = NSImage(contentsOf: url),
            let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData)
        else {
            throw SnapshotError("Could not read rendered image at \(url.path)")
        }

        let width = max(bitmap.pixelsWide, 1)
        let height = max(bitmap.pixelsHigh, 1)
        let startX = Int(Double(width) * minimumXRatio)
        let stepX = max(1, (width - startX) / 28)
        let stepY = max(1, height / 28)
        var foregroundSamples = 0

        for x in stride(from: startX, to: width, by: stepX) {
            for y in stride(from: 0, to: height, by: stepY) {
                guard let color = bitmap.colorAt(x: x, y: y) else { continue }
                let brightness = max(color.redComponent, color.greenComponent, color.blueComponent)
                let saturation = brightness - min(color.redComponent, color.greenComponent, color.blueComponent)
                if brightness > 0.42 || saturation > 0.18 {
                    foregroundSamples += 1
                }
            }
        }

        if foregroundSamples < 12 {
            throw SnapshotError("Rendered detail content appears empty: \(url.path)")
        }
    }

    private static func assertNoMissingControlPlaceholders(at url: URL) throws {
        guard
            let image = NSImage(contentsOf: url),
            let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData)
        else {
            throw SnapshotError("Could not read rendered image at \(url.path)")
        }

        let width = max(bitmap.pixelsWide, 1)
        let height = max(bitmap.pixelsHigh, 1)
        let stepX = max(1, width / 64)
        let stepY = max(1, height / 64)
        var warningSamples = 0

        for x in stride(from: 0, to: width, by: stepX) {
            for y in stride(from: 0, to: height, by: stepY) {
                guard let color = bitmap.colorAt(x: x, y: y) else { continue }
                let isPlaceholderYellow = color.redComponent > 0.88
                    && color.greenComponent > 0.68
                    && color.blueComponent < 0.12
                if isPlaceholderYellow {
                    warningSamples += 1
                }
            }
        }

        if warningSamples > 2 {
            throw SnapshotError("Rendered image contains missing-control placeholders: \(url.path)")
        }
    }

    private static func metadata(for url: URL) throws -> SnapshotMetadata {
        guard
            let image = NSImage(contentsOf: url),
            let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData)
        else {
            throw SnapshotError("Could not read rendered image metadata at \(url.path)")
        }

        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let byteCount = attributes[.size] as? Int ?? 0
        return SnapshotMetadata(
            fileName: url.lastPathComponent,
            width: bitmap.pixelsWide,
            height: bitmap.pixelsHigh,
            byteCount: byteCount
        )
    }

    private static func writeManifest(_ snapshots: [SnapshotMetadata], to url: URL) throws {
        let manifest = SnapshotManifest(
            generatedAt: ISO8601DateFormatter().string(from: Date()),
            snapshots: snapshots
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(manifest)
        try data.write(to: url)
    }

    private static func assertSnapshotManifest(at url: URL) throws {
        let data = try Data(contentsOf: url)
        let manifest = try JSONDecoder().decode(SnapshotManifest.self, from: data)
        let expectedNames: Set<String> = [
            "mini-timer.png",
            "detail-timer.png",
            "detail-schedule.png",
            "detail-analytics.png",
            "detail-settings.png"
        ]
        let actualNames = Set(manifest.snapshots.map(\.fileName))
        guard actualNames == expectedNames else {
            throw SnapshotError("Snapshot manifest entries do not match expected files: \(actualNames.sorted())")
        }
        guard manifest.snapshots.allSatisfy({ $0.width > 0 && $0.height > 0 && $0.byteCount > 0 }) else {
            throw SnapshotError("Snapshot manifest contains invalid image metadata: \(url.path)")
        }
    }
}

private struct SnapshotManifest: Codable {
    let generatedAt: String
    let snapshots: [SnapshotMetadata]
}

private struct SnapshotMetadata: Codable {
    let fileName: String
    let width: Int
    let height: Int
    let byteCount: Int
}

struct SnapshotError: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}

private struct SnapshotDetailView: View {
    let selectedSection: SnapshotDetailSection
    let content: AnyView

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                Text("ChronoFocus")
                    .font(.title2.bold())
                    .foregroundStyle(MacTheme.primaryText)
                    .padding(.bottom, 8)

                ForEach(SnapshotDetailSection.allCases) { section in
                    Label(section.title, systemImage: section.symbolName)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .background(
                            section == selectedSection ? Color.white.opacity(0.12) : Color.clear,
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                }
                Spacer()
            }
            .font(.headline)
            .foregroundStyle(MacTheme.primaryText)
            .frame(width: 190, alignment: .topLeading)
            .padding(18)
            .background(Color.black.opacity(0.18))

            content
                .frame(width: 910, height: 720, alignment: .topLeading)
            .background(MacTheme.background)
            .clipped()
        }
        .background(MacTheme.background)
        .preferredColorScheme(.dark)
    }
}

private enum SnapshotDetailSection: String, CaseIterable, Identifiable {
    case timer
    case schedule
    case analytics
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .timer: return "计时"
        case .schedule: return "日程"
        case .analytics: return "统计"
        case .settings: return "设置"
        }
    }

    var symbolName: String {
        switch self {
        case .timer: return "timer"
        case .schedule: return "calendar"
        case .analytics: return "chart.xyaxis.line"
        case .settings: return "slider.horizontal.3"
        }
    }
}

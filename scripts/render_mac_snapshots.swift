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
        if CommandLine.arguments.count == 3, CommandLine.arguments[1] == "--ui-evidence-output" {
            try renderUIEvidence(to: URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true))
            return
        }
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

        let miniView = MacMiniTimerView(openDetails: { _ in })
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
        try assertForegroundContent(at: miniURL, minimumXRatio: 0.64, maximumXRatio: 0.94, minimumYRatio: 0.16, maximumYRatio: 0.80)
        try assertNoMissingControlPlaceholders(at: miniURL)
        var snapshotMetadata = [try metadata(for: miniURL)]

        print("Mac snapshots rendered:")
        print(miniURL.path)

        let timerNormalQueueURL = URL(fileURLWithPath: "/tmp/chronofocus-mac-timer-normal-queue.png")
        let timerNormalQueueView = SnapshotDetailView(
            selectedSection: .timer,
            content: AnyView(MacTimerDetailView())
        )
        .environmentObject(store)
        .environmentObject(engine)
        .environmentObject(notifications)
        .environmentObject(premium)
        .environmentObject(calendarSync)
        .environment(\.macSnapshotRendering, true)
        .frame(width: 1100, height: 720)
        guard store.startableTasks().count > 7 else {
            throw SnapshotError("Mac timer queue overflow fixture requires more than seven startable tasks")
        }
        try render(timerNormalQueueView, to: timerNormalQueueURL)
        try assertNonBlankImage(at: timerNormalQueueURL)
        try assertNoMissingControlPlaceholders(at: timerNormalQueueURL)
        print(timerNormalQueueURL.path)

        guard let timerHandoffTask = store.startableTasks().first(where: { $0.category == "产品" }) else {
            throw SnapshotError("Mac schedule to timer handoff fixture requires an enabled 产品 task")
        }
        let timerHandoffRequest = MacTimerHandoffRequest(
            category: "产品",
            preferredTaskID: timerHandoffTask.id
        )
        guard let resolvedTimerHandoffTask = resolveMacTimerHandoffTask(
            timerHandoffRequest,
            from: store.startableTasks()
        ) else {
            throw SnapshotError("Mac schedule to timer handoff fixture could not resolve its request")
        }
        engine.selectTask(resolvedTimerHandoffTask)

        let calendarRangeFixtureCount = store.tasks.filter { task in
            guard task.category == "产品", let dueDate = task.dueDate else { return false }
            return Calendar.current.isDate(dueDate, equalTo: Date(), toGranularity: .weekOfYear)
        }.count
        guard calendarRangeFixtureCount > 4 else {
            throw SnapshotError("Mac calendar range overflow fixture requires more than four tasks")
        }

        let searchFixture = TaskCategorySearchResult(
            options: TaskCategoryPreset.prioritizedFilterOptions(categories: store.taskCategories, countProvider: { _ in 0 }),
            query: "产品",
            selectedCategory: "产品"
        )
        guard searchFixture.showsSearch, searchFixture.matches.map(\.category) == ["产品"] else {
            throw SnapshotError("Category filter search fixture requires six categories and one visible product match")
        }

        let detailPages: [(fileName: String, section: SnapshotDetailSection, content: AnyView)] = [
            (
                "detail-timer.png",
                .timer,
                AnyView(MacTimerDetailView(
                    initialTaskCategory: "产品",
                    timerHandoffRequest: timerHandoffRequest
                ))
            ),
            (
                "detail-schedule.png",
                .schedule,
                AnyView(MacScheduleDetailView(
                    initialTaskCategory: "产品",
                    initialExistingCategorySearchQuery: "产品"
                ))
            ),
            ("detail-analytics.png", .analytics, AnyView(MacAnalyticsDetailView())),
            ("detail-settings.png", .settings, AnyView(MacSettingsDetailView()))
        ]

        for detailPage in detailPages {
            let detailURL = outputDirectory.appendingPathComponent(detailPage.fileName)
            let detailContentHeight: CGFloat = detailPage.fileName == "detail-schedule.png" ? 1400 : 720
            let detailView = SnapshotDetailView(
                selectedSection: detailPage.section,
                content: detailPage.content,
                contentHeight: detailContentHeight
            )
            .environmentObject(store)
            .environmentObject(engine)
            .environmentObject(notifications)
            .environmentObject(premium)
            .environmentObject(calendarSync)
            .environment(\.macSnapshotRendering, true)
            .environment(\.macSnapshotCategorySearch, "产品")
            .frame(
                width: 1100,
                height: detailContentHeight
            )

            try render(detailView, to: detailURL)
            try assertNonBlankImage(at: detailURL)
            try assertForegroundContent(at: detailURL, minimumXRatio: 0.22)
            try assertNoMissingControlPlaceholders(at: detailURL)
            snapshotMetadata.append(try metadata(for: detailURL))
            print(detailURL.path)
        }

        guard store.startableTasks().allSatisfy({ $0.category != "工作" }) else {
            throw SnapshotError("Mac timer category empty fixture requires zero 工作 tasks")
        }

        let timerCategoryEmptyURL = URL(fileURLWithPath: "/tmp/chronofocus-mac-timer-category-empty.png")
        let timerCategoryEmptyView = SnapshotDetailView(
            selectedSection: .timer,
            content: AnyView(MacTimerDetailView(initialTaskCategory: "工作"))
        )
        .environmentObject(store)
        .environmentObject(engine)
        .environmentObject(notifications)
        .environmentObject(premium)
        .environmentObject(calendarSync)
        .environment(\.macSnapshotRendering, true)
        .frame(width: 1100, height: 720)
        try render(timerCategoryEmptyView, to: timerCategoryEmptyURL)
        try assertNonBlankImage(at: timerCategoryEmptyURL)
        try assertNoMissingControlPlaceholders(at: timerCategoryEmptyURL)

        let timerCategoryEmptyNarrowURL = URL(fileURLWithPath: "/tmp/chronofocus-mac-timer-category-empty-narrow.png")
        let timerCategoryEmptyNarrowView = MacTimerCategoryEmptyStateView(
            category: "工作",
            isSnapshotRendering: true,
            onAddTask: {},
            onClear: {}
        )
        .environmentObject(store)
        .frame(width: 220)
        try render(timerCategoryEmptyNarrowView, to: timerCategoryEmptyNarrowURL)
        try assertNonBlankImage(at: timerCategoryEmptyNarrowURL)
        try assertNoMissingControlPlaceholders(at: timerCategoryEmptyNarrowURL)
        print(timerCategoryEmptyURL.path)
        print(timerCategoryEmptyNarrowURL.path)

        guard store.startableTasks().contains(where: { $0.category == "产品" }) else {
            throw SnapshotError("Mac timer category context fixture requires 产品 tasks")
        }

        let timerCategoryFilteredURL = URL(fileURLWithPath: "/tmp/chronofocus-mac-timer-category-filtered.png")
        let timerCategoryFilteredView = SnapshotDetailView(
            selectedSection: .timer,
            content: AnyView(MacTimerDetailView(initialTaskCategory: "产品"))
        )
        .environmentObject(store)
        .environmentObject(engine)
        .environmentObject(notifications)
        .environmentObject(premium)
        .environmentObject(calendarSync)
        .environment(\.macSnapshotRendering, true)
        .frame(width: 1100, height: 720)
        try render(timerCategoryFilteredView, to: timerCategoryFilteredURL)
        try assertNonBlankImage(at: timerCategoryFilteredURL)
        try assertForegroundContent(at: timerCategoryFilteredURL, minimumXRatio: 0.22)
        try assertNoMissingControlPlaceholders(at: timerCategoryFilteredURL)

        let timerCategoryContextNarrowURL = URL(fileURLWithPath: "/tmp/chronofocus-mac-timer-category-context-narrow.png")
        let timerCategoryContextNarrowView = MacTimerCategoryContextView(
            category: "跨团队产品体验优化",
            filteredCount: 128,
            totalCount: 1024,
            isSnapshotRendering: true,
            onAddTask: {},
            onClear: {}
        )
        .environmentObject(store)
        .frame(width: 220)
        try render(timerCategoryContextNarrowView, to: timerCategoryContextNarrowURL)
        try assertNonBlankImage(at: timerCategoryContextNarrowURL)
        try assertNoMissingControlPlaceholders(at: timerCategoryContextNarrowURL)
        try assertMinimumPixelSize(
            at: timerCategoryContextNarrowURL,
            width: 400,
            height: 220
        )
        print(timerCategoryFilteredURL.path)
        print(timerCategoryContextNarrowURL.path)

        let manifestURL = outputDirectory.appendingPathComponent("manifest.json")
        try writeManifest(snapshotMetadata, to: manifestURL)
        try assertSnapshotManifest(at: manifestURL)
        print(manifestURL.path)
    }

    @MainActor
    private static func renderUIEvidence(to outputDirectory: URL) throws {
        guard !FileManager.default.fileExists(atPath: outputDirectory.path) else {
            throw SnapshotError("UI output directory already exists")
        }
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        let checksDirectory = outputDirectory.appendingPathComponent("checks", isDirectory: true)
        try FileManager.default.createDirectory(at: checksDirectory, withIntermediateDirectories: true)
        let blankURL = checksDirectory.appendingPathComponent("blank-negative.png")
        try render(Color(red: 0.10, green: 0.12, blue: 0.14).frame(width: 920, height: 1800), to: blankURL)
        var blankRejected = false
        do {
            try assertForegroundContent(at: blankURL, minimumXRatio: 0.22)
        } catch let error as SnapshotError {
            blankRejected = error.description.contains("Rendered detail content appears empty")
        }
        guard blankRejected else { throw SnapshotError("Foreground detector accepted the blank negative fixture") }
        let blankLightURL = checksDirectory.appendingPathComponent("blank-light-negative.png")
        try render(MacTheme.background.frame(width: 920, height: 1800), to: blankLightURL, theme: .light)
        try assertBackgroundTheme(at: blankLightURL, theme: .light)
        var lightBlankRejected = false
        do {
            try assertForegroundContent(at: blankLightURL, minimumXRatio: 0.22, theme: .light)
        } catch let error as SnapshotError {
            lightBlankRejected = error.description.contains("Rendered detail content appears empty")
        }
        guard lightBlankRejected else { throw SnapshotError("Foreground detector accepted the blank light negative fixture") }
        for theme in AppThemeMode.allCases {
            let blankPanelURL = checksDirectory.appendingPathComponent("blank-panel-\(theme.rawValue)-negative.png")
            let blankPanel = ZStack(alignment: .topTrailing) {
                MacTheme.background
                Text("25:00")
                    .font(.largeTitle.bold())
                    .foregroundStyle(MacTheme.primaryText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .padding(.leading, 20)
                RoundedRectangle(cornerRadius: 8)
                    .fill(MacTheme.quickPanel)
                    .frame(width: 210, height: 410)
                    .padding(.top, 58)
                    .padding(.trailing, 20)
            }
            .frame(width: 560, height: 500)
            try render(blankPanel, to: blankPanelURL, theme: theme)
            try assertNonBlankImage(at: blankPanelURL)
            var panelRejected = false
            do {
                try assertForegroundContent(at: blankPanelURL, minimumXRatio: 0.64, theme: theme, maximumXRatio: 0.94, minimumYRatio: 0.16, maximumYRatio: 0.80)
            } catch let error as SnapshotError {
                panelRejected = error.description.contains("Rendered detail content appears empty")
            }
            guard panelRejected else { throw SnapshotError("Panel detector accepted a blank \(theme.rawValue) panel beside visible timer content") }
        }
        print("Quick panel blank-region negatives rejected for dark and light.")
        let suiteName = "ChronoFocusUIEvidence-\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            throw SnapshotError("Could not create UI evidence suite")
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = FocusStore(defaults: defaults)
        seedSnapshotData(into: store)
        store.settings.autoStartFocus = false
        store.settings.autoStartBreaks = false
        let notifications = MacNotificationService(disabledForSnapshots: true)
        let engine = TimerEngine(store: store, notifications: notifications, liveActivities: MacLiveActivityService())
        let premium = MacPremiumAccessService(loadProductsOnInit: false, isProUnlockedForSnapshots: true)
        let calendarSync = MacCalendarSyncService()
        var fixtures = [UIFixtureMetadata]()

        @MainActor
        func capture(_ name: String, section: SnapshotDetailSection, content: AnyView, width: CGFloat,
                     height: CGFloat = 720, state: String, largeType: Bool = false,
                     theme: AppThemeMode = .dark, categoriesExpanded: Bool = false) throws {
            store.settings.appThemeMode = theme
            let view = SnapshotDetailView(selectedSection: section, content: content, contentHeight: height, windowWidth: width)
                .environmentObject(store)
                .environmentObject(engine)
                .environmentObject(notifications)
                .environmentObject(premium)
                .environmentObject(calendarSync)
                .environment(\.macSnapshotRendering, true)
                .environment(\.macSnapshotCategoriesExpanded, categoriesExpanded)
                .dynamicTypeSize(largeType ? .accessibility2 : .large)
                .frame(width: width, height: height)
            let url = outputDirectory.appendingPathComponent(name)
            try render(view, to: url, theme: theme)
            try assertNonBlankImage(at: url)
            try assertForegroundContent(at: url, minimumXRatio: 0.22, theme: theme)
            try assertBackgroundTheme(at: url, theme: theme)
            try assertNoMissingControlPlaceholders(at: url)
            let image = try metadata(for: url)
            guard image.width == Int(width * 2), image.height == Int(height * 2) else {
                throw SnapshotError("UI fixture dimensions do not match the entire window: \(name)")
            }
            fixtures.append(UIFixtureMetadata(image: image, windowWidth: Int(width), windowHeight: Int(height),
                                              sidebarWidth: 190, contentWidth: Int(width) - 190,
                                              state: state, dynamicType: largeType ? "accessibility2" : "large",
                                              theme: theme.rawValue, categoriesExpanded: categoriesExpanded))
            print("Rendered UI fixture: \(name), window=\(Int(width))x\(Int(height)), state=\(state)")
        }

        try capture("timer-1100.png", section: .timer, content: AnyView(MacTimerDetailView()), width: 1100, state: "idle, full queue")
        try capture("timer-920.png", section: .timer, content: AnyView(MacTimerDetailView()), width: 920, state: "idle, compact columns")
        try capture("timer-920-full.png", section: .timer, content: AnyView(MacTimerDetailView()), width: 920, height: 1800, state: "idle, compact full page")
        try capture("schedule-1100.png", section: .schedule, content: AnyView(MacScheduleDetailView(initialTaskCategory: "产品")), width: 1100, state: "product category, task-first viewport")
        try capture("schedule-920.png", section: .schedule, content: AnyView(MacScheduleDetailView(initialTaskCategory: "产品")), width: 920, state: "product category, compact task-first viewport")
        try capture("schedule-expanded.png", section: .schedule, content: AnyView(MacScheduleDetailView(initialTaskCategory: "产品")), width: 1100, height: 1400, state: "all categories expanded", categoriesExpanded: true)
        try capture("timer-light.png", section: .timer, content: AnyView(MacTimerDetailView()), width: 1100, state: "light timer, collapsed categories", theme: .light)
        try capture("schedule-light.png", section: .schedule, content: AnyView(MacScheduleDetailView(initialTaskCategory: "产品")), width: 1100, height: 1000, state: "light schedule, collapsed categories", theme: .light)
        try capture("analytics-light.png", section: .analytics, content: AnyView(MacAnalyticsDetailView()), width: 1100, height: 1400, state: "light analytics", theme: .light)
        try capture("settings-light.png", section: .settings, content: AnyView(MacSettingsDetailView()), width: 1100, height: 1100, state: "light settings, theme control", theme: .light)

        store.settings.appThemeMode = .light
        let miniLightURL = outputDirectory.appendingPathComponent("mini-light.png")
        let miniLight = MacMiniTimerView(openDetails: { _ in })
            .environmentObject(store)
            .environmentObject(engine)
            .environmentObject(notifications)
            .environmentObject(premium)
            .environment(\.macSnapshotRendering, true)
            .environment(\.macSnapshotShowsQuickPanel, true)
        try render(miniLight, to: miniLightURL, theme: .light)
        try assertNonBlankImage(at: miniLightURL)
        try assertForegroundContent(at: miniLightURL, minimumXRatio: 0, theme: .light)
        try assertForegroundContent(at: miniLightURL, minimumXRatio: 0.64, theme: .light, maximumXRatio: 0.94, minimumYRatio: 0.16, maximumYRatio: 0.80)
        try assertBackgroundTheme(at: miniLightURL, theme: .light)
        try assertNoMissingControlPlaceholders(at: miniLightURL)
        let miniMetadata = try metadata(for: miniLightURL)
        guard miniMetadata.width == 1120, miniMetadata.height == 1000 else { throw SnapshotError("Light popover dimensions changed") }
        fixtures.append(UIFixtureMetadata(image: miniMetadata, windowWidth: 560, windowHeight: 500,
                                          sidebarWidth: 0, contentWidth: 560, state: "light popover and quick panel",
                                          dynamicType: "large", theme: "light", categoriesExpanded: false))

        guard let longTask = store.addTask(title: "整理跨团队产品体验评审中的问题，完成下一阶段的可访问性与发布准备", category: "跨团队产品体验与设计系统", dueDate: nil, estimatedRounds: 2, accentHex: "#3DE8C5") else {
            throw SnapshotError("Could not create long title fixture")
        }
        engine.selectTask(longTask)
        try capture("timer-long-text.png", section: .timer, content: AnyView(MacTimerDetailView(initialTaskCategory: longTask.category)), width: 920, height: 1500, state: "long Chinese task and category", largeType: true)
        engine.start()
        engine.pause()
        guard engine.isPaused, store.activeTimer?.taskID == longTask.id else { throw SnapshotError("Paused fixture did not pause") }
        try capture("timer-paused.png", section: .timer, content: AnyView(MacTimerDetailView()), width: 1100, state: "paused, resume action")
        engine.stop(markIncomplete: false)

        guard let openTask = store.addTask(title: "阅读与记录想法", category: "阅读", dueDate: nil, estimatedRounds: 1, accentHex: "#FFB84D", startMode: .openEnded) else {
            throw SnapshotError("Could not create open-ended fixture")
        }
        engine.selectTask(openTask)
        engine.start()
        try capture("timer-open-ended.png", section: .timer, content: AnyView(MacTimerDetailView()), width: 920, state: "open-ended, finish task action")
        engine.stop(markIncomplete: false)
        engine.selectTask(nil)
        store.tasks.removeAll()
        store.pomodoroPlan.removeAll()
        try capture("timer-empty.png", section: .timer, content: AnyView(MacTimerDetailView()), width: 1100, state: "empty queue, free focus available")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(fixtures).write(to: outputDirectory.appendingPathComponent("fixtures.json"))
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
        let calendar = Calendar.current
        let snapshotDay = calendar.startOfDay(for: now)
        let snapshotDueDate: (Int, Int) -> Date = { hour, minute in
            calendar.date(bySettingHour: hour, minute: minute, second: 0, of: snapshotDay) ?? now
        }
        _ = store.addTask(
            title: "整理 Mac 版番茄钟界面",
            category: "产品",
            dueDate: snapshotDueDate(9, 0),
            estimatedRounds: 3,
            accentHex: "#3DE8C5",
            isEnabled: true,
            autoStartPomodoro: true
        )
        _ = store.addTask(
            title: "接入日历同步验收",
            category: "工程",
            dueDate: snapshotDueDate(10, 0),
            estimatedRounds: 2,
            accentHex: "#54A0FF"
        )
        _ = store.addTask(
            title: "统计报表视觉检查",
            category: "复盘",
            dueDate: snapshotDueDate(11, 0),
            estimatedRounds: 1,
            accentHex: "#A78BFA"
        )

        for index in 1...5 {
            _ = store.addTask(
                title: "日程范围任务 \(index)",
                category: "产品",
                dueDate: snapshotDueDate(12 + index / 4, (index % 4) * 15),
                estimatedRounds: 1,
                accentHex: index.isMultiple(of: 2) ? "#3DE8C5" : "#54A0FF"
            )
        }

        for index in 1...6 {
            _ = store.addTask(
                title: "队列浏览任务 \(index)",
                category: "队列验证",
                dueDate: snapshotDueDate(12 + index / 4, (index % 4) * 15),
                estimatedRounds: 1,
                accentHex: index.isMultiple(of: 2) ? "#FF9F43" : "#54A0FF"
            )
        }

        let sessionCategories = [
            "产品",
            "工程",
            "用户研究",
            "设计系统",
            "客户反馈",
            "阅读笔记",
            "历史归档"
        ]
        for (offset, sessionCategory) in sessionCategories.enumerated() {
            let start = Calendar.current.date(byAdding: .day, value: -offset, to: now) ?? now
            store.recordSession(
                FocusSession(
                    taskID: nil,
                    taskTitle: offset == 0 ? "整理 Mac 版番茄钟界面" : "专注记录 \(offset)",
                    category: sessionCategory,
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
    private static func render<V: View>(_ view: V, to url: URL, theme: AppThemeMode = .dark) throws {
        let scheme: ColorScheme = theme == .dark ? .dark : .light
        guard let appearance = NSAppearance(named: theme == .dark ? .darkAqua : .aqua) else {
            throw SnapshotError("Could not resolve the requested appearance")
        }
        var renderedImage: NSImage?
        appearance.performAsCurrentDrawingAppearance {
            let renderer = ImageRenderer(content: view.environment(\.colorScheme, scheme).preferredColorScheme(scheme))
            renderer.scale = 2
            renderedImage = renderer.nsImage
        }
        guard let image = renderedImage else {
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

    private static func assertForegroundContent(at url: URL, minimumXRatio: Double, theme: AppThemeMode = .dark,
                                                maximumXRatio: Double = 1, minimumYRatio: Double = 0,
                                                maximumYRatio: Double = 1) throws {
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
        let endX = Int(Double(width) * maximumXRatio)
        let startY = Int(Double(height) * minimumYRatio)
        let endY = Int(Double(height) * maximumYRatio)
        // A sparse 28-row grid can miss glyphs on a tall, otherwise valid page.
        let stepX = max(1, (endX - startX) / 96)
        let stepY = max(1, (endY - startY) / 96)
        var foregroundSamples = 0

        for x in stride(from: startX, to: endX, by: stepX) {
            for y in stride(from: startY, to: endY, by: stepY) {
                guard let color = bitmap.colorAt(x: x, y: y) else { continue }
                let brightness = max(color.redComponent, color.greenComponent, color.blueComponent)
                let saturation = brightness - min(color.redComponent, color.greenComponent, color.blueComponent)
                let hasTextContrast = theme == .dark ? brightness > 0.42 : brightness < 0.62
                if hasTextContrast || saturation > 0.18 {
                    foregroundSamples += 1
                }
            }
        }

        if foregroundSamples < 12 {
            throw SnapshotError("Rendered detail content appears empty: \(url.path)")
        }
    }

    private static func assertBackgroundTheme(at url: URL, theme: AppThemeMode) throws {
        guard let image = NSImage(contentsOf: url), let data = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: data),
              let color = bitmap.colorAt(x: bitmap.pixelsWide - 4, y: bitmap.pixelsHigh - 4) else {
            throw SnapshotError("Could not read the theme background")
        }
        let brightness = max(color.redComponent, color.greenComponent, color.blueComponent)
        guard theme == .light ? brightness > 0.75 : brightness < 0.40 else {
            throw SnapshotError("Rendered background does not match \(theme.rawValue): \(url.lastPathComponent)")
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

    private static func assertMinimumPixelSize(at url: URL, width: Int, height: Int) throws {
        guard
            let image = NSImage(contentsOf: url),
            let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData)
        else {
            throw SnapshotError("Could not read rendered image dimensions at \(url.path)")
        }

        guard bitmap.pixelsWide >= width, bitmap.pixelsHigh >= height else {
            throw SnapshotError(
                "Rendered image is smaller than \(width)x\(height) pixels: "
                    + "\(bitmap.pixelsWide)x\(bitmap.pixelsHigh) at \(url.path)"
            )
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

private struct UIFixtureMetadata: Codable {
    let image: SnapshotMetadata
    let windowWidth: Int
    let windowHeight: Int
    let sidebarWidth: Int
    let contentWidth: Int
    let state: String
    let dynamicType: String
    let theme: String
    let categoriesExpanded: Bool
}

struct SnapshotError: Error, CustomStringConvertible {
    let description: String

    init(_ description: String) {
        self.description = description
    }
}

private struct SnapshotDetailView: View {
    @EnvironmentObject private var store: FocusStore
    let selectedSection: SnapshotDetailSection
    let content: AnyView
    let contentHeight: CGFloat
    let windowWidth: CGFloat

    init(
        selectedSection: SnapshotDetailSection,
        content: AnyView,
        contentHeight: CGFloat = 720,
        windowWidth: CGFloat = 1100
    ) {
        self.selectedSection = selectedSection
        self.content = content
        self.contentHeight = contentHeight
        self.windowWidth = windowWidth
    }

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
                            section == selectedSection ? MacTheme.track : Color.clear,
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                }
                Spacer()
            }
            .font(.headline)
            .foregroundStyle(MacTheme.primaryText)
            .padding(18)
            .frame(width: 190, alignment: .topLeading)
            .background(MacTheme.sidebar)

            content
                .frame(width: windowWidth - 190, height: contentHeight, alignment: .topLeading)
            .background(MacTheme.background)
            .clipped()
        }
        .background(MacTheme.background)
        .preferredColorScheme(store.settings.appThemeMode == .dark ? .dark : .light)
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

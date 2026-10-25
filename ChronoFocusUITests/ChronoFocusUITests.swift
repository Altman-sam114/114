import XCTest

@MainActor
final class ChronoFocusUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    override func tearDownWithError() throws {
        app?.terminate()
    }

    func testFreeFocusLifecycle() {
        launch(fixture: "empty")
        capture("timer-idle")
        let primary = app.buttons["timer.primary"]
        XCTAssertTrue(primary.isHittable, "The default primary action must be visible without scrolling")
        XCTAssertLessThanOrEqual(primary.frame.maxY, app.tabBars.firstMatch.frame.minY, "The tab bar must not cover the primary action")
        reveal(primary)
        primary.tap()
        waitForLabel(primary, prefix: "暂停")
        capture("timer-running")
        primary.tap()
        waitForLabel(primary, prefix: "继续")
        capture("timer-paused")
        primary.tap()
        waitForLabel(primary, prefix: "暂停")
        capture("timer-resumed")
        let stop = app.buttons["timer.stop"]
        reveal(stop)
        stop.tap()
        waitForLabel(primary, prefix: "开始")
        capture("timer-stopped")
    }

    func testReminderDisclosure() {
        launch(fixture: "empty")
        let disclosure = app.buttons["timer.reminders"]
        reveal(disclosure)
        XCTAssertTrue((disclosure.value as? String)?.contains("已收起") == true)
        disclosure.tap()
        let expanded = NSPredicate(format: "value CONTAINS %@", "已展开")
        expectation(for: expanded, evaluatedWith: disclosure)
        waitForExpectations(timeout: 5)
        capture("reminders-expanded")
        reveal(disclosure)
        disclosure.tap()
        XCTAssertTrue((disclosure.value as? String)?.contains("已收起") == true)
        capture("reminders-collapsed")
    }

    func testThemeSwitchAcrossTabs() {
        launch(fixture: "tasks")
        let theme = app.buttons["theme.toggle"]
        XCTAssertEqual(theme.value as? String, "暗色")
        theme.tap()
        expectation(for: NSPredicate(format: "value == %@", "亮色"), evaluatedWith: theme)
        waitForExpectations(timeout: 5)
        capture("timer-light")
        app.tabBars.buttons["日程"].tap()
        XCTAssertTrue(app.buttons["schedule.add"].waitForExistence(timeout: 5))
        capture("schedule-light")
        app.tabBars.buttons["设置"].tap()
        revealNotificationAction()
        capture("settings-notifications-light")
        let privacy = app.descendants(matching: .any)["settings.privacy"].firstMatch
        reveal(privacy)
        let notice = app.staticTexts["settings.privacy.notice"]
        reveal(notice)
        if notice.frame.maxY > app.tabBars.firstMatch.frame.minY { app.swipeUp() }
        XCTAssertGreaterThanOrEqual(notice.frame.height, 44)
        XCTAssertLessThanOrEqual(notice.frame.maxX, app.frame.maxX)
        XCTAssertLessThanOrEqual(notice.frame.maxY, app.tabBars.firstMatch.frame.minY, "Data notice must remain above the tab bar")
        capture("settings-privacy-light")
        app.tabBars.buttons["计时"].tap()
        XCTAssertEqual(theme.value as? String, "亮色", "Theme must survive switching tabs")
        theme.tap()
        expectation(for: NSPredicate(format: "value == %@", "暗色"), evaluatedWith: theme)
        waitForExpectations(timeout: 5)
        capture("timer-dark-restored")
        app.tabBars.buttons["日程"].tap()
        reveal(app.buttons["schedule.plan.generate"])
        capture("schedule-actions-dark")
    }

    func testScheduleCategoryPrefillAndSave() {
        launch(fixture: "tasks")
        app.tabBars.buttons["日程"].tap()
        let search = app.textFields["category.search"]
        reveal(search)
        search.tap()
        search.typeText("产品\n")
        let category = app.buttons["schedule.category.产品"]
        reveal(category)
        category.tap()
        capture("schedule-filtered")
        let add = app.buttons["schedule.add"]
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        add.tap()
        let categoryField = app.textFields["task.editor.category"]
        XCTAssertTrue(categoryField.waitForExistence(timeout: 5))
        XCTAssertEqual(categoryField.value as? String, "产品")
        capture("task-editor-prefilled")
        let title = app.textFields["task.editor.title"]
        title.tap()
        title.typeText("云端新增待办")
        app.buttons["task.editor.save"].tap()
        let saved = app.staticTexts["云端新增待办"].firstMatch
        XCTAssertTrue(saved.waitForExistence(timeout: 5))
        reveal(saved)
        capture("schedule-saved")
    }

    func testAccessibilityTextWithLongTask() {
        launch(fixture: "long", largeType: true)
        capture("large-text-idle")
        let remaining = app.staticTexts["timer.remaining"]
        XCTAssertTrue(remaining.waitForExistence(timeout: 5))
        XCTAssertEqual(remaining.value as? String, "25:00")
        let taskTitle = app.staticTexts["timer.task-title"]
        XCTAssertGreaterThan(taskTitle.frame.height, 120, "The long task title must actually expand in the accessibility layout")
        XCTAssertLessThanOrEqual(remaining.frame.maxX, app.frame.maxX, "The countdown must remain inside the viewport")
        let primary = app.buttons["timer.primary"]
        reveal(primary)
        XCTAssertGreaterThanOrEqual(primary.frame.height, 44)
        XCTAssertLessThanOrEqual(primary.frame.maxX, app.frame.maxX)
        primary.tap()
        waitForLabel(primary, prefix: "暂停")
        capture("large-text-running")
        app.tabBars.buttons["设置"].tap()
        revealNotificationAction()
        capture("large-text-notifications")
    }

    func testScheduleAccessibilityAndActions() {
        launch(fixture: "schedule-long", largeType: true)
        app.tabBars.buttons["日程"].tap()
        let heading = app.descendants(matching: .any)["schedule.calendar.heading"].firstMatch
        XCTAssertTrue(heading.waitForExistence(timeout: 5))
        XCTAssertLessThan(heading.frame.height, 160, "The calendar heading must not collapse into a column of individual characters")
        let today = app.buttons["schedule.today"]
        revealInsideViewport(today)
        XCTAssertTrue(today.isHittable)
        XCTAssertGreaterThanOrEqual(today.frame.height, 44)
        capture("schedule-large-calendar")
        let title = app.staticTexts.matching(NSPredicate(format: "identifier BEGINSWITH %@", "schedule.task.title.")).firstMatch
        revealInsideViewport(title)
        XCTAssertEqual(title.label, "整理产品体验评审与下一阶段任务")
        XCTAssertGreaterThan(title.frame.height, 80)
        capture("schedule-long-title")
        let category = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "schedule.task.category.")).firstMatch
        revealInsideViewport(category)
        XCTAssertTrue(category.label.contains("跨团队产品体验与可访问性改进"))
        XCTAssertGreaterThan(category.frame.height, 40)
        capture("schedule-long-category")
        for name in ["focus", "edit", "enable"] {
            let action = taskAction(name)
            revealInsideViewport(action)
            XCTAssertTrue(action.isHittable)
            XCTAssertGreaterThanOrEqual(action.frame.height, 44)
        }
        capture("schedule-long-actions")
        let edit = taskAction("edit")
        revealInsideViewport(edit)
        edit.tap()
        let field = app.textFields["task.editor.category"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        XCTAssertEqual(field.value as? String, "跨团队产品体验与可访问性改进")
        capture("schedule-long-editor")
        app.buttons["task.editor.cancel"].tap()
        let focus = taskAction("focus")
        revealInsideViewport(focus)
        focus.tap()
        let selectedTitle = app.staticTexts["timer.task-title"]
        XCTAssertTrue(selectedTitle.waitForExistence(timeout: 5))
        expectation(for: NSPredicate(format: "label == %@", "整理产品体验评审与下一阶段任务"), evaluatedWith: selectedTitle)
        waitForExpectations(timeout: 5)
        XCTAssertEqual(selectedTitle.label, "整理产品体验评审与下一阶段任务")
        XCTAssertTrue(app.buttons["timer.primary"].label.hasPrefix("开始"), "Schedule handoff must select the task without starting it")
        capture("schedule-long-handoff")
    }

    private func taskAction(_ name: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "schedule.task.\(name).")).firstMatch
    }

    private func revealInsideViewport(_ element: XCUIElement) {
        reveal(element)
        for _ in 0..<12 {
            let top = app.navigationBars.firstMatch.frame.maxY + 6
            let bottom = app.tabBars.firstMatch.frame.minY - 6
            let frame = element.frame
            if frame.minY >= top && frame.maxY <= bottom { break }
            let overflow = frame.minY < top ? frame.minY - top : frame.maxY - bottom
            scrollVertically(by: overflow, maximumStep: 160)
        }
        let frame = element.frame
        let top = app.navigationBars.firstMatch.frame.maxY + 6
        let bottom = app.tabBars.firstMatch.frame.minY - 6
        if frame.minY < top || frame.maxY > bottom {
            capture("viewport-alignment-failure")
        }
        XCTAssertGreaterThanOrEqual(frame.minY, top)
        XCTAssertLessThanOrEqual(frame.maxY, bottom)
        XCTAssertGreaterThanOrEqual(element.frame.minX, app.frame.minX)
        XCTAssertLessThanOrEqual(element.frame.maxX, app.frame.maxX)
    }

    private func launch(fixture: String, largeType: Bool = false) {
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-fixture=\(fixture)", "-AppleLanguages", "(zh-Hans)", "-AppleLocale", "zh_CN"]
        if largeType {
            app.launchArguments += ["--ui-large-type"]
        }
        app.launch()
        XCTAssertTrue(app.buttons["timer.primary"].waitForExistence(timeout: 10))
        XCTAssertTrue([CGFloat(375), CGFloat(390)].contains(app.frame.width), "UI tests must run on the declared iPhone widths")
        let dimensions = XCTAttachment(string: "pointWidth=\(app.frame.width);pointHeight=\(app.frame.height);largeType=\(largeType)")
        dimensions.name = "fixture-dimensions"
        dimensions.lifetime = .keepAlways
        add(dimensions)
    }

    private func revealNotificationAction() {
        let action = app.buttons["settings.notifications.authorize"]
        revealInsideViewport(action)
        XCTAssertEqual(action.label, "授权")
        XCTAssertTrue(action.isHittable)
        XCTAssertGreaterThanOrEqual(action.frame.width, 120, "The notification action must not collapse beside the status message")
        XCTAssertGreaterThanOrEqual(action.frame.height, 44)
        XCTAssertLessThanOrEqual(action.frame.maxX, app.frame.maxX)
        XCTAssertLessThanOrEqual(action.frame.maxY, app.tabBars.firstMatch.frame.minY)
    }

    private func reveal(_ element: XCUIElement) {
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        for attempt in 0..<16 {
            if element.isHittable { return }
            let frame = element.frame
            let isAboveViewport = !frame.isEmpty && frame.maxY < app.frame.midY
            if isAboveViewport || (frame.isEmpty && attempt >= 8) {
                scrollVertically(by: -240)
            } else {
                scrollVertically(by: 240)
            }
        }
        capture("unreachable-control")
        XCTFail("Control could not be reached by scrolling: \(element.identifier)")
    }

    private func scrollVertically(by overflow: CGFloat, maximumStep: CGFloat = 240) {
        let top = app.navigationBars.firstMatch.frame.maxY + 6
        let bottom = app.tabBars.firstMatch.frame.minY - 6
        let limit = min(maximumStep, (bottom - top) * 0.6)
        let magnitude = min(limit, max(32, abs(overflow)))
        let distance = overflow < 0 ? -magnitude : magnitude
        // The outer gutter avoids nested pickers and horizontal category scrollers.
        // Tiny corrections must still cross the scroll recognizer's movement threshold.
        let center = app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: 10, dy: (top + bottom) / 2))
        center.withOffset(CGVector(dx: 0, dy: distance / 2)).press(forDuration: 0.1, thenDragTo: center.withOffset(CGVector(dx: 0, dy: -distance / 2)), withVelocity: .slow, thenHoldForDuration: 0.1)
    }

    private func waitForLabel(_ element: XCUIElement, prefix: String) {
        expectation(for: NSPredicate(format: "label BEGINSWITH %@", prefix), evaluatedWith: element)
        waitForExpectations(timeout: 5)
    }

    private func capture(_ name: String) {
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = name
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}

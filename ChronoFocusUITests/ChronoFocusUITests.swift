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
        app.tabBars.buttons["计时"].tap()
        XCTAssertEqual(theme.value as? String, "亮色", "Theme must survive switching tabs")
        theme.tap()
        expectation(for: NSPredicate(format: "value == %@", "暗色"), evaluatedWith: theme)
        waitForExpectations(timeout: 5)
        capture("timer-dark-restored")
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

    private func reveal(_ element: XCUIElement) {
        XCTAssertTrue(element.waitForExistence(timeout: 5))
        for _ in 0..<10 {
            if element.isHittable { return }
            app.swipeUp()
        }
        XCTFail("Control could not be reached by scrolling: \(element.identifier)")
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

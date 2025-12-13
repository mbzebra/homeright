//
//  HomeRightUITests.swift
//  HomeRightUITests
//
//  Created by Mariswaran Balasubramanian on 12/5/25.
//

import XCTest

final class HomeRightUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testNotificationsCanBeEnabledAndScheduled() {
        let app = XCUIApplication()
        app.launch()

        addUIInterruptionMonitor(withDescription: "Notification Permission") { alert in
            if alert.buttons["Allow"].exists {
                alert.buttons["Allow"].tap()
                return true
            } else if alert.buttons["Allow Once"].exists {
                alert.buttons["Allow Once"].tap()
                return true
            }
            return false
        }

        let bellButton = app.buttons["reminderButton"]
        XCTAssertTrue(bellButton.waitForExistence(timeout: 5), "Bell button not found")
        bellButton.tap()
        app.tap() // trigger permission handler if needed

        let toggle = app.switches["enableRemindersToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5), "Reminder toggle not found")
        if toggle.value as? String == "0" {
            toggle.tap()
        }

        let status = app.staticTexts["notificationStatus"]
        XCTAssertTrue(status.waitForExistence(timeout: 5), "Status label not found")
        XCTAssertTrue(status.label.contains("Reminders") || status.label.contains("Scheduled"), "Status did not update: \(status.label)")
    }
}

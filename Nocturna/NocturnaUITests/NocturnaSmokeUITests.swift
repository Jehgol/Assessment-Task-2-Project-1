import XCTest

/// A minimal UI test that exercises app launch and the first step of onboarding.
final class NocturnaSmokeUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testOnboardingFirstScreenAndAdvance() {
        let app = XCUIApplication()
        app.launch()

        let getStarted = app.buttons["Get Started"]
        let continueBtn = app.buttons["Continue"]
        XCTAssertTrue(getStarted.exists || continueBtn.exists, "The first screen should expose a primary call to action.")

        if getStarted.exists { getStarted.tap() } else { continueBtn.tap() }

        // Confirm that a configuration screen is presented.
        let bedtimeTitle = app.staticTexts["Set Your Bedtime"]
        let wakeTitle = app.staticTexts["Set Your Wake Time"]
        XCTAssertTrue(bedtimeTitle.exists || wakeTitle.exists, "Advancing should lead to a configuration step.")
    }
}

import XCTest
@testable import Nocturna

/// Confirms persistence helpers operate on focus modes and surface onboarding state.
final class DataManagerTests: XCTestCase {

    func testAddUpdateDeleteFocusMode() {
        let manager = DataManager.shared
        manager.resetAllData() // Start from a known state where supported.

        let mode = FocusMode.quickFocus()
        manager.addFocusMode(mode)
        XCTAssertTrue(manager.focusModes.contains(where: { $0.id == mode.id }))

        // Extend and persist the edited mode.
        mode.extendSession(by: 10)
        manager.updateFocusMode(mode)
        let updated = manager.focusModes.first(where: { $0.id == mode.id })
        XCTAssertNotNil(updated, "The edited focus mode should be present after update.")

        manager.deleteFocusMode(mode)
        XCTAssertFalse(manager.focusModes.contains(where: { $0.id == mode.id }), "The focus mode should be removed after deletion.")
    }

    func testHasCompletedOnboardingFlag() {
        let manager = DataManager.shared
        manager.hasCompletedOnboarding = false
        XCTAssertFalse(manager.hasCompletedOnboarding)
        manager.hasCompletedOnboarding = true
        XCTAssertTrue(manager.hasCompletedOnboarding)
    }
}

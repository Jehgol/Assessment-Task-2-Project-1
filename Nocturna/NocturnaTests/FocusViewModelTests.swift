import XCTest
@testable import Nocturna

/// Verifies the lifecycle of a focus session started from `FocusViewModel`.
final class FocusViewModelTests: XCTestCase {

    func testStartExtendAndStopFocus() {
        // This test starts a short session, extends it, and then stops it.
        let vm = FocusViewModel()
        vm.selectedAppsToBlock = ["Instagram", "Twitter"]

        vm.startCustomFocus(duration: 1) // 1 minute

        XCTAssertTrue(vm.isActive, "A session should be active after starting.")
        XCTAssertNotNil(vm.activeFocusMode, "An active focus mode is expected when a session is active.")

        // Extend by 1 minute and assert the duration increases.
        vm.extendFocus(by: 1)
        if let mode = vm.activeFocusMode {
            XCTAssertGreaterThanOrEqual(mode.duration, 120, "Duration should increase by approximately 60 seconds.")
        }

        vm.stopFocus()
        XCTAssertFalse(vm.isActive, "No session should be active after stopping.")
        XCTAssertNil(vm.activeFocusMode, "The active focus mode should be cleared after stopping.")
    }
}

import XCTest
@testable import Nocturna

/// Ensures onboarding validation enforces a minimum sleep duration.
final class OnboardingViewModelTests: XCTestCase {

    func testValidateSleepScheduleRejectsTooShort() {
        let vm = OnboardingViewModel()
        var comps = DateComponents()
        comps.hour = 22; comps.minute = 0
        vm.bedtime = Calendar.current.date(from: comps)!
        comps.hour = 1; comps.minute = 0
        vm.wakeTime = Calendar.current.date(from: comps)!

        XCTAssertFalse(vm.validateSleepSchedule(), "Validation should fail when sleep is shorter than the minimum threshold.")
        XCTAssertNotNil(vm.errorMessage, "An error message should be presented on invalid input.")
    }

    func testValidateSleepScheduleAcceptsFourHoursOrMore() {
        let vm = OnboardingViewModel()
        var comps = DateComponents()
        comps.hour = 22; comps.minute = 0
        vm.bedtime = Calendar.current.date(from: comps)!
        comps.hour = 2; comps.minute = 30
        vm.wakeTime = Calendar.current.date(from: comps)!

        XCTAssertTrue(vm.validateSleepSchedule(), "Validation should pass when the window is four hours or longer.")
        XCTAssertNil(vm.errorMessage, "The error message should be cleared on success.")
    }
}

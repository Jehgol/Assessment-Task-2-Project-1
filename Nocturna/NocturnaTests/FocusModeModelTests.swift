import XCTest
@testable import Nocturna

/// Verifies focus mode preset shapes and simple mutating helpers.
final class FocusModeModelTests: XCTestCase {

    func testPresetsHaveExpectedDurations() {
        let pomodoro = FocusMode.pomodoro()
        let deepWork = FocusMode.deepWork()
        let quick = FocusMode.quickFocus()

        XCTAssertEqual(Int(pomodoro.duration/60), 25, "Pomodoro should default to 25 minutes.")
        XCTAssertEqual(Int(deepWork.duration/60), 90, "Deep Work should default to 90 minutes.")
        XCTAssertEqual(Int(quick.duration/60), 15, "Quick Focus should default to 15 minutes.")
    }

    func testExtendAndBreak() {
        var mode = FocusMode.quickFocus()
        let original = mode.duration
        mode.extendSession(by: 5)
        XCTAssertEqual(mode.duration, original + 300, accuracy: 0.1, "Extending should add seconds to duration.")
        // A break should not crash; formal notification assertions are outside this lightweight unit test.
        mode.takeBreak(minutes: 1)
    }

    func testCodableRoundTrip() throws {
        let mode = FocusMode(name: "Custom", duration: 1800)
        let data = try JSONEncoder().encode(mode)
        let decoded = try JSONDecoder().decode(FocusMode.self, from: data)
        XCTAssertEqual(decoded.name, "Custom")
        XCTAssertEqual(Int(decoded.duration), 1800)
    }
}

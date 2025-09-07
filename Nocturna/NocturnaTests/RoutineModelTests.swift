import XCTest
@testable import Nocturna

/// Exercises `Routine` scheduling logic in isolation.
final class RoutineModelTests: XCTestCase {

    func testInitAndNextOccurrence() {
        let inFiveMinutes = Date().addingTimeInterval(5 * 60)
        let r = Routine(name: "Test", type: .custom, scheduledTime: inFiveMinutes, repeatDays: [])
        r.isActive = true // `nextOccurrence()` returns nil for inactive routines.

        let next = r.nextOccurrence()
        XCTAssertNotNil(next, "A next occurrence should be computable for an active routine.")
        if let next = next {
            XCTAssertGreaterThanOrEqual(next.timeIntervalSinceNow, 0, "The next occurrence should not be in the past.")
        }
    }

    func testCodableRoundTrip() throws {
        let r = Routine(name: "Morning", type: .morning, scheduledTime: Date(), repeatDays: [])
        let data = try JSONEncoder().encode(r)
        let decoded = try JSONDecoder().decode(Routine.self, from: data)
        XCTAssertEqual(decoded.name, r.name)
        XCTAssertEqual(decoded.type, r.type)
    }
}

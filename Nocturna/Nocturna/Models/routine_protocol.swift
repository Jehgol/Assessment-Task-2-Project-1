/**
 Summary
 -------
 Protocols that define shared behavior across task-like domain types. These include basic lifecycle, scheduling,
 and notification capabilities.
 
 Motivation
 ----------
 Protocol-oriented composition avoids deep inheritance hierarchies and keeps types small and testable.
 */
import Foundation

// MARK: - Protocol-Oriented Design for Routines

/// Base protocol for all routine types
protocol RoutineProtocol {
    var id: UUID { get }
    var name: String { get set }
    var isActive: Bool { get set }
    var createdAt: Date { get }
    var triggerTime: Date? { get set }
    
    func activate()
    func deactivate()
    func schedule()
}

/// Protocol for schedulable items
protocol Schedulable {
    var scheduledTime: Date { get set }
    var repeatDays: Set<Weekday> { get set }
    var isRecurring: Bool { get }
    
    /// Computes and returns the next time this routine should fire if it is active; returns nil when inactive or not schedulable.
    func nextOccurrence() -> Date?
}

/// Protocol for items that can send notifications
protocol Notifiable {
    var notificationIdentifier: String { get }
    var notificationTitle: String { get }
    var notificationBody: String { get }
    
    /// Schedules a one-off local notification at the specified date.
    func scheduleNotification()
    func cancelNotification()
}

/// Protocol for trackable activities
protocol Trackable {
    var startTime: Date? { get set }
    var endTime: Date? { get set }
    
    func startTracking()
    func stopTracking()
}

// MARK: - Supporting Types

/// Type documentation.
enum Weekday: Int, CaseIterable, Codable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
    
    var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }
}

/// Domain model representing a schedulable routine with activation state and repeat rules.
enum RoutineType: String, Codable, CaseIterable {
    case morning = "Morning"
    case bedtime = "Bedtime"
    case focus = "Focus"
    case custom = "Custom"
    
    var icon: String {
        switch self {
        case .morning: return "sun.max.fill"
        case .bedtime: return "moon.fill"
        case .focus: return "target"
        case .custom: return "star.fill"
        }
    }
}
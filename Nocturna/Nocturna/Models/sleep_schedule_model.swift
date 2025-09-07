/**
 Summary
 -------
 Model describing bedtime, wake time, and weekday enablement. It can compute the nominal sleep duration and
 integrates with local notifications for reminders.
 
 Responsibilities
 ----------------
 - Stores the schedule and whether it is enabled.
 - Provides convenience methods to enable/disable reminders.
 */
import Foundation

// MARK: - Sleep Schedule Model

/// Domain model holding bedtime/wake time and weekday enablement with convenience helpers.
class SleepSchedule: ObservableObject, Codable {
    @Published var bedtime: Date
    @Published var wakeTime: Date
    @Published var isEnabled: Bool
    @Published var preBedRoutineMinutes: Int
    @Published var activeDays: Set<Weekday>
    
    // Computed properties
    var sleepDuration: TimeInterval {
        let calendar = Calendar.current
        let bedComponents = calendar.dateComponents([.hour, .minute], from: bedtime)
        let wakeComponents = calendar.dateComponents([.hour, .minute], from: wakeTime)
        
        guard let bedHour = bedComponents.hour,
              let bedMinute = bedComponents.minute,
              let wakeHour = wakeComponents.hour,
              let wakeMinute = wakeComponents.minute else { return 0 }
        
        let bedMinutes = bedHour * 60 + bedMinute
        let wakeMinutes = wakeHour * 60 + wakeMinute
        
        if wakeMinutes > bedMinutes {
            return TimeInterval((wakeMinutes - bedMinutes) * 60)
        } else {
            return TimeInterval(((24 * 60 - bedMinutes) + wakeMinutes) * 60)
        }
    }
    
    var preBedRoutineTime: Date {
        return bedtime.addingTimeInterval(-TimeInterval(preBedRoutineMinutes * 60))
    }
    
    var sleepQualityEstimate: SleepQuality {
        let hours = sleepDuration / 3600
        if hours >= 7 && hours <= 9 {
            return .good
        } else if hours >= 6 && hours < 7 {
            return .fair
        } else {
            return .poor
        }
    }
    
    // MARK: - Initialization
    
    init(bedtime: Date = Date(), wakeTime: Date = Date(), preBedRoutineMinutes: Int = 30) {
        self.bedtime = bedtime
        self.wakeTime = wakeTime
        self.isEnabled = false
        self.preBedRoutineMinutes = preBedRoutineMinutes
        self.activeDays = Set(Weekday.allCases) // Active all days by default
    }
    
    // MARK: - Methods
    
    /// Enables the schedule and registers any required reminders.
    func enable() {
        isEnabled = true
        scheduleNotifications()
    }
    
    /// Disables the schedule and cancels any related reminders.
    func disable() {
        isEnabled = false
        cancelNotifications()
    }
    
    /// Schedules a one-off local notification at the specified date.
    func scheduleNotifications() {
        guard isEnabled else { return }
        
        // Schedule bedtime reminder
        NotificationManager.shared.scheduleDailyNotification(
            title: "Bedtime Approaching 🌙",
            body: "Your pre-bed routine starts in \(preBedRoutineMinutes) minutes",
            time: preBedRoutineTime,
            identifier: "bedtime_reminder"
        )
        
        // Schedule wake-up notification
        NotificationManager.shared.scheduleDailyNotification(
            title: "Good Morning! ☀️",
            body: "Time to start your day with energy",
            time: wakeTime,
            identifier: "wakeup_reminder"
        )
    }
    
    /// Cancels a previously scheduled notification with the given identifier.
    func cancelNotifications() {
        NotificationManager.shared.cancelNotification(identifier: "bedtime_reminder")
        NotificationManager.shared.cancelNotification(identifier: "wakeup_reminder")
    }
    
    // MARK: - Codable
    
    /// Type documentation.
    enum CodingKeys: String, CodingKey {
        case bedtime, wakeTime, isEnabled, preBedRoutineMinutes, activeDays
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        bedtime = try container.decode(Date.self, forKey: .bedtime)
        wakeTime = try container.decode(Date.self, forKey: .wakeTime)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        preBedRoutineMinutes = try container.decode(Int.self, forKey: .preBedRoutineMinutes)
        activeDays = try container.decode(Set<Weekday>.self, forKey: .activeDays)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(bedtime, forKey: .bedtime)
        try container.encode(wakeTime, forKey: .wakeTime)
        try container.encode(isEnabled, forKey: .isEnabled)
        try container.encode(preBedRoutineMinutes, forKey: .preBedRoutineMinutes)
        try container.encode(activeDays, forKey: .activeDays)
    }
}

// MARK: - Supporting Types

/// Domain model holding bedtime/wake time and weekday enablement with convenience helpers.
enum SleepQuality {
    case good
    case fair
    case poor
    
    var color: String {
        switch self {
        case .good: return "green"
        case .fair: return "yellow"
        case .poor: return "red"
        }
    }
    
    var message: String {
        switch self {
        case .good: return "Great sleep schedule!"
        case .fair: return "Could use more rest"
        case .poor: return "Consider adjusting your schedule"
        }
    }
}
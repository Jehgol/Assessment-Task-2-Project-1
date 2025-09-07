/**
 Summary
 -------
 Model representing a schedulable routine (e.g., Morning, Bedtime, or a custom routine).
 
 Responsibilities
 ----------------
 - Captures the target time and repeat days.
 - Tracks whether the routine is active.
 - Computes the next occurrence to support notifications and UI.
 */
import Foundation

// MARK: - Base Routine Class

/// Domain model representing a schedulable routine with activation state and repeat rules.
class Routine: RoutineProtocol, Schedulable, Notifiable, Codable, ObservableObject, Identifiable {
    let id: UUID
    @Published var name: String
    @Published var isActive: Bool
    let createdAt: Date
    @Published var triggerTime: Date?
    
    // Schedulable properties
    @Published var scheduledTime: Date
    @Published var repeatDays: Set<Weekday>
    
    // Routine specific properties
    @Published var type: RoutineType
    @Published var actions: [RoutineAction]
    
    // Computed properties
    var isRecurring: Bool {
        return !repeatDays.isEmpty
    }
    
    var notificationIdentifier: String {
        return "routine_\(id.uuidString)"
    }
    
    var notificationTitle: String {
        switch type {
        case .morning:
            return "Good Morning! ☀️"
        case .bedtime:
            return "Time to Wind Down 🌙"
        case .focus:
            return "Focus Mode Starting 🎯"
        case .custom:
            return name
        }
    }
    
    var notificationBody: String {
        switch type {
        case .morning:
            return "Your morning routine is starting. Let's make today great!"
        case .bedtime:
            return "Your bedtime routine begins now. Time to prepare for restful sleep."
        case .focus:
            return "Entering focus mode. Distractions will be minimized."
        case .custom:
            return "Your \(name) routine is starting now."
        }
    }
    
    // MARK: - Initialization
    
    init(name: String, type: RoutineType, scheduledTime: Date = Date(), repeatDays: Set<Weekday> = []) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.isActive = false
        self.createdAt = Date()
        self.triggerTime = nil
        self.scheduledTime = scheduledTime
        self.repeatDays = repeatDays
        self.actions = []
    }
    
    // MARK: - Protocol Methods
    
    func activate() {
        isActive = true
        schedule()
        scheduleNotification()
    }
    
    func deactivate() {
        isActive = false
        cancelNotification()
    }
    
    func schedule() {
        guard isActive else { return }
        triggerTime = nextOccurrence()
    }
    
    /// Computes and returns the next time this routine should fire if it is active; returns nil when inactive or not schedulable.
    func nextOccurrence() -> Date? {
        guard isActive else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        
        if repeatDays.isEmpty {
            // One-time routine
            return scheduledTime > now ? scheduledTime : nil
        } else {
            // Recurring routine
            var nextDate: Date?
            
            for dayOffset in 0..<7 {
                guard let testDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
                let weekday = calendar.component(.weekday, from: testDate)
                
                if let day = Weekday(rawValue: weekday), repeatDays.contains(day) {
                    var components = calendar.dateComponents([.year, .month, .day], from: testDate)
                    let timeComponents = calendar.dateComponents([.hour, .minute], from: scheduledTime)
                    components.hour = timeComponents.hour
                    components.minute = timeComponents.minute
                    
                    if let candidateDate = calendar.date(from: components), candidateDate > now {
                        nextDate = candidateDate
                        break
                    }
                }
            }
            
            return nextDate
        }
    }
    
    /// Schedules a one-off local notification at the specified date.
    func scheduleNotification() {
        NotificationManager.shared.scheduleRoutineNotification(for: self)
    }
    
    /// Cancels a previously scheduled notification with the given identifier.
    func cancelNotification() {
        NotificationManager.shared.cancelNotification(identifier: notificationIdentifier)
    }
    
    // MARK: - Codable
    
    /// Type documentation.
    enum CodingKeys: String, CodingKey {
        case id, name, isActive, createdAt, triggerTime
        case scheduledTime, repeatDays, type, actions
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        triggerTime = try container.decodeIfPresent(Date.self, forKey: .triggerTime)
        scheduledTime = try container.decode(Date.self, forKey: .scheduledTime)
        repeatDays = try container.decode(Set<Weekday>.self, forKey: .repeatDays)
        type = try container.decode(RoutineType.self, forKey: .type)
        actions = try container.decode([RoutineAction].self, forKey: .actions)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(triggerTime, forKey: .triggerTime)
        try container.encode(scheduledTime, forKey: .scheduledTime)
        try container.encode(repeatDays, forKey: .repeatDays)
        try container.encode(type, forKey: .type)
        try container.encode(actions, forKey: .actions)
    }
}

// MARK: - Routine Action

/// Domain model representing a schedulable routine with activation state and repeat rules.
struct RoutineAction: Codable, Identifiable {
    let id = UUID()
    var name: String
    var icon: String
    var duration: TimeInterval?
    
    static let presets: [RoutineAction] = [
        RoutineAction(name: "Dim Lights", icon: "lightbulb.fill", duration: nil),
        RoutineAction(name: "Block Social Media", icon: "apps.iphone", duration: 3600),
        RoutineAction(name: "Play Calming Music", icon: "music.note", duration: nil),
        RoutineAction(name: "Set Phone to Silent", icon: "speaker.slash.fill", duration: nil),
        RoutineAction(name: "Start Meditation", icon: "brain.head.profile", duration: 600)
    ]
}

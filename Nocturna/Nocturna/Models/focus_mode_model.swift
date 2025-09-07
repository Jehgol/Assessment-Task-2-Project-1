/**
 Summary
 -------
 Model representing a time-bounded focus session (e.g., Pomodoro, Deep Work, or a custom duration).
 
 Responsibilities
 ----------------
 - Stores the session's configuration (name, duration, optional break interval).
 - Tracks start/end times and derives remaining time and progress.
 - Provides helpers to extend a session or insert short breaks.
 */
import Foundation

// MARK: - Focus Mode Model

/// Domain model describing a time-bounded focus session with derived progress and remaining time.
class FocusMode: RoutineProtocol, Trackable, ObservableObject, Codable, Identifiable {
    let id: UUID
    @Published var name: String
    @Published var isActive: Bool
    let createdAt: Date
    @Published var triggerTime: Date?
    
    // Focus specific properties
    @Published var duration: TimeInterval
    @Published var blockedApps: Set<String>
    @Published var allowedContacts: Set<String>
    @Published var breakInterval: TimeInterval?
    
    // Trackable properties
    @Published var startTime: Date?
    @Published var endTime: Date?
    
    // Session tracking
    @Published var sessionsCompleted: Int = 0
    @Published var totalFocusTime: TimeInterval = 0
    
    // Computed properties
    var remainingTime: TimeInterval? {
        guard isActive, let startTime = startTime else { return nil }
        let elapsed = Date().timeIntervalSince(startTime)
        return max(0, duration - elapsed)
    }
    
    var progress: Double {
        guard isActive, let startTime = startTime else { return 0 }
        let elapsed = Date().timeIntervalSince(startTime)
        return min(1.0, elapsed / duration)
    }
    
    // MARK: - Initialization
    
    init(name: String = "Focus Session", duration: TimeInterval = 3600) {
        self.id = UUID()
        self.name = name
        self.duration = duration
        self.isActive = false
        self.createdAt = Date()
        self.triggerTime = nil
        self.blockedApps = Set(FocusMode.defaultBlockedApps)
        self.allowedContacts = []
        self.breakInterval = nil
    }
    
    // MARK: - Protocol Methods
    
    func activate() {
        isActive = true
        startTracking()
        scheduleEndNotification()
        NotificationManager.shared.sendNotification(
            title: "Focus Mode Active 🎯",
            body: "You're now in focus mode for \(Int(duration/60)) minutes",
            identifier: "focus_start_\(id.uuidString)"
        )
    }
    
    func deactivate() {
        stopTracking()
        isActive = false
        NotificationManager.shared.cancelNotification(identifier: "focus_end_\(id.uuidString)")
    }
    
    func schedule() {
        // Focus modes are typically started manually
        triggerTime = Date()
    }
    
    func startTracking() {
        startTime = Date()
        endTime = nil
    }
    
    func stopTracking() {
        endTime = Date()
        if let start = startTime, let end = endTime {
            let sessionDuration = end.timeIntervalSince(start)
            totalFocusTime += sessionDuration
            sessionsCompleted += 1
        }
    }
    
    // MARK: - Focus Methods
    
    /// Increases the session's duration by the specified number of minutes.
    func extendSession(by minutes: Int) {
        duration += TimeInterval(minutes * 60)
        if isActive {
            scheduleEndNotification()
        }
    }
    
    /// Schedules a short break during the session and posts a reminder to resume.
    func takeBreak(minutes: Int = 5) {
        guard isActive else { return }
        
        // Pause the focus session
        let resumeTime = Date().addingTimeInterval(TimeInterval(minutes * 60))
        
        NotificationManager.shared.scheduleNotification(
            title: "Break Time Over ⏰",
            body: "Ready to get back to focus?",
            date: resumeTime,
            identifier: "focus_break_\(id.uuidString)"
        )
    }
    
    private func scheduleEndNotification() {
        guard let startTime = startTime else { return }
        let endTime = startTime.addingTimeInterval(duration)
        
        NotificationManager.shared.scheduleNotification(
            title: "Focus Session Complete! 🎉",
            body: "Great job! You focused for \(Int(duration/60)) minutes",
            date: endTime,
            identifier: "focus_end_\(id.uuidString)"
        )
    }
    
    // MARK: - App Blocking
    
    func addBlockedApp(_ appName: String) {
        blockedApps.insert(appName)
    }
    
    func removeBlockedApp(_ appName: String) {
        blockedApps.remove(appName)
    }
    
    static let defaultBlockedApps = [
        "Instagram",
        "Facebook",
        "Twitter",
        "TikTok",
        "YouTube",
        "Snapchat",
        "Reddit"
    ]
    
    // MARK: - Presets
    
    static func pomodoro() -> FocusMode {
        let mode = FocusMode(name: "Pomodoro", duration: 25 * 60)
        mode.breakInterval = 5 * 60
        return mode
    }
    
    static func deepWork() -> FocusMode {
        return FocusMode(name: "Deep Work", duration: 90 * 60)
    }
    
    static func quickFocus() -> FocusMode {
        return FocusMode(name: "Quick Focus", duration: 15 * 60)
    }
    
    // MARK: - Codable
    
    /// Type documentation.
    enum CodingKeys: String, CodingKey {
        case id, name, isActive, createdAt, triggerTime
        case duration, blockedApps, allowedContacts, breakInterval
        case startTime, endTime, sessionsCompleted, totalFocusTime
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        isActive = try container.decode(Bool.self, forKey: .isActive)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        triggerTime = try container.decodeIfPresent(Date.self, forKey: .triggerTime)
        duration = try container.decode(TimeInterval.self, forKey: .duration)
        blockedApps = try container.decode(Set<String>.self, forKey: .blockedApps)
        allowedContacts = try container.decode(Set<String>.self, forKey: .allowedContacts)
        breakInterval = try container.decodeIfPresent(TimeInterval.self, forKey: .breakInterval)
        startTime = try container.decodeIfPresent(Date.self, forKey: .startTime)
        endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
        sessionsCompleted = try container.decode(Int.self, forKey: .sessionsCompleted)
        totalFocusTime = try container.decode(TimeInterval.self, forKey: .totalFocusTime)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(isActive, forKey: .isActive)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(triggerTime, forKey: .triggerTime)
        try container.encode(duration, forKey: .duration)
        try container.encode(blockedApps, forKey: .blockedApps)
        try container.encode(allowedContacts, forKey: .allowedContacts)
        try container.encodeIfPresent(breakInterval, forKey: .breakInterval)
        try container.encodeIfPresent(startTime, forKey: .startTime)
        try container.encodeIfPresent(endTime, forKey: .endTime)
        try container.encode(sessionsCompleted, forKey: .sessionsCompleted)
        try container.encode(totalFocusTime, forKey: .totalFocusTime)
    }
}

/**
 Summary
 -------
 View model that drives the Focus experience. It coordinates session lifecycle, progress updates, and persistence.
 
 Collaborators
 -------------
 - `DataManager` for persistence of session templates or state.
 - `NotificationManager` for completion and reminder notifications.
 */
import Foundation
import SwiftUI
import Combine

// MARK: - Focus View Model

/// View model responsible for coordinating UI state and user intents for `Focus`.
class FocusViewModel: ObservableObject {
    @Published var activeFocusMode: FocusMode?
    @Published var selectedDuration: Int = 25 // Minutes
    @Published var selectedAppsToBlock: Set<String> = []
    @Published var isCustomizing = false
    @Published var showingStats = false
    @Published var focusProgress: Double = 0
    @Published var remainingTimeText = "00:00"
    
    private let dataManager = DataManager.shared
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // Preset durations in minutes
    let presetDurations = [15, 25, 45, 60, 90, 120]
    
    // Available apps to block
    let availableApps = [
        "Instagram",
        "Facebook",
        "Twitter",
        "TikTok",
        "YouTube",
        "Snapchat",
        "Reddit",
        "WhatsApp",
        "Telegram",
        "Discord",
        "Netflix",
        "Games"
    ]
    
    // MARK: - Computed Properties
    
    var isActive: Bool {
        activeFocusMode?.isActive ?? false
    }
    
    var focusModes: [FocusMode] {
        dataManager.focusModes
    }
    
    var totalFocusTimeToday: String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let totalSeconds = focusModes.reduce(0) { total, mode in
            guard let startTime = mode.startTime,
                  calendar.isDate(startTime, inSameDayAs: today) else { return total }
            
            if let endTime = mode.endTime {
                return total + endTime.timeIntervalSince(startTime)
            } else if mode.isActive {
                return total + Date().timeIntervalSince(startTime)
            }
            return total
        }
        
        return formatTime(totalSeconds)
    }
    
    var sessionsCompletedToday: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return focusModes.reduce(0) { count, mode in
            guard let endTime = mode.endTime,
                  calendar.isDate(endTime, inSameDayAs: today) else { return count }
            return count + 1
        }
    }
    
    var currentStreak: Int {
        // Calculate consecutive days with at least one focus session
        let calendar = Calendar.current
        var streak = 0
        var checkDate = Date()
        
        for _ in 0..<30 { // Check last 30 days
            let dayStart = calendar.startOfDay(for: checkDate)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let hasSession = focusModes.contains { mode in
                guard let startTime = mode.startTime else { return false }
                return startTime >= dayStart && startTime < dayEnd
            }
            
            if hasSession {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        
        return streak
    }
    
    // MARK: - Initialization
    
    init() {
        setupBindings()
        checkActiveFocusMode()
    }
    
    deinit {
        stopTimer()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        dataManager.$focusModes
            .sink { [weak self] _ in
                self?.checkActiveFocusMode()
            }
            .store(in: &cancellables)
    }
    
    private func checkActiveFocusMode() {
        activeFocusMode = focusModes.first { $0.isActive }
        if activeFocusMode != nil {
            startTimer()
        } else {
            stopTimer()
        }
    }
    
    // MARK: - Timer Management
    
    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
        updateProgress()
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func updateProgress() {
        guard let mode = activeFocusMode else {
            focusProgress = 0
            remainingTimeText = "00:00"
            return
        }
        
        if let remaining = mode.remainingTime {
            focusProgress = mode.progress
            remainingTimeText = formatTime(remaining)
            
            // Check if session is complete
            if remaining <= 0 {
                completeSession()
            }
        }
    }
    
    // MARK: - Focus Actions
    
    func startFocus() {
        startCustomFocus(duration: selectedDuration)
    }
    
    /// Starts a new focus session with the specified duration in minutes. Updates UI state and persists the session as needed.
    func startCustomFocus(duration: Int) {
        // Create new focus mode
        let focusMode = FocusMode(
            name: "Focus Session",
            duration: TimeInterval(duration * 60)
        )
        
        // Apply selected apps to block
        focusMode.blockedApps = selectedAppsToBlock
        
        // Save and activate
        dataManager.addFocusMode(focusMode)
        activateFocusMode(focusMode)
    }
    
    func startPresetFocus(_ preset: FocusPreset) {
        let focusMode: FocusMode
        
        switch preset {
        case .pomodoro:
            focusMode = FocusMode.pomodoro()
        case .deepWork:
            focusMode = FocusMode.deepWork()
        case .quickFocus:
            focusMode = FocusMode.quickFocus()
        }
        
        dataManager.addFocusMode(focusMode)
        activateFocusMode(focusMode)
    }
    
    private func activateFocusMode(_ mode: FocusMode) {
        // Deactivate any active mode
        if let active = activeFocusMode {
            active.deactivate()
            dataManager.updateFocusMode(active)
        }
        
        // Activate new mode
        mode.activate()
        activeFocusMode = mode
        dataManager.updateFocusMode(mode)
        startTimer()
    }
    
    /// Inserts a short break without discarding the session and schedules a reminder to resume.
    func pauseFocus() {
        guard let mode = activeFocusMode else { return }
        
        // Take a 5-minute break
        mode.takeBreak(minutes: 5)
        
        // Send notification
        NotificationManager.shared.sendNotification(
            title: "Taking a Break ☕",
            body: "Your 5-minute break has started",
            identifier: "focus_break"
        )
    }
    
    /// Ends the active focus session and resets the view-model state.
    func stopFocus() {
        guard let mode = activeFocusMode else { return }
        
        mode.deactivate()
        dataManager.updateFocusMode(mode)
        activeFocusMode = nil
        stopTimer()
        
        // Reset UI
        focusProgress = 0
        remainingTimeText = "00:00"
    }
    
    /// Adds the specified number of minutes to the active focus session and refreshes derived values.
    func extendFocus(by minutes: Int) {
        guard let mode = activeFocusMode else { return }
        
        mode.extendSession(by: minutes)
        dataManager.updateFocusMode(mode)
        
        NotificationManager.shared.sendNotification(
            title: "Focus Extended 🎯",
            body: "Added \(minutes) minutes to your session",
            identifier: "focus_extended"
        )
    }
    
    private func completeSession() {
        guard let mode = activeFocusMode else { return }
        
        // Send completion notification
        NotificationManager.shared.sendNotification(
            title: "Focus Session Complete! 🎉",
            body: "Great job! You focused for \(Int(mode.duration/60)) minutes",
            identifier: "focus_complete"
        )
        
        // Stop the session
        stopFocus()
    }
    
    // MARK: - App Blocking
    
    func toggleAppBlock(_ appName: String) {
        if selectedAppsToBlock.contains(appName) {
            selectedAppsToBlock.remove(appName)
        } else {
            selectedAppsToBlock.insert(appName)
        }
    }
    
    func selectAllApps() {
        selectedAppsToBlock = Set(availableApps)
    }
    
    func deselectAllApps() {
        selectedAppsToBlock = []
    }
    
    // MARK: - Utilities
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let remainingSeconds = Int(seconds) % 60
        
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return String(format: "%d:%02d:%02d", hours, remainingMinutes, remainingSeconds)
        } else {
            return String(format: "%02d:%02d", minutes, remainingSeconds)
        }
    }
    
    // MARK: - Statistics
    
    func getWeeklyStats() -> [DayStats] {
        let calendar = Calendar.current
        var stats: [DayStats] = []
        
        for dayOffset in (0..<7).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date()) else { continue }
            
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let dayFocusTime = focusModes.reduce(0) { total, mode in
                guard let startTime = mode.startTime,
                      startTime >= dayStart && startTime < dayEnd else { return total }
                
                if let endTime = mode.endTime {
                    return total + endTime.timeIntervalSince(startTime)
                } else if mode.isActive && calendar.isDateInToday(startTime) {
                    return total + Date().timeIntervalSince(startTime)
                }
                return total
            }
            
            stats.append(DayStats(
                date: date,
                focusMinutes: Int(dayFocusTime / 60)
            ))
        }
        
        return stats
    }
}

// MARK: - Supporting Types

/// Type documentation.
enum FocusPreset {
    case pomodoro
    case deepWork
    case quickFocus
    
    var name: String {
        switch self {
        case .pomodoro: return "Pomodoro"
        case .deepWork: return "Deep Work"
        case .quickFocus: return "Quick Focus"
        }
    }
    
    var duration: Int {
        switch self {
        case .pomodoro: return 25
        case .deepWork: return 90
        case .quickFocus: return 15
        }
    }
    
    var description: String {
        switch self {
        case .pomodoro: return "25 min work, 5 min break"
        case .deepWork: return "90 min uninterrupted focus"
        case .quickFocus: return "15 min quick session"
        }
    }
    
    var icon: String {
        switch self {
        case .pomodoro: return "timer"
        case .deepWork: return "brain.head.profile"
        case .quickFocus: return "bolt.fill"
        }
    }
}

/// Type documentation.
struct DayStats {
    let date: Date
    let focusMinutes: Int
    
    var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
}
/**
 Summary
 -------
 View model that powers the Home screen. It exposes greeting text, next scheduled event, and quick actions.
 
 Collaborators
 -------------
 - `DataManager` for reading/writing routines and session state.
 - `NotificationManager` to reflect authorization/scheduling status as needed.
 */
import Foundation
import SwiftUI
import Combine

// MARK: - Home View Model

/// View model responsible for coordinating UI state and user intents for `Home`.
class HomeViewModel: ObservableObject {
    @Published var currentTime = Date()
    @Published var activeRoutine: Routine?
    @Published var activeFocusMode: FocusMode?
    @Published var upcomingRoutine: Routine?
    @Published var isEditingRoutines = false
    @Published var selectedTab: HomeTab = .routines
    
    private let dataManager = DataManager.shared
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: currentTime)
        switch hour {
        case 0..<12:
            return "Good Morning"
        case 12..<17:
            return "Good Afternoon"
        case 17..<21:
            return "Good Evening"
        default:
            return "Good Night"
        }
    }
    
    var currentTimeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: currentTime)
    }
    
    var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: currentTime)
    }
    
    var sleepSchedule: SleepSchedule {
        dataManager.sleepSchedule
    }
    
    var routines: [Routine] {
        dataManager.routines
    }
    
    var focusModes: [FocusMode] {
        dataManager.focusModes
    }
    
    var hasActiveSession: Bool {
        activeRoutine != nil || activeFocusMode != nil
    }
    
    var nextScheduledEvent: String? {
        if let upcoming = upcomingRoutine,
           let triggerTime = upcoming.triggerTime {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "\(upcoming.name) at \(formatter.string(from: triggerTime))"
        }
        
        if sleepSchedule.isEnabled {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            
            let now = Date()
            let bedtime = sleepSchedule.preBedRoutineTime
            let wakeTime = sleepSchedule.wakeTime
            
            // Check which is next
            if bedtime > now {
                return "Bedtime routine at \(formatter.string(from: bedtime))"
            } else if wakeTime > now {
                return "Wake up at \(formatter.string(from: wakeTime))"
            }
        }
        
        return nil
    }
    
    // MARK: - Initialization
    
    init() {
        setupTimer()
        checkActiveRoutines()
        findUpcomingRoutine()
        observeDataChanges()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - Setup
    
    private func setupTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            self.currentTime = Date()
            self.checkRoutineTriggers()
        }
    }
    
    private func observeDataChanges() {
        dataManager.$routines
            .sink { [weak self] _ in
                self?.checkActiveRoutines()
                self?.findUpcomingRoutine()
            }
            .store(in: &cancellables)
        
        dataManager.$focusModes
            .sink { [weak self] _ in
                self?.checkActiveFocusMode()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Routine Management
    
    private func checkActiveRoutines() {
        activeRoutine = routines.first { $0.isActive }
    }
    
    private func checkActiveFocusMode() {
        activeFocusMode = focusModes.first { $0.isActive }
    }
    
    private func findUpcomingRoutine() {
        let now = Date()
        let upcoming = routines
            .compactMap { routine -> (Routine, Date)? in
                guard let triggerTime = routine.nextOccurrence() else { return nil }
                return (routine, triggerTime)
            }
            .filter { $0.1 > now }
            .sorted { $0.1 < $1.1 }
            .first
        
        upcomingRoutine = upcoming?.0
    }
    
    private func checkRoutineTriggers() {
        let now = Date()
        
        for routine in routines where routine.isActive {
            if let triggerTime = routine.triggerTime,
               triggerTime <= now,
               triggerTime.timeIntervalSince(now) > -60 { // Within last minute
                triggerRoutine(routine)
            }
        }
    }
    
    private func triggerRoutine(_ routine: Routine) {
        // Mark as triggered
        routine.triggerTime = nil
        routine.schedule() // Schedule next occurrence
        
        // Send notification
        NotificationManager.shared.sendNotification(
            title: routine.notificationTitle,
            body: routine.notificationBody,
            identifier: "routine_triggered_\(routine.id.uuidString)"
        )
        
        // Update active routine
        activeRoutine = routine
    }
    
    // MARK: - Actions
    
    func toggleRoutine(_ routine: Routine) {
        if routine.isActive {
            routine.deactivate()
            if activeRoutine?.id == routine.id {
                activeRoutine = nil
            }
        } else {
            routine.activate()
        }
        dataManager.updateRoutine(routine)
    }
    
    /// Removes the given routine from the collection and schedules persistence.
    func deleteRoutine(_ routine: Routine) {
        routine.deactivate()
        dataManager.deleteRoutine(routine)
        if activeRoutine?.id == routine.id {
            activeRoutine = nil
        }
    }
    
    func startFocusMode(_ mode: FocusMode) {
        // Deactivate any active focus mode
        focusModes.forEach { $0.deactivate() }
        
        // Activate selected mode
        mode.activate()
        activeFocusMode = mode
        dataManager.updateFocusMode(mode)
    }
    
    /// Ends the active focus session and resets the view-model state.
    func stopFocusMode() {
        activeFocusMode?.deactivate()
        if let mode = activeFocusMode {
            dataManager.updateFocusMode(mode)
        }
        activeFocusMode = nil
    }
    
    func toggleSleepSchedule() {
        if sleepSchedule.isEnabled {
            sleepSchedule.disable()
        } else {
            sleepSchedule.enable()
        }
    }
    
    func createQuickFocus(duration: Int) {
        let focusMode = FocusMode(
            name: "Quick Focus",
            duration: TimeInterval(duration * 60)
        )
        dataManager.addFocusMode(focusMode)
        startFocusMode(focusMode)
    }
    
    // MARK: - Statistics
    
    func getTodayStats() -> DailyStats {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Count completed routines today
        let completedRoutines = routines.filter { routine in
            guard let triggerTime = routine.triggerTime else { return false }
            return calendar.isDate(triggerTime, inSameDayAs: today)
        }.count
        
        // Calculate focus time today
        let todayFocusTime = focusModes.reduce(0) { total, mode in
            guard let startTime = mode.startTime,
                  calendar.isDate(startTime, inSameDayAs: today) else { return total }
            
            if let endTime = mode.endTime {
                return total + endTime.timeIntervalSince(startTime)
            } else if mode.isActive {
                return total + Date().timeIntervalSince(startTime)
            }
            return total
        }
        
        return DailyStats(
            completedRoutines: completedRoutines,
            focusMinutes: Int(todayFocusTime / 60),
            sleepQuality: sleepSchedule.sleepQualityEstimate
        )
    }
}

// MARK: - Supporting Types

/// Type documentation.
enum HomeTab {
    case routines
    case focus
    case calendar
    
    var icon: String {
        switch self {
        case .routines: return "clock.fill"
        case .focus: return "target"
        case .calendar: return "calendar"
        }
    }
    
    var title: String {
        switch self {
        case .routines: return "Routines"
        case .focus: return "Focus"
        case .calendar: return "Calendar"
        }
    }
}

/// Type documentation.
struct DailyStats {
    let completedRoutines: Int
    let focusMinutes: Int
    let sleepQuality: SleepQuality
}

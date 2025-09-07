/**
 Summary
 -------
 View model that manages the onboarding step machine: bedtime, wake time, routine selection, and completion.
 
 Responsibilities
 ----------------
 - Validates the sleep window and surfaces user-friendly error messages.
 - Seeds reasonable defaults after successful completion.
 */
import Foundation
import SwiftUI

// MARK: - Onboarding View Model

/// View model responsible for coordinating UI state and user intents for `Onboarding`.
class OnboardingViewModel: ObservableObject {
    @Published var currentStep: OnboardingStep = .welcome
    @Published var bedtime = Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
    @Published var wakeTime = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    @Published var preBedRoutineMinutes = 30
    @Published var selectedRoutineTypes: Set<RoutineType> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let dataManager = DataManager.shared
    private let notificationManager = NotificationManager.shared
    
    // MARK: - Computed Properties
    
    var canProceed: Bool {
        switch currentStep {
        case .welcome:
            return true
        case .setBedtime, .setWakeTime:
            return true
        case .configureRoutines:
            return true // Can skip
        case .complete:
            return true
        }
    }
    
    var stepProgress: Double {
        let totalSteps = OnboardingStep.allCases.count
        let currentIndex = OnboardingStep.allCases.firstIndex(of: currentStep) ?? 0
        return Double(currentIndex + 1) / Double(totalSteps)
    }
    
    var sleepDurationText: String {
        let calendar = Calendar.current
        let bedComponents = calendar.dateComponents([.hour, .minute], from: bedtime)
        let wakeComponents = calendar.dateComponents([.hour, .minute], from: wakeTime)
        
        guard let bedHour = bedComponents.hour,
              let bedMinute = bedComponents.minute,
              let wakeHour = wakeComponents.hour,
              let wakeMinute = wakeComponents.minute else { return "0 hours" }
        
        let bedMinutes = bedHour * 60 + bedMinute
        let wakeMinutes = wakeHour * 60 + wakeMinute
        
        let totalMinutes: Int
        if wakeMinutes > bedMinutes {
            totalMinutes = wakeMinutes - bedMinutes
        } else {
            totalMinutes = (24 * 60 - bedMinutes) + wakeMinutes
        }
        
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        
        if minutes == 0 {
            return "\(hours) hours"
        } else {
            return "\(hours)h \(minutes)m"
        }
    }
    
    // MARK: - Navigation
    
    func nextStep() {
        guard canProceed else { return }
        
        switch currentStep {
        case .welcome:
            requestNotificationPermission()
            currentStep = .setBedtime
        case .setBedtime:
            saveBedtime()
            currentStep = .setWakeTime
        case .setWakeTime:
            saveWakeTime()
            currentStep = .configureRoutines
        case .configureRoutines:
            setupRoutines()
            currentStep = .complete
        case .complete:
            completeOnboarding()
        }
    }
    
    func previousStep() {
        switch currentStep {
        case .welcome:
            break
        case .setBedtime:
            currentStep = .welcome
        case .setWakeTime:
            currentStep = .setBedtime
        case .configureRoutines:
            currentStep = .setWakeTime
        case .complete:
            currentStep = .configureRoutines
        }
    }
    
    func skip() {
        // Skip directly to completion
        completeOnboarding()
    }
    
    // MARK: - Setup Methods
    
    private func requestNotificationPermission() {
        notificationManager.requestAuthorization()
    }
    
    private func saveBedtime() {
        dataManager.sleepSchedule.bedtime = bedtime
        dataManager.sleepSchedule.preBedRoutineMinutes = preBedRoutineMinutes
    }
    
    private func saveWakeTime() {
        dataManager.sleepSchedule.wakeTime = wakeTime
        dataManager.sleepSchedule.isEnabled = true
        dataManager.sleepSchedule.enable()
    }
    
    private func setupRoutines() {
        isLoading = true
        
        // Create selected routine types
        for type in selectedRoutineTypes {
            let routine = createRoutine(for: type)
            dataManager.addRoutine(routine)
        }
        
        // Create default focus modes if selected
        if selectedRoutineTypes.contains(.focus) {
            dataManager.addFocusMode(FocusMode.pomodoro())
            dataManager.addFocusMode(FocusMode.deepWork())
        }
        
        isLoading = false
    }
    
    private func createRoutine(for type: RoutineType) -> Routine {
        let routine: Routine
        
        switch type {
        case .morning:
            routine = Routine(
                name: "Morning Routine",
                type: .morning,
                scheduledTime: wakeTime,
                repeatDays: Set(Weekday.allCases)
            )
            routine.actions = [
                RoutineAction(name: "Open Curtains", icon: "sun.max.fill", duration: nil),
                RoutineAction(name: "Morning Playlist", icon: "music.note", duration: nil),
                RoutineAction(name: "Weather Check", icon: "cloud.sun.fill", duration: nil)
            ]
            
        case .bedtime:
            routine = Routine(
                name: "Bedtime Routine",
                type: .bedtime,
                scheduledTime: bedtime.addingTimeInterval(-TimeInterval(preBedRoutineMinutes * 60)),
                repeatDays: Set(Weekday.allCases)
            )
            routine.actions = [
                RoutineAction(name: "Dim Lights", icon: "lightbulb.fill", duration: nil),
                RoutineAction(name: "Block Social Media", icon: "apps.iphone", duration: nil),
                RoutineAction(name: "Enable Do Not Disturb", icon: "moon.fill", duration: nil)
            ]
            
        case .focus:
            routine = Routine(
                name: "Daily Focus",
                type: .focus,
                scheduledTime: Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()
            )
            routine.actions = [
                RoutineAction(name: "Block Distracting Apps", icon: "xmark.app.fill", duration: 3600),
                RoutineAction(name: "Silent Mode", icon: "speaker.slash.fill", duration: nil)
            ]
            
        case .custom:
            routine = Routine(name: "Custom Routine", type: .custom)
        }
        
        return routine
    }
    
    private func completeOnboarding() {
        dataManager.hasCompletedOnboarding = true
    }
    
    // MARK: - Validation
    
    /// Validates that bedtime and wake time yield at least a minimum duration (e.g., 4 hours). Returns true when valid and clears any error message; otherwise sets an error and returns false.
    func validateSleepSchedule() -> Bool {
        let calendar = Calendar.current
        let bedComponents = calendar.dateComponents([.hour, .minute], from: bedtime)
        let wakeComponents = calendar.dateComponents([.hour, .minute], from: wakeTime)
        
        guard let bedHour = bedComponents.hour,
              let wakeHour = wakeComponents.hour else { return false }
        
        // Ensure at least 4 hours of sleep
        let bedMinutes = bedHour * 60 + (bedComponents.minute ?? 0)
        let wakeMinutes = wakeHour * 60 + (wakeComponents.minute ?? 0)
        
        let sleepMinutes: Int
        if wakeMinutes > bedMinutes {
            sleepMinutes = wakeMinutes - bedMinutes
        } else {
            sleepMinutes = (24 * 60 - bedMinutes) + wakeMinutes
        }
        
        if sleepMinutes < 240 { // Less than 4 hours
            errorMessage = "Sleep duration should be at least 4 hours"
            return false
        }
        
        errorMessage = nil
        return true
    }
}

// MARK: - Onboarding Step

/// Type documentation.
enum OnboardingStep: CaseIterable {
    case welcome
    case setBedtime
    case setWakeTime
    case configureRoutines
    case complete
    
    var title: String {
        switch self {
        case .welcome:
            return "Welcome to Nocturna"
        case .setBedtime:
            return "Set Your Bedtime"
        case .setWakeTime:
            return "Set Your Wake Time"
        case .configureRoutines:
            return "Choose Your Routines"
        case .complete:
            return "You're All Set!"
        }
    }
    
    var description: String {
        switch self {
        case .welcome:
            return "Let's set up your sleep schedule and create healthy routines"
        case .setBedtime:
            return "When do you want to go to bed?"
        case .setWakeTime:
            return "When do you want to wake up?"
        case .configureRoutines:
            return "Select the routines you'd like to use"
        case .complete:
            return "Your personalized sleep journey begins now"
        }
    }
}
/**
 Summary
 -------
 Central repository for persisted app state (routines, focus modes, and settings). Persistence uses JSON files
 and `UserDefaults`, with debounced autosave to keep the UI responsive.
 
 Responsibilities
 ----------------
 - Loads state on launch and seeds defaults when needed.
 - Provides CRUD helpers for routines and focus modes.
 - Surfaces a flag indicating whether onboarding has been completed.
 */
import Foundation
import Combine

// MARK: - Data Manager

/// Service object that encapsulates system APIs and cross-cutting concerns for the app.
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    @Published var routines: [Routine] = []
    @Published var sleepSchedule: SleepSchedule
    @Published var focusModes: [FocusMode] = []
    @Published var hasCompletedOnboarding: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // File URLs
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    private var routinesURL: URL {
        documentsDirectory.appendingPathComponent("routines.json")
    }
    
    private var sleepScheduleURL: URL {
        documentsDirectory.appendingPathComponent("sleepSchedule.json")
    }
    
    private var focusModesURL: URL {
        documentsDirectory.appendingPathComponent("focusModes.json")
    }
    
    private var settingsURL: URL {
        documentsDirectory.appendingPathComponent("settings.json")
    }
    
    // MARK: - Initialization
    
    private init() {
        // Initialize with default sleep schedule
        self.sleepSchedule = SleepSchedule()
        
        // Load saved data
        loadAll()
        
        // Setup auto-save
        setupAutoSave()
    }
    
    // MARK: - Auto-Save Setup
    
    private func setupAutoSave() {
        // Auto-save routines
        $routines
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveRoutines()
            }
            .store(in: &cancellables)
        
        // Auto-save sleep schedule
        sleepSchedule.objectWillChange
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveSleepSchedule()
            }
            .store(in: &cancellables)
        
        // Auto-save focus modes
        $focusModes
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveFocusModes()
            }
            .store(in: &cancellables)
        
        // Auto-save settings
        $hasCompletedOnboarding
            .sink { [weak self] _ in
                self?.saveSettings()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Load Methods
    
    func loadAll() {
        loadRoutines()
        loadSleepSchedule()
        loadFocusModes()
        loadSettings()
    }
    
    private func loadRoutines() {
        do {
            let data = try Data(contentsOf: routinesURL)
            routines = try JSONDecoder().decode([Routine].self, from: data)
        } catch {
            print("Error loading routines: \(error)")
            // Create default routines if none exist
            createDefaultRoutines()
        }
    }
    
    private func loadSleepSchedule() {
        do {
            let data = try Data(contentsOf: sleepScheduleURL)
            sleepSchedule = try JSONDecoder().decode(SleepSchedule.self, from: data)
        } catch {
            print("Error loading sleep schedule: \(error)")
            sleepSchedule = SleepSchedule()
        }
    }
    
    private func loadFocusModes() {
        do {
            let data = try Data(contentsOf: focusModesURL)
            focusModes = try JSONDecoder().decode([FocusMode].self, from: data)
        } catch {
            print("Error loading focus modes: \(error)")
            // Create default focus modes if none exist
            createDefaultFocusModes()
        }
    }
    
    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: "settings") {
            do {
                let settings = try JSONDecoder().decode(Settings.self, from: data)
                hasCompletedOnboarding = settings.hasCompletedOnboarding
            } catch {
                print("Error loading settings: \(error)")
            }
        }
    }
    
    // MARK: - Save Methods
    
    private func saveRoutines() {
        do {
            let data = try JSONEncoder().encode(routines)
            try data.write(to: routinesURL)
        } catch {
            print("Error saving routines: \(error)")
        }
    }
    
    private func saveSleepSchedule() {
        do {
            let data = try JSONEncoder().encode(sleepSchedule)
            try data.write(to: sleepScheduleURL)
        } catch {
            print("Error saving sleep schedule: \(error)")
        }
    }
    
    private func saveFocusModes() {
        do {
            let data = try JSONEncoder().encode(focusModes)
            try data.write(to: focusModesURL)
        } catch {
            print("Error saving focus modes: \(error)")
        }
    }
    
    private func saveSettings() {
        let settings = Settings(hasCompletedOnboarding: hasCompletedOnboarding)
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: "settings")
        }
    }
    
    // MARK: - CRUD Operations
    
    // Routines
    /// Inserts a new routine into the collection and schedules persistence.
    func addRoutine(_ routine: Routine) {
        routines.append(routine)
    }
    
    /// Persists changes to an existing routine, if present in the collection.
    func updateRoutine(_ routine: Routine) {
        if let index = routines.firstIndex(where: { $0.id == routine.id }) {
            routines[index] = routine
        }
    }
    
    /// Removes the given routine from the collection and schedules persistence.
    func deleteRoutine(_ routine: Routine) {
        routines.removeAll { $0.id == routine.id }
    }
    
    // Focus Modes
    /// Inserts a new focus mode into the collection and schedules persistence.
    func addFocusMode(_ mode: FocusMode) {
        focusModes.append(mode)
    }
    
    /// Persists changes to an existing focus mode, if present in the collection.
    func updateFocusMode(_ mode: FocusMode) {
        if let index = focusModes.firstIndex(where: { $0.id == mode.id }) {
            focusModes[index] = mode
        }
    }
    
    /// Removes the given focus mode from the collection and schedules persistence.
    func deleteFocusMode(_ mode: FocusMode) {
        focusModes.removeAll { $0.id == mode.id }
    }
    
    // MARK: - Default Data
    
    private func createDefaultRoutines() {
        let morningRoutine = Routine(
            name: "Morning Routine",
            type: .morning,
            scheduledTime: Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date(),
            repeatDays: Set(Weekday.allCases)
        )
        morningRoutine.actions = [
            RoutineAction(name: "Open Curtains", icon: "sun.max.fill", duration: nil),
            RoutineAction(name: "Start Morning Playlist", icon: "music.note", duration: nil)
        ]
        
        let bedtimeRoutine = Routine(
            name: "Bedtime Routine",
            type: .bedtime,
            scheduledTime: Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date(),
            repeatDays: Set(Weekday.allCases)
        )
        bedtimeRoutine.actions = [
            RoutineAction(name: "Dim Lights", icon: "lightbulb.fill", duration: nil),
            RoutineAction(name: "Enable Do Not Disturb", icon: "moon.fill", duration: nil)
        ]
        
        routines = [morningRoutine, bedtimeRoutine]
    }
    
    private func createDefaultFocusModes() {
        focusModes = [
            FocusMode.pomodoro(),
            FocusMode.deepWork(),
            FocusMode.quickFocus()
        ]
    }
    
    // MARK: - Reset
    
    /// Clears all persisted state and restores sensible defaults. Intended for development/testing and a visible 'reset data' action.
    func resetAllData() {
        // Clear all data
        routines = []
        sleepSchedule = SleepSchedule()
        focusModes = []
        hasCompletedOnboarding = false
        
        // Delete files
        try? FileManager.default.removeItem(at: routinesURL)
        try? FileManager.default.removeItem(at: sleepScheduleURL)
        try? FileManager.default.removeItem(at: focusModesURL)
        UserDefaults.standard.removeObject(forKey: "settings")
        
        // Recreate defaults
        createDefaultRoutines()
        createDefaultFocusModes()
    }
}

// MARK: - Settings Model

/// Type documentation.
struct Settings: Codable {
    var hasCompletedOnboarding: Bool
}
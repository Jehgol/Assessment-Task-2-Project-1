/**
 Summary
 -------
 A collection of reusable SwiftUI components (cards, buttons, list rows, etc.) used across the app.
 
 Purpose
 -------
 To keep higher-level views simple by factoring presentational pieces into focused, reusable views.
 */
import SwiftUI

// MARK: - Settings View

/// SwiftUI View for the Settings screen. Binds to the corresponding view model.
struct SettingsView: View {
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    @Environment(\.presentationMode) var presentationMode
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.large) {
                        // Sleep Schedule Settings
                        sleepScheduleSection
                        
                        // Notifications
                        notificationsSection
                        
                        // Data Management
                        dataManagementSection
                        
                        // About
                        aboutSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Theme.Colors.primary)
                }
            }
        }
        .alert("Reset All Data?", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                dataManager.resetAllData()
            }
        } message: {
            Text("This will delete all your routines, focus sessions, and settings. This action cannot be undone.")
        }
    }
    
    private var sleepScheduleSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("Sleep Schedule")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.primaryText)
            
            VStack(spacing: Theme.Spacing.small) {
                // Bedtime
                HStack {
                    Image(systemName: "moon.fill")
                        .foregroundColor(Theme.Colors.bedtime)
                    Text("Bedtime")
                        .foregroundColor(Theme.Colors.primaryText)
                    Spacer()
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { dataManager.sleepSchedule.bedtime },
                            set: { dataManager.sleepSchedule.bedtime = $0 }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                }
                
                Divider()
                
                // Wake Time
                HStack {
                    Image(systemName: "sun.max.fill")
                        .foregroundColor(Theme.Colors.wakeTime)
                    Text("Wake Time")
                        .foregroundColor(Theme.Colors.primaryText)
                    Spacer()
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { dataManager.sleepSchedule.wakeTime },
                            set: { dataManager.sleepSchedule.wakeTime = $0 }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                }
                
                Divider()
                
                // Pre-bed Routine
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(Theme.Colors.primary)
                    Text("Pre-bed Routine")
                        .foregroundColor(Theme.Colors.primaryText)
                    Spacer()
                    Text("\(dataManager.sleepSchedule.preBedRoutineMinutes) min")
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }
            .padding()
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
        }
    }
    
    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("Notifications")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.primaryText)
            
            VStack(spacing: Theme.Spacing.small) {
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundColor(Theme.Colors.primary)
                    Text("Notifications Enabled")
                        .foregroundColor(Theme.Colors.primaryText)
                    Spacer()
                    Toggle("", isOn: $notificationManager.isAuthorized)
                        .disabled(true)
                        .tint(Theme.Colors.primary)
                }
                
                if !notificationManager.isAuthorized {
                    Button(action: {
                        notificationManager.requestAuthorization()
                    }) {
                        Text("Enable Notifications")
                            .font(Theme.Typography.callout)
                            .foregroundColor(Theme.Colors.primary)
                    }
                }
            }
            .padding()
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
        }
    }
    
    private var dataManagementSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("Data Management")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.primaryText)
            
            VStack(spacing: 0) {
                Button(action: { showingResetAlert = true }) {
                    HStack {
                        Image(systemName: "trash.fill")
                            .foregroundColor(Theme.Colors.error)
                        Text("Reset All Data")
                            .foregroundColor(Theme.Colors.error)
                        Spacer()
                    }
                    .padding()
                }
            }
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
        }
    }
    
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("About")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.primaryText)
            
            VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                HStack {
                    Text("Version")
                        .foregroundColor(Theme.Colors.secondaryText)
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(Theme.Colors.primaryText)
                }
                
                Divider()
                
                HStack {
                    Text("Developer")
                        .foregroundColor(Theme.Colors.secondaryText)
                    Spacer()
                    Text("Nocturna Team")
                        .foregroundColor(Theme.Colors.primaryText)
                }
            }
            .padding()
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
        }
    }
}

// MARK: - Add Routine View

/// SwiftUI View for the AddRoutine screen. Binds to the corresponding view model.
struct AddRoutineView: View {
    @StateObject private var dataManager = DataManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var routineName = ""
    @State private var routineType: RoutineType = .custom
    @State private var scheduledTime = Date()
    @State private var selectedDays: Set<Weekday> = []
    @State private var selectedActions: [RoutineAction] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.large) {
                        // Name Input
                        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                            Text("Routine Name")
                                .font(Theme.Typography.headline)
                                .foregroundColor(Theme.Colors.primaryText)
                            
                            TextField("Enter routine name", text: $routineName)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        // Type Selection
                        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                            Text("Type")
                                .font(Theme.Typography.headline)
                                .foregroundColor(Theme.Colors.primaryText)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Theme.Spacing.small) {
                                    ForEach(RoutineType.allCases, id: \.self) { type in
                                        TypeChip(
                                            type: type,
                                            isSelected: routineType == type
                                        ) {
                                            routineType = type
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Schedule Time
                        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                            Text("Schedule Time")
                                .font(Theme.Typography.headline)
                                .foregroundColor(Theme.Colors.primaryText)
                            
                            DatePicker(
                                "Time",
                                selection: $scheduledTime,
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                            .datePickerStyle(WheelDatePickerStyle())
                            .padding()
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(Theme.CornerRadius.medium)
                        }
                        
                        // Repeat Days
                        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                            Text("Repeat")
                                .font(Theme.Typography.headline)
                                .foregroundColor(Theme.Colors.primaryText)
                            
                            HStack(spacing: Theme.Spacing.xSmall) {
                                ForEach(Weekday.allCases, id: \.self) { day in
                                    DayChip(
                                        day: day,
                                        isSelected: selectedDays.contains(day)
                                    ) {
                                        if selectedDays.contains(day) {
                                            selectedDays.remove(day)
                                        } else {
                                            selectedDays.insert(day)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Actions
                        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                            Text("Actions")
                                .font(Theme.Typography.headline)
                                .foregroundColor(Theme.Colors.primaryText)
                            
                            VStack(spacing: Theme.Spacing.small) {
                                ForEach(RoutineAction.presets) { action in
                                    ActionSelectionRow(
                                        action: action,
                                        isSelected: selectedActions.contains(where: { $0.id == action.id })
                                    ) {
                                        if let index = selectedActions.firstIndex(where: { $0.id == action.id }) {
                                            selectedActions.remove(at: index)
                                        } else {
                                            selectedActions.append(action)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("New Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Theme.Colors.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveRoutine()
                    }
                    .foregroundColor(Theme.Colors.primary)
                    .disabled(routineName.isEmpty)
                }
            }
        }
    }
    
    private func saveRoutine() {
        let routine = Routine(
            name: routineName,
            type: routineType,
            scheduledTime: scheduledTime,
            repeatDays: selectedDays
        )
        routine.actions = selectedActions
        dataManager.addRoutine(routine)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Edit Routine View

/// SwiftUI View for the EditRoutine screen. Binds to the corresponding view model.
struct EditRoutineView: View {
    let routine: Routine
    @StateObject private var dataManager = DataManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var routineName = ""
    @State private var scheduledTime = Date()
    @State private var selectedDays: Set<Weekday> = []
    @State private var selectedActions: [RoutineAction] = []
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.large) {
                        // Name Input
                        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                            Text("Routine Name")
                                .font(Theme.Typography.headline)
                                .foregroundColor(Theme.Colors.primaryText)
                            
                            TextField("Enter routine name", text: $routineName)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        // Schedule Time
                        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                            Text("Schedule Time")
                                .font(Theme.Typography.headline)
                                .foregroundColor(Theme.Colors.primaryText)
                            
                            DatePicker(
                                "Time",
                                selection: $scheduledTime,
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                            .datePickerStyle(WheelDatePickerStyle())
                            .padding()
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(Theme.CornerRadius.medium)
                        }
                        
                        // Repeat Days
                        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                            Text("Repeat")
                                .font(Theme.Typography.headline)
                                .foregroundColor(Theme.Colors.primaryText)
                            
                            HStack(spacing: Theme.Spacing.xSmall) {
                                ForEach(Weekday.allCases, id: \.self) { day in
                                    DayChip(
                                        day: day,
                                        isSelected: selectedDays.contains(day)
                                    ) {
                                        if selectedDays.contains(day) {
                                            selectedDays.remove(day)
                                        } else {
                                            selectedDays.insert(day)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Actions
                        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                            Text("Actions")
                                .font(Theme.Typography.headline)
                                .foregroundColor(Theme.Colors.primaryText)
                            
                            VStack(spacing: Theme.Spacing.small) {
                                ForEach(RoutineAction.presets) { action in
                                    ActionSelectionRow(
                                        action: action,
                                        isSelected: selectedActions.contains(where: { $0.id == action.id })
                                    ) {
                                        if let index = selectedActions.firstIndex(where: { $0.id == action.id }) {
                                            selectedActions.remove(at: index)
                                        } else {
                                            selectedActions.append(action)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Theme.Colors.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        updateRoutine()
                    }
                    .foregroundColor(Theme.Colors.primary)
                }
            }
        }
        .onAppear {
            routineName = routine.name
            scheduledTime = routine.scheduledTime
            selectedDays = routine.repeatDays
            selectedActions = routine.actions
        }
    }
    
    /// Persists changes to an existing routine, if present in the collection.
    private func updateRoutine() {
        routine.name = routineName
        routine.scheduledTime = scheduledTime
        routine.repeatDays = selectedDays
        routine.actions = selectedActions
        dataManager.updateRoutine(routine)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Supporting Components

/// Type documentation.
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
            .foregroundColor(Theme.Colors.primaryText)
    }
}

/// Type documentation.
struct TypeChip: View {
    let type: RoutineType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: type.icon)
                Text(type.rawValue)
            }
            .font(Theme.Typography.callout)
            .foregroundColor(isSelected ? .white : Theme.Colors.primaryText)
            .padding(.horizontal, Theme.Spacing.medium)
            .padding(.vertical, Theme.Spacing.small)
            .background(
                isSelected ? Theme.Colors.primary : Theme.Colors.cardBackground
            )
            .cornerRadius(Theme.CornerRadius.small)
        }
    }
}

/// Type documentation.
struct DayChip: View {
    let day: Weekday
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(day.shortName)
                .font(Theme.Typography.caption)
                .foregroundColor(isSelected ? .white : Theme.Colors.primaryText)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(isSelected ? Theme.Colors.primary : Theme.Colors.cardBackground)
                )
        }
    }
}

/// Type documentation.
struct ActionSelectionRow: View {
    let action: RoutineAction
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: action.icon)
                    .foregroundColor(Theme.Colors.primary)
                
                Text(action.name)
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.primaryText)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? Theme.Colors.primary : Theme.Colors.tertiaryText)
            }
            .padding()
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.small)
        }
    }
}
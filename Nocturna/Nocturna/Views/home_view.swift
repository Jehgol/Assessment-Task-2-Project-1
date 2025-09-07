/**
 Summary
 -------
 The Home screen that summarizes routines, the current day, and quick actions.
 
 MVVM Role
 ---------
 View layer that binds to `HomeViewModel` for greeting, next event, and active-session awareness.
 
 Key Responsibilities
 --------------------
 - Displays routine cards and quick actions.
 - Reflects whether a focus session is currently active.
 */
import SwiftUI

// MARK: - Home View

/// SwiftUI View for the Home screen. Binds to the corresponding view model.
struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showingSettings = false
    @State private var showingAddRoutine = false
    @State private var selectedRoutine: Routine?
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Theme.Colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                        .padding()
                    
                    // Main Content
                    ScrollView {
                        VStack(spacing: Theme.Spacing.large) {
                            // Current Status Card
                            currentStatusCard
                            
                            // Quick Actions
                            if !viewModel.hasActiveSession {
                                quickActionsSection
                            }
                            
                            // Active Session
                            if let activeRoutine = viewModel.activeRoutine {
                                ActiveRoutineCard(routine: activeRoutine, viewModel: viewModel)
                            }
                            
                            if let activeFocus = viewModel.activeFocusMode {
                                ActiveFocusCard(focusMode: activeFocus, viewModel: viewModel)
                            }
                            
                            // Routines Section
                            routinesSection
                            
                            // Today's Stats
                            todayStatsCard
                        }
                        .padding()
                    }
                    
                    // Tab Bar
                    CustomTabBar(selectedTab: $viewModel.selectedTab)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingAddRoutine) {
                AddRoutineView()
            }
            .sheet(item: $selectedRoutine) { routine in
                EditRoutineView(routine: routine)
            }
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.greeting)
                    .font(Theme.Typography.title2)
                    .foregroundColor(Theme.Colors.primaryText)
                
                Text(viewModel.currentDateString)
                    .font(Theme.Typography.callout)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            
            Spacer()
            
            Button(action: { showingSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(Theme.Colors.primary)
            }
        }
    }
    
    // MARK: - Current Status Card
    
    private var currentStatusCard: some View {
        VStack(spacing: Theme.Spacing.medium) {
            // Current Time
            Text(viewModel.currentTimeString)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(Theme.Colors.primaryText)
            
            // Status
            if viewModel.hasActiveSession {
                HStack {
                    Circle()
                        .fill(Theme.Colors.success)
                        .frame(width: 8, height: 8)
                    
                    Text("Active Session")
                        .font(Theme.Typography.callout)
                        .foregroundColor(Theme.Colors.success)
                }
            } else if let nextEvent = viewModel.nextScheduledEvent {
                Text(nextEvent)
                    .font(Theme.Typography.callout)
                    .foregroundColor(Theme.Colors.secondaryText)
            } else {
                Text("No Active Routine")
                    .font(Theme.Typography.callout)
                    .foregroundColor(Theme.Colors.tertiaryText)
            }
            
            // Sleep Schedule Toggle
            HStack {
                Image(systemName: viewModel.sleepSchedule.isEnabled ? "moon.fill" : "moon")
                    .foregroundColor(Theme.Colors.primary)
                
                Text("Sleep Schedule")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.primaryText)
                
                Spacer()
                
                Toggle("", isOn: Binding(
                    get: { viewModel.sleepSchedule.isEnabled },
                    set: { _ in viewModel.toggleSleepSchedule() }
                ))
                .labelsHidden()
                .tint(Theme.Colors.primary)
            }
            .padding()
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(Theme.CornerRadius.medium)
        }
        .padding()
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.large)
    }
    
    // MARK: - Quick Actions Section
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text("Quick Actions")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.primaryText)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.small) {
                    QuickActionButton(
                        icon: "target",
                        title: "15 min",
                        color: Theme.Colors.focusActive
                    ) {
                        viewModel.createQuickFocus(duration: 15)
                    }
                    
                    QuickActionButton(
                        icon: "timer",
                        title: "25 min",
                        color: Theme.Colors.primary,
                        action: {
                            viewModel.createQuickFocus(duration: 25)
                        }
                    )
                    
                    QuickActionButton(
                        icon: "brain.head.profile",
                        title: "45 min",
                        color: Theme.Colors.accent,
                        action: {
                            viewModel.createQuickFocus(duration: 45)
                        }
                    )
                    
                    NavigationLink(destination: FocusView()) {
                        QuickActionButton(
                            icon: "plus.circle.fill",
                            title: "Custom",
                            color: Theme.Colors.secondary
                        ) { }
                    }
                }
            }
        }
    }
    
    // MARK: - Routines Section
    
    private var routinesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            HStack {
                Text("Routines")
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.primaryText)
                
                Spacer()
                
                Button(action: { showingAddRoutine = true }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Theme.Colors.primary)
                }
            }
            
            if viewModel.routines.isEmpty {
                EmptyRoutineCard()
            } else {
                ForEach(viewModel.routines) { routine in
                    RoutineCard(routine: routine) {
                        viewModel.toggleRoutine(routine)
                    } onEdit: {
                        selectedRoutine = routine
                    } onDelete: {
                        viewModel.deleteRoutine(routine)
                    }
                }
            }
        }
    }
    
    // MARK: - Today Stats Card
    
    private var todayStatsCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("Today's Progress")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.primaryText)
            
            let stats = viewModel.getTodayStats()
            
            HStack(spacing: Theme.Spacing.medium) {
                StatItem(
                    icon: "checkmark.circle.fill",
                    value: "\(stats.completedRoutines)",
                    label: "Routines",
                    color: Theme.Colors.success
                )
                
                StatItem(
                    icon: "target",
                    value: "\(stats.focusMinutes)m",
                    label: "Focus",
                    color: Theme.Colors.primary
                )
                
                StatItem(
                    icon: "bed.double.fill",
                    value: stats.sleepQuality.message,
                    label: "Sleep",
                    color: Color(stats.sleepQuality.color)
                )
            }
        }
        .padding()
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.large)
    }
}

// MARK: - Supporting Views

/// Type documentation.
struct ActiveRoutineCard: View {
    let routine: Routine
    let viewModel: HomeViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            HStack {
                Image(systemName: routine.type.icon)
                    .foregroundColor(Theme.Colors.primary)
                
                Text("\(routine.name) Active")
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.primaryText)
                
                Spacer()
                
                Button("End") {
                    viewModel.toggleRoutine(routine)
                }
                .font(Theme.Typography.callout)
                .foregroundColor(Theme.Colors.error)
            }
            
            // Actions
            if !routine.actions.isEmpty {
                VStack(alignment: .leading, spacing: Theme.Spacing.xSmall) {
                    ForEach(routine.actions) { action in
                        HStack {
                            Image(systemName: action.icon)
                                .foregroundColor(Theme.Colors.secondary)
                                .frame(width: 20)
                            
                            Text(action.name)
                                .font(Theme.Typography.callout)
                                .foregroundColor(Theme.Colors.secondaryText)
                            
                            Spacer()
                        }
                    }
                }
            }
        }
        .padding()
        .background(Theme.Gradients.primary.opacity(0.2))
        .cornerRadius(Theme.CornerRadius.large)
    }
}

/// Type documentation.
struct ActiveFocusCard: View {
    let focusMode: FocusMode
    let viewModel: HomeViewModel
    @State private var progress: Double = 0
    @State private var remainingTime = "00:00"
    
    var body: some View {
        VStack(spacing: Theme.Spacing.medium) {
            HStack {
                Image(systemName: "target")
                    .foregroundColor(Theme.Colors.focusActive)
                
                Text("Focus Mode Active")
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.primaryText)
                
                Spacer()
                
                Button("Stop") {
                    viewModel.stopFocusMode()
                }
                .font(Theme.Typography.callout)
                .foregroundColor(Theme.Colors.error)
            }
            
            // Progress Ring
            ZStack {
                Circle()
                    .stroke(Theme.Colors.secondaryBackground, lineWidth: 8)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Theme.Gradients.focus, lineWidth: 8)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
                
                Text(remainingTime)
                    .font(Theme.Typography.title2)
                    .foregroundColor(Theme.Colors.primaryText)
            }
            .frame(height: 120)
            .onAppear {
                updateProgress()
            }
            .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
                updateProgress()
            }
        }
        .padding()
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.large)
    }
    
    private func updateProgress() {
        progress = focusMode.progress
        if let remaining = focusMode.remainingTime {
            let minutes = Int(remaining) / 60
            let seconds = Int(remaining) % 60
            remainingTime = String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

/// Domain model representing a schedulable routine with activation state and repeat rules.
struct RoutineCard: View {
    let routine: Routine
    let onToggle: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: routine.type.icon)
                .font(.title2)
                .foregroundColor(routine.isActive ? Theme.Colors.primary : Theme.Colors.secondaryText)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(routine.name)
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.primaryText)
                
                Text(DateFormatter.localizedString(from: routine.scheduledTime, dateStyle: .none, timeStyle: .short))
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)


            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { routine.isActive },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
            .tint(Theme.Colors.primary)
        }
        .padding()
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.medium)
        .contextMenu {
            Button(action: onEdit) {
                HStack {
                    Image(systemName: "pencil")
                    Text("Edit")
                }
            }
            
            Button(role: .destructive, action: onDelete) {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete")
                }
            }
        }
    }
}

/// Type documentation.
struct EmptyRoutineCard: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.medium) {
            Image(systemName: "clock.badge.plus")
                .font(.largeTitle)
                .foregroundColor(Theme.Colors.tertiaryText)
            
            Text("No routines yet")
                .font(Theme.Typography.callout)
                .foregroundColor(Theme.Colors.secondaryText)
            
            Text("Add a routine to get started")
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.tertiaryText)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.medium)
    }
}

/// Type documentation.
struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.xSmall) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(Theme.Typography.caption)
                    .foregroundColor(.white)
            }
            .frame(width: 80, height: 80)
            .background(
                LinearGradient(
                    colors: [color, color.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(Theme.CornerRadius.medium)
        }
    }
}

/// Type documentation.
struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xSmall) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.primaryText)
            
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(Theme.CornerRadius.small)
    }
}

/// Type documentation.
struct CustomTabBar: View {
    @Binding var selectedTab: HomeTab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach([HomeTab.routines, HomeTab.focus, HomeTab.calendar], id: \.self) { tab in
                Button(action: { selectedTab = tab }) {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.title2)
                        
                        Text(tab.title)
                            .font(Theme.Typography.caption2)
                    }
                    .foregroundColor(selectedTab == tab ? Theme.Colors.primary : Theme.Colors.tertiaryText)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, Theme.Spacing.small)
        .background(Theme.Colors.secondaryBackground)
    }
}

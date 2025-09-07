/**
 Summary
 -------
 The Focus screen where a user starts, extends, pauses, and stops a focus session.
 
 MVVM Role
 ---------
 View layer that binds to `FocusViewModel` for session state, remaining time, and progress.
 
 Key Responsibilities
 --------------------
 - Offers preset durations and a custom duration entry.
 - Displays a progress indicator and time remaining.
 - Exposes controls to extend, pause, or end the current session.
 */
import SwiftUI

// MARK: - Focus View

/// SwiftUI View for the Focus screen. Binds to the corresponding view model.
struct FocusView: View {
    @StateObject private var viewModel = FocusViewModel()
    @State private var showingAppSelection = false
    @State private var showingStats = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // Background
            Theme.Colors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: Theme.Spacing.large) {
                    // Header
                    headerView
                    
                    if viewModel.isActive {
                        // Active Focus Session
                        activeFocusView
                    } else {
                        // Focus Setup
                        focusSetupView
                    }
                    
                    // Stats
                    focusStatsCard
                }
                .padding()
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingAppSelection) {
            AppSelectionView(viewModel: viewModel)
        }
        .sheet(isPresented: $showingStats) {
            FocusStatsView(viewModel: viewModel)
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(Theme.Colors.primary)
            }
            
            Spacer()
            
            Text("Focus Mode")
                .font(Theme.Typography.title2)
                .foregroundColor(Theme.Colors.primaryText)
            
            Spacer()
            
            Button(action: { showingStats = true }) {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(Theme.Colors.primary)
            }
        }
        .padding(.bottom)
    }
    
    // MARK: - Active Focus View
    
    private var activeFocusView: some View {
        VStack(spacing: Theme.Spacing.large) {
            // Focus Ring
            ZStack {
                // Background Ring
                Circle()
                    .stroke(Theme.Colors.secondaryBackground, lineWidth: 12)
                
                // Progress Ring
                Circle()
                    .trim(from: 0, to: viewModel.focusProgress)
                    .stroke(
                        LinearGradient(
                            colors: [Theme.Colors.focusActive, Theme.Colors.primary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: viewModel.focusProgress)
                
                // Center Content
                VStack(spacing: Theme.Spacing.small) {
                    Text(viewModel.remainingTimeText)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(Theme.Colors.primaryText)
                    
                    Text("Remaining")
                        .font(Theme.Typography.callout)
                        .foregroundColor(Theme.Colors.secondaryText)
                }
            }
            .frame(width: 250, height: 250)
            
            // Active Session Info
            if let mode = viewModel.activeFocusMode {
                VStack(spacing: Theme.Spacing.small) {
                    Text(mode.name)
                        .font(Theme.Typography.title3)
                        .foregroundColor(Theme.Colors.primaryText)
                    
                    if !mode.blockedApps.isEmpty {
                        Text("\(mode.blockedApps.count) apps blocked")
                            .font(Theme.Typography.callout)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                }
            }
            
            // Control Buttons
            HStack(spacing: Theme.Spacing.medium) {
                Button(action: { viewModel.pauseFocus() }) {
                    HStack {
                        Image(systemName: "pause.fill")
                        Text("Pause")
                    }
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.primary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.Colors.cardBackground)
                    .cornerRadius(Theme.CornerRadius.medium)
                }
                
                Button(action: { viewModel.extendFocus(by: 10) }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("+10 min")
                    }
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.accent)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.Colors.cardBackground)
                    .cornerRadius(Theme.CornerRadius.medium)
                }
            }
            
            Button(action: { viewModel.stopFocus() }) {
                Text("End Session")
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.error)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                            .stroke(Theme.Colors.error, lineWidth: 2)
                    )
            }
        }
    }
    
    // MARK: - Focus Setup View
    
    private var focusSetupView: some View {
        VStack(spacing: Theme.Spacing.large) {
            // Preset Options
            VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                Text("Quick Start")
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.primaryText)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Theme.Spacing.small) {
                        ForEach([FocusPreset.pomodoro, FocusPreset.deepWork, FocusPreset.quickFocus], id: \.name) { preset in
                            PresetCard(preset: preset) {
                                viewModel.startPresetFocus(preset)
                            }
                        }
                    }
                }
            }
            
            // Custom Duration
            VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                Text("Custom Session")
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.primaryText)
                
                // Duration Selector
                VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                    HStack {
                        Text("Duration")
                            .font(Theme.Typography.body)
                            .foregroundColor(Theme.Colors.secondaryText)
                        
                        Spacer()
                        
                        Text("\(viewModel.selectedDuration) minutes")
                            .font(Theme.Typography.headline)
                            .foregroundColor(Theme.Colors.primary)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Theme.Spacing.xSmall) {
                            ForEach(viewModel.presetDurations, id: \.self) { duration in
                                DurationChip(
                                    duration: duration,
                                    isSelected: viewModel.selectedDuration == duration
                                ) {
                                    viewModel.selectedDuration = duration
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Theme.Colors.cardBackground)
                .cornerRadius(Theme.CornerRadius.medium)
                
                // App Blocking
                Button(action: { showingAppSelection = true }) {
                    HStack {
                        Image(systemName: "apps.iphone")
                            .foregroundColor(Theme.Colors.primary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Block Distracting Apps")
                                .font(Theme.Typography.body)
                                .foregroundColor(Theme.Colors.primaryText)
                            
                            if viewModel.selectedAppsToBlock.isEmpty {
                                Text("No apps selected")
                                    .font(Theme.Typography.caption)
                                    .foregroundColor(Theme.Colors.tertiaryText)
                            } else {
                                Text("\(viewModel.selectedAppsToBlock.count) apps selected")
                                    .font(Theme.Typography.caption)
                                    .foregroundColor(Theme.Colors.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(Theme.Colors.tertiaryText)
                    }
                    .padding()
                    .background(Theme.Colors.cardBackground)
                    .cornerRadius(Theme.CornerRadius.medium)
                }
                
                // Start Button
                Button(action: { viewModel.startFocus() }) {
                    Text("Start Focus Session")
                        .primaryButtonStyle()
                }
            }
        }
    }
    
    // MARK: - Stats Card
    
    private var focusStatsCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("Today's Focus")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.primaryText)
            
            HStack(spacing: Theme.Spacing.medium) {
                FocusStatItem(
                    value: viewModel.totalFocusTimeToday,
                    label: "Total Time",
                    icon: "clock.fill"
                )
                
                FocusStatItem(
                    value: "\(viewModel.sessionsCompletedToday)",
                    label: "Sessions",
                    icon: "checkmark.circle.fill"
                )
                
                FocusStatItem(
                    value: "\(viewModel.currentStreak)",
                    label: "Day Streak",
                    icon: "flame.fill"
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
struct PresetCard: View {
    let preset: FocusPreset
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: Theme.Spacing.small) {
                Image(systemName: preset.icon)
                    .font(.largeTitle)
                    .foregroundColor(Theme.Colors.primary)
                
                Text(preset.name)
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.primaryText)
                
                Text(preset.description)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 120, height: 140)
            .padding()
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
        }
    }
}

/// Type documentation.
struct DurationChip: View {
    let duration: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("\(duration)")
                .font(Theme.Typography.headline)
                .foregroundColor(isSelected ? .white : Theme.Colors.primaryText)
                .padding(.horizontal, Theme.Spacing.medium)
                .padding(.vertical, Theme.Spacing.small)
                .background(
                    isSelected ? Theme.Colors.primary : Theme.Colors.secondaryBackground
                )
                .cornerRadius(Theme.CornerRadius.small)
        }
    }
}

/// Type documentation.
struct FocusStatItem: View {
    let value: String
    let label: String
    let icon: String
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xSmall) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Theme.Colors.primary)
            
            Text(value)
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.primaryText)
            
            Text(label)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - App Selection View

/// SwiftUI View for the AppSelection screen. Binds to the corresponding view model.
struct AppSelectionView: View {
    @ObservedObject var viewModel: FocusViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                VStack {
                    // Header Actions
                    HStack {
                        Button("Select All") {
                            viewModel.selectAllApps()
                        }
                        .foregroundColor(Theme.Colors.primary)
                        
                        Spacer()
                        
                        Button("Deselect All") {
                            viewModel.deselectAllApps()
                        }
                        .foregroundColor(Theme.Colors.secondary)
                    }
                    .padding()
                    
                    // Apps List
                    ScrollView {
                        VStack(spacing: Theme.Spacing.small) {
                            ForEach(viewModel.availableApps, id: \.self) { app in
                                AppSelectionRow(
                                    appName: app,
                                    isSelected: viewModel.selectedAppsToBlock.contains(app)
                                ) {
                                    viewModel.toggleAppBlock(app)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Block Apps")
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
    }
}

/// Type documentation.
struct AppSelectionRow: View {
    let appName: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(appName)
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

// MARK: - Focus Stats View

/// SwiftUI View for the FocusStats screen. Binds to the corresponding view model.
struct FocusStatsView: View {
    @ObservedObject var viewModel: FocusViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: Theme.Spacing.large) {
                        // Weekly Chart
                        WeeklyFocusChart(stats: viewModel.getWeeklyStats())
                        
                        // Total Stats
                        VStack(spacing: Theme.Spacing.medium) {
                            Text("All Time Stats")
                                .font(Theme.Typography.headline)
                                .foregroundColor(Theme.Colors.primaryText)
                            
                            HStack(spacing: Theme.Spacing.medium) {
                                StatCard(
                                    title: "Total Sessions",
                                    value: "\(viewModel.focusModes.reduce(0) { $0 + $1.sessionsCompleted })",
                                    icon: "target"
                                )
                                
                                StatCard(
                                    title: "Total Hours",
                                    value: String(format: "%.1f", viewModel.focusModes.reduce(0) { $0 + $1.totalFocusTime } / 3600),
                                    icon: "clock.fill"
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Focus Statistics")
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
    }
}

/// Type documentation.
struct WeeklyFocusChart: View {
    let stats: [DayStats]
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("Weekly Focus Time")
                .font(Theme.Typography.headline)
                .foregroundColor(Theme.Colors.primaryText)
            
            HStack(alignment: .bottom, spacing: Theme.Spacing.xSmall) {
                ForEach(stats, id: \.date) { day in
                    VStack {
                        Text("\(day.focusMinutes)")
                            .font(Theme.Typography.caption2)
                            .foregroundColor(Theme.Colors.secondaryText)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Theme.Colors.primary)
                            .frame(width: 40, height: CGFloat(day.focusMinutes) * 2)
                        
                        Text(day.dayName)
                            .font(Theme.Typography.caption)
                            .foregroundColor(Theme.Colors.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(Theme.CornerRadius.medium)
        }
        .padding()
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.large)
    }
}

/// Type documentation.
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: Theme.Spacing.small) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Theme.Colors.primary)
            
            Text(value)
                .font(Theme.Typography.title2)
                .foregroundColor(Theme.Colors.primaryText)
            
            Text(title)
                .font(Theme.Typography.caption)
                .foregroundColor(Theme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.medium)
    }
}
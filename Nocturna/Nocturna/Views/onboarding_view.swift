/**
 Summary
 -------
 The Onboarding flow that captures bedtime, wake time, and routine preferences.
 
 MVVM Role
 ---------
 View layer bound to `OnboardingViewModel` for step transitions, validation, and seeding of defaults.
 
 Key Responsibilities
 --------------------
 - Guides the user through initial configuration.
 - Validates a minimum sleep duration and surfaces errors inline.
 - Requests notification permissions when appropriate.
 */
import SwiftUI

// MARK: - Onboarding View

/// SwiftUI View for the Onboarding screen. Binds to the corresponding view model.
struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var showSkipAlert = false
    
    var body: some View {
        ZStack {
            // Background
            Theme.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Progress Bar
                ProgressView(value: viewModel.stepProgress)
                    .tint(Theme.Colors.primary)
                    .padding(.horizontal)
                    .padding(.top)
                
                // Content
                ScrollView {
                    VStack(spacing: Theme.Spacing.large) {
                        // Step Content
                        stepContent
                            .padding(.horizontal)
                            .padding(.top, Theme.Spacing.xLarge)
                        
                        Spacer(minLength: Theme.Spacing.xxLarge)
                    }
                }
                
                // Bottom Actions
                VStack(spacing: Theme.Spacing.medium) {
                    if viewModel.currentStep != .complete {
                        // Skip Button (only for configureRoutines)
                        if viewModel.currentStep == .configureRoutines {
                            Button("Skip for now") {
                                showSkipAlert = true
                            }
                            .foregroundColor(Theme.Colors.secondaryText)
                            .font(Theme.Typography.callout)
                        }
                        
                        // Navigation Buttons
                        HStack(spacing: Theme.Spacing.medium) {
                            if viewModel.currentStep != .welcome {
                                Button(action: viewModel.previousStep) {
                                    Image(systemName: "chevron.left")
                                        .font(.title2)
                                        .foregroundColor(Theme.Colors.primary)
                                        .frame(width: 60, height: 50)
                                        .background(Theme.Colors.cardBackground)
                                        .cornerRadius(Theme.CornerRadius.medium)
                                }
                            }
                            
                            Button(action: viewModel.nextStep) {
                                Text(viewModel.currentStep == .complete ? "Get Started" : "Continue")
                                    .primaryButtonStyle()
                            }
                            .disabled(!viewModel.canProceed)
                        }
                    } else {
                        Button(action: viewModel.nextStep) {
                            Text("Get Started")
                                .primaryButtonStyle()
                        }
                    }
                }
                .padding()
                .background(Theme.Colors.secondaryBackground)
            }
        }
        .alert("Skip Setup?", isPresented: $showSkipAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Skip", role: .destructive) {
                viewModel.skip()
            }
        } message: {
            Text("You can configure routines later from settings.")
        }
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .welcome:
            WelcomeStepView()
        case .setBedtime:
            BedtimeStepView(viewModel: viewModel)
        case .setWakeTime:
            WakeTimeStepView(viewModel: viewModel)
        case .configureRoutines:
            RoutinesStepView(viewModel: viewModel)
        case .complete:
            CompleteStepView()
        }
    }
}

// MARK: - Welcome Step

/// SwiftUI View for the WelcomeStep screen. Binds to the corresponding view model.
struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.xLarge) {
            // Logo
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 80))
                .foregroundColor(Theme.Colors.primary)
                .padding()
                .background(
                    Circle()
                        .fill(Theme.Colors.primary.opacity(0.2))
                )
            
            VStack(spacing: Theme.Spacing.medium) {
                Text("Welcome to")
                    .font(Theme.Typography.title2)
                    .foregroundColor(Theme.Colors.secondaryText)
                
                Text("NOCTURNA")
                    .font(Theme.Typography.largeTitle)
                    .foregroundColor(Theme.Colors.primaryText)
                    .tracking(2)
            }
            
            Text("Your personal sleep companion")
                .font(Theme.Typography.body)
                .foregroundColor(Theme.Colors.secondaryText)
                .multilineTextAlignment(.center)
            
            // Features
            VStack(spacing: Theme.Spacing.large) {
                FeatureRow(
                    icon: "bed.double.fill",
                    title: "Better Sleep",
                    description: "Establish healthy bedtime routines"
                )
                
                FeatureRow(
                    icon: "target",
                    title: "Stay Focused",
                    description: "Block distractions during focus time"
                )
                
                FeatureRow(
                    icon: "clock.fill",
                    title: "Smart Routines",
                    description: "Automate your daily habits"
                )
            }
            .padding(.top)
        }
    }
}

// MARK: - Bedtime Step

/// SwiftUI View for the BedtimeStep screen. Binds to the corresponding view model.
struct BedtimeStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xLarge) {
            // Icon
            Image(systemName: "moon.fill")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.bedtime)
            
            // Title
            VStack(spacing: Theme.Spacing.small) {
                Text("Set Your Bedtime")
                    .font(Theme.Typography.title)
                    .foregroundColor(Theme.Colors.primaryText)
                
                Text("When do you usually go to sleep?")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            
            // Time Picker
            DatePicker(
                "Bedtime",
                selection: $viewModel.bedtime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(WheelDatePickerStyle())
            .labelsHidden()
            .colorScheme(.dark)
            .padding()
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.large)
            
            // Pre-bed Routine
            VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                Text("Pre-bed routine starts")
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.primaryText)
                
                HStack {
                    Text("\(viewModel.preBedRoutineMinutes) minutes before bedtime")
                        .font(Theme.Typography.callout)
                        .foregroundColor(Theme.Colors.secondaryText)
                    
                    Spacer()
                }
                
                Slider(
                    value: Binding(
                        get: { Double(viewModel.preBedRoutineMinutes) },
                        set: { viewModel.preBedRoutineMinutes = Int($0) }
                    ),
                    in: 15...60,
                    step: 5
                )
                .tint(Theme.Colors.primary)
            }
            .padding()
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
        }
    }
}

// MARK: - Wake Time Step

/// SwiftUI View for the WakeTimeStep screen. Binds to the corresponding view model.
struct WakeTimeStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xLarge) {
            // Icon
            Image(systemName: "sun.max.fill")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.wakeTime)
            
            // Title
            VStack(spacing: Theme.Spacing.small) {
                Text("Set Your Wake Time")
                    .font(Theme.Typography.title)
                    .foregroundColor(Theme.Colors.primaryText)
                
                Text("When do you want to wake up?")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            
            // Time Picker
            DatePicker(
                "Wake Time",
                selection: $viewModel.wakeTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(WheelDatePickerStyle())
            .labelsHidden()
            .colorScheme(.dark)
            .padding()
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.large)
            
            // Sleep Duration Display
            VStack(spacing: Theme.Spacing.small) {
                HStack {
                    Image(systemName: "bed.double.fill")
                        .foregroundColor(Theme.Colors.primary)
                    Text("Sleep Duration")
                        .font(Theme.Typography.headline)
                        .foregroundColor(Theme.Colors.primaryText)
                    Spacer()
                }
                
                Text(viewModel.sleepDurationText)
                    .font(Theme.Typography.title2)
                    .foregroundColor(Theme.Colors.accent)
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(Theme.Typography.caption)
                        .foregroundColor(Theme.Colors.error)
                }
            }
            .padding()
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
        }
    }
}

// MARK: - Routines Step

/// SwiftUI View for the RoutinesStep screen. Binds to the corresponding view model.
struct RoutinesStepView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack(spacing: Theme.Spacing.xLarge) {
            // Icon
            Image(systemName: "clock.badge.checkmark.fill")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.primary)
            
            // Title
            VStack(spacing: Theme.Spacing.small) {
                Text("Choose Your Routines")
                    .font(Theme.Typography.title)
                    .foregroundColor(Theme.Colors.primaryText)
                
                Text("Select the routines you'd like to use")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            
            // Routine Options
            VStack(spacing: Theme.Spacing.medium) {
                ForEach(RoutineType.allCases.filter { $0 != .custom }, id: \.self) { type in
                    RoutineOptionCard(
                        type: type,
                        isSelected: viewModel.selectedRoutineTypes.contains(type),
                        action: {
                            if viewModel.selectedRoutineTypes.contains(type) {
                                viewModel.selectedRoutineTypes.remove(type)
                            } else {
                                viewModel.selectedRoutineTypes.insert(type)
                            }
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Complete Step

/// SwiftUI View for the CompleteStep screen. Binds to the corresponding view model.
struct CompleteStepView: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.xLarge) {
            // Success Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(Theme.Colors.success)
            
            VStack(spacing: Theme.Spacing.medium) {
                Text("You're All Set!")
                    .font(Theme.Typography.title)
                    .foregroundColor(Theme.Colors.primaryText)
                
                Text("Your personalized sleep journey begins now")
                    .font(Theme.Typography.body)
                    .foregroundColor(Theme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            // Summary Cards
            VStack(spacing: Theme.Spacing.medium) {
                SummaryCard(
                    icon: "moon.fill",
                    title: "Sleep Schedule",
                    description: "Configured and ready"
                )
                
                SummaryCard(
                    icon: "bell.fill",
                    title: "Notifications",
                    description: "Enabled for reminders"
                )
                
                SummaryCard(
                    icon: "sparkles",
                    title: "Routines",
                    description: "Ready to help you focus"
                )
            }
            .padding(.top)
        }
    }
}

// MARK: - Supporting Views

/// Type documentation.
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: Theme.Spacing.medium) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Theme.Colors.primary)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.primaryText)
                
                Text(description)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            
            Spacer()
        }
    }
}

/// Domain model representing a schedulable routine with activation state and repeat rules.
struct RoutineOptionCard: View {
    let type: RoutineType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? Theme.Colors.primary : Theme.Colors.secondaryText)
                
                Text(type.rawValue)
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.primaryText)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? Theme.Colors.primary : Theme.Colors.tertiaryText)
            }
            .padding()
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(isSelected ? Theme.Colors.primary : Color.clear, lineWidth: 2)
            )
        }
    }
}

/// Type documentation.
struct SummaryCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(Theme.Colors.success)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Theme.Typography.headline)
                    .foregroundColor(Theme.Colors.primaryText)
                
                Text(description)
                    .font(Theme.Typography.caption)
                    .foregroundColor(Theme.Colors.secondaryText)
            }
            
            Spacer()
        }
        .padding()
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.medium)
    }
}
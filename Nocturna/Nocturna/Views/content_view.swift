/**
 Summary
 -------
 The compositional container that switches between onboarding and the main experience based on persisted state.
 
 MVVM Role
 ---------
 View layer bound to one or more view models provided via `@EnvironmentObject` or `@StateObject`.
 
 Key Responsibilities
 --------------------
 - Presents onboarding when initial setup has not been completed.
 - Presents the home experience when the app is ready.
 */
import SwiftUI



// MARK: - Content View (Main App Entry)

/// SwiftUI View for the Content screen. Binds to the corresponding view model.
struct ContentView: View {
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    
    var body: some View {
        Group {
            if dataManager.hasCompletedOnboarding {
                HomeView()
            } else {
                OnboardingView()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            setupApp()
        }
    }
    
    private func setupApp() {
        // Request notification permissions if needed
        if !notificationManager.isAuthorized {
            notificationManager.requestAuthorization()
        }
    }
}

// MARK: - Preview

/// Type documentation.
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

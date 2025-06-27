import SwiftUI
import MLXEngine

@main
struct MLXChatAppApp: App {
    @StateObject private var appState = AppState()
    
    init() {
        // This would be a good place for any initial setup, like logging.
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
        }
    }
}

struct RootView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            if appState.showOnboarding {
                // We will create this view next
                OnboardingView(onComplete: {
                    appState.completeOnboarding()
                })
            } else {
                ContentView()
            }
        }
    }
} 
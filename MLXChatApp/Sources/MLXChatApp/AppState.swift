import SwiftUI

@MainActor
class AppState: ObservableObject {
    @Published var showOnboarding = !UserDefaults.standard.bool(forKey: "onboarding_completed")
    
    func completeOnboarding() {
        showOnboarding = false
        UserDefaults.standard.set(true, forKey: "onboarding_completed")
    }
} 
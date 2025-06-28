import SwiftUI
import SwiftUIKit

struct ContentView: View {
    @State private var selectedTab = 0
    @AppStorage("selectedStyleKind") private var selectedStyleKindRaw: String = UIAIStyleKind.minimal.rawValue
    @AppStorage("selectedColorScheme") private var selectedColorSchemeRaw: String = UIAIColorScheme.light.rawValue
    @AppStorage("showOnboarding") private var showOnboarding: Bool = true
    @State private var showOnboardingSheet: Bool = false
    
    private var currentStyle: any UIAIStyle {
        UIAIStyleRegistry.style(for: UIAIStyleKind(rawValue: selectedStyleKindRaw) ?? .minimal, colorScheme: UIAIColorScheme(rawValue: selectedColorSchemeRaw) ?? .light)
    }
    
    var body: some View {
        ZStack {
            if showOnboarding {
                OnboardingView {
                    showOnboarding = false
                }
            } else {
            #if os(iOS)
            TabView(selection: $selectedTab) {
                ChatView()
                    .tabItem {
                        Image(systemName: "message")
                        Text("Chat")
                    }
                    .tag(0)
                
                ModelDiscoveryView()
                    .tabItem {
                        Image(systemName: "square.and.arrow.down")
                        Text("Models")
                    }
                    .tag(1)
                
                SettingsView(
                    selectedStyleKindRaw: $selectedStyleKindRaw,
                    selectedColorSchemeRaw: $selectedColorSchemeRaw,
                    showOnboarding: $showOnboarding,
                    showOnboardingSheet: $showOnboardingSheet
                )
                    .tabItem {
                        Image(systemName: "gear")
                        Text("Settings")
                    }
                    .tag(2)
            }
            .uiaiStyle(currentStyle)
            #else
            NavigationSplitView {
                List(selection: $selectedTab) {
                    Label("Chat", systemImage: "message").tag(0)
                    Label("Models", systemImage: "square.and.arrow.down").tag(1)
                    Label("Settings", systemImage: "gear").tag(2)
                }
                .listStyle(.sidebar)
            
                switch selectedTab {
                case 0:
                    ChatView()
                case 1:
                    ModelDiscoveryView()
                case 2:
                    SettingsView(
                        selectedStyleKindRaw: $selectedStyleKindRaw,
                        selectedColorSchemeRaw: $selectedColorSchemeRaw,
                        showOnboarding: $showOnboarding,
                        showOnboardingSheet: $showOnboardingSheet
                    )
                default:
                    ChatView()
                }
            }
            .uiaiStyle(currentStyle)
            #endif
            }
        }
        .sheet(isPresented: $showOnboardingSheet) {
            OnboardingView {
                showOnboarding = false
                showOnboardingSheet = false
            }
        }
    }
}

// Placeholder for SettingsView
struct SettingsView: View {
    @Binding var selectedStyleKindRaw: String
    @Binding var selectedColorSchemeRaw: String
    @Binding var showOnboarding: Bool
    @Binding var showOnboardingSheet: Bool
    @State private var showingAppearanceSheet = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Appearance")) {
                    Button(action: { showingAppearanceSheet = true }) {
                        HStack {
                            Image(systemName: "paintpalette")
                            Text("Change Theme & Style")
                        }
                    }
                }
                Section(header: Text("Development")) {
                    Toggle(isOn: $showOnboarding) {
                        Text("Show onboarding on next launch")
                    }
                    .accessibilityIdentifier("showOnboardingToggle")
                    Button(action: { showOnboardingSheet = true }) {
                        Label("Show onboarding now", systemImage: "rectangle.stack.person.crop")
                    }
                    .accessibilityIdentifier("showOnboardingNowButton")
                }
                // Add other settings here
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingAppearanceSheet) {
                AppearanceSettingsView(
                    selectedStyleKindRaw: $selectedStyleKindRaw,
                    selectedColorSchemeRaw: $selectedColorSchemeRaw
                )
            }
        }
    }
} 
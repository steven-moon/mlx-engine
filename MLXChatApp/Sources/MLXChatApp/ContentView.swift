import SwiftUI
import SwiftUIKit

struct ContentView: View {
    @State private var selectedTab = 0
    @AppStorage("selectedStyleKind") private var selectedStyleKindRaw: String = UIAIStyleKind.minimal.rawValue
    @AppStorage("selectedColorScheme") private var selectedColorSchemeRaw: String = UIAIColorScheme.light.rawValue
    
    private var currentStyle: any UIAIStyle {
        UIAIStyleRegistry.style(for: UIAIStyleKind(rawValue: selectedStyleKindRaw) ?? .minimal, colorScheme: UIAIColorScheme(rawValue: selectedColorSchemeRaw) ?? .light)
    }
    
    var body: some View {
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
                selectedColorSchemeRaw: $selectedColorSchemeRaw
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
        } detail: {
            switch selectedTab {
            case 0:
                ChatView()
            case 1:
                ModelDiscoveryView()
            case 2:
                SettingsView(
                    selectedStyleKindRaw: $selectedStyleKindRaw,
                    selectedColorSchemeRaw: $selectedColorSchemeRaw
                )
            default:
                ChatView()
            }
        }
        .uiaiStyle(currentStyle)
        #endif
    }
}

// Placeholder for SettingsView
struct SettingsView: View {
    @Binding var selectedStyleKindRaw: String
    @Binding var selectedColorSchemeRaw: String
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
import SwiftUI
import MLXEngine

struct MainTabView: View {
    @State private var selectedModel: String = ""
    @State private var maxTokens: Double = 2048
    @State private var enableLogging: Bool = false
    @State private var selectedTab: Int = 0
    
    init() {
        AppLogger.shared.debug("MainTabView", "Initialized MainTabView")
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ChatTab(selectedModel: $selectedModel, maxTokens: $maxTokens)
                .tabItem {
                    Label("Chat", systemImage: "message")
                }
                .tag(0)
                .onAppear { AppLogger.shared.debug("MainTabView", "Chat tab appeared") }
            ModelDiscoveryView()
                .tabItem {
                    Label("Models", systemImage: "square.and.arrow.down")
                }
                .tag(1)
                .onAppear { AppLogger.shared.debug("MainTabView", "Models tab appeared") }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(2)
                .onAppear { AppLogger.shared.debug("MainTabView", "Settings tab appeared") }
            DebugPanel()
                .tabItem {
                    Label("Debug", systemImage: "ladybug")
                }
                .tag(3)
                .onAppear { AppLogger.shared.debug("MainTabView", "Debug tab appeared") }
        }
    }
} 
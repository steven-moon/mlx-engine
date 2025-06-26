import SwiftUI
import MLXEngine
import UIAI

struct MainTabView: View {
    @State private var selectedModel: String = ""
    @State private var maxTokens: Double = 2048
    @State private var enableLogging: Bool = false
    @State private var selectedTab: Int = 0
    @Binding var selectedStyleKindRaw: String
    @Binding var selectedColorSchemeRaw: String
    @Environment(\.uiaiStyle) private var uiaiStyle: any UIAIStyle
    
    var body: some View {
        ZStack {
            uiaiStyle.backgroundColor.ignoresSafeArea()
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
                SettingsView(selectedStyleKindRaw: $selectedStyleKindRaw, selectedColorSchemeRaw: $selectedColorSchemeRaw)
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
            .accentColor(uiaiStyle.accentColor)
            .background(uiaiStyle.backgroundColor.ignoresSafeArea())
            .onAppear {
                AppLogger.shared.debug("MainTabView", "MainTabView appeared")
                let appearance = UITabBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor(uiaiStyle.backgroundColor)
                UITabBar.appearance().standardAppearance = appearance
                if #available(iOS 15.0, *) {
                    UITabBar.appearance().scrollEdgeAppearance = appearance
                }
            }
        }
    }
} 
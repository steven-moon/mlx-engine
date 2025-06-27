import SwiftUI
import SwiftUIKit

struct ContentView: View {
    @State private var selectedTab = 0
    
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
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(2)
        }
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
                SettingsView()
            default:
                ChatView()
            }
        }
        #endif
    }
}

// Placeholder for SettingsView
struct SettingsView: View {
    var body: some View {
        Text("Settings View")
    }
} 
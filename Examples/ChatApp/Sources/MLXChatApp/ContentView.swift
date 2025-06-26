//
//  ContentView.swift
//  MLXChatApp
//
//  Main entry for the sample chat app using UIAI library.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("UIAI.selectedModel") private var selectedModel: String = "Qwen 0.5B Chat"
    @AppStorage("UIAI.maxTokens") private var maxTokens: Double = 2048
    @AppStorage("UIAI.enableLogging") private var enableLogging: Bool = true
    
    var body: some View {
        MainTabView(selectedModel: $selectedModel, maxTokens: $maxTokens, enableLogging: $enableLogging)
    }
}

#Preview {
    ContentView()
}

#if os(macOS)
struct SidebarView: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        List(selection: $selectedTab) {
            NavigationLink(destination: ChatView()) {
                Label("Chat", systemImage: "message")
            }
            .tag(0)
            
            NavigationLink(destination: ModelDiscoveryView()) {
                Label("Models", systemImage: "square.and.arrow.down")
            }
            .tag(1)
            
            NavigationLink(destination: SettingsView()) {
                Label("Settings", systemImage: "gear")
            }
            .tag(2)
        }
        .navigationTitle("MLX Chat")
    }
}
#endif 
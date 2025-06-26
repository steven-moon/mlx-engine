//
//  MainTabView.swift
//  MLXChatApp
//
//  Extracted from SampleChatApp for clarity and modularity.
//

import SwiftUI
import UIAI

struct MainTabView: View {
    @Binding var selectedModel: String
    @Binding var maxTokens: Double
    @Binding var enableLogging: Bool
    
    var body: some View {
        TabView {
            ChatTab(selectedModel: $selectedModel, maxTokens: $maxTokens)
                .tabItem {
                    Label("Chat", systemImage: "bubble.left.and.bubble.right.fill")
                }
            ModelDiscoveryView()
                .tabItem {
                    Label("Models", systemImage: "square.stack.3d.up")
                }
            SettingsPanel()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
            DebugPanel()
                .tabItem {
                    Label("Debug", systemImage: "ladybug")
                }
        }
    }
} 
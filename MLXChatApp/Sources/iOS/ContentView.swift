//
//  ContentView.swift
//  MLXChatApp
//
//  Main entry for the sample chat app using UIAI library.
//

import SwiftUI
import MLXEngine // Ensure AppLogger is available

struct ContentView: View {
    @AppStorage("UIAI.selectedModel") private var selectedModel: String = "Qwen 0.5B Chat"
    @AppStorage("UIAI.maxTokens") private var maxTokens: Double = 2048
    @AppStorage("UIAI.enableLogging") private var enableLogging: Bool = true
    
    init() {
        AppLogger.shared.debug("ContentView", "Initialized ContentView")
    }
    
    var body: some View {
        MainTabView()
            .onAppear {
                AppLogger.shared.debug("ContentView", "Rendering ContentView body")
            }
    }
}

#Preview {
    ContentView()
} 
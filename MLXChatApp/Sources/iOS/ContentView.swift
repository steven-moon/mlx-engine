//
//  ContentView.swift
//  MLXChatApp
//
//  Main entry for the sample chat app using UIAI library.
//

import SwiftUI
import MLXEngine // Ensure AppLogger is available
import UIAI

struct ContentView: View {
    @AppStorage("UIAI.selectedModel") private var selectedModel: String = "Qwen 0.5B Chat"
    @AppStorage("UIAI.maxTokens") private var maxTokens: Double = 2048
    @AppStorage("UIAI.enableLogging") private var enableLogging: Bool = true
    @AppStorage("selectedUIAIStyleKind") private var selectedStyleKindRaw: String = UIAIStyleKind.minimal.rawValue
    @AppStorage("selectedUIAIColorScheme") private var selectedColorSchemeRaw: String = UIAIColorScheme.light.rawValue
    
    private var selectedStyleKind: UIAIStyleKind {
        UIAIStyleKind(rawValue: selectedStyleKindRaw) ?? .minimal
    }
    private var selectedColorScheme: UIAIColorScheme {
        UIAIColorScheme(rawValue: selectedColorSchemeRaw) ?? .light
    }
    private var currentStyle: UIAIStyle {
        UIAIStyleRegistry.style(for: selectedStyleKind, colorScheme: selectedColorScheme)
    }
    
    init() {
        AppLogger.shared.debug("ContentView", "Initialized ContentView")
    }
    
    var body: some View {
        MainTabView()
            .uiaiStyle(currentStyle)
            .onAppear {
                AppLogger.shared.debug("ContentView", "Rendering ContentView body")
            }
    }
}

#Preview {
    ContentView()
} 
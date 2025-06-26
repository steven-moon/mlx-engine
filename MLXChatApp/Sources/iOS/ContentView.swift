//
//  ContentView.swift
//  MLXChatApp
//
//  Main entry for the sample chat app using UIAI library.
//

import SwiftUI
import MLXEngine // Ensure AppLogger is available
import UIAI
import os

struct ContentView: View {
    @AppStorage("UIAI.selectedModel") private var selectedModel: String = "Qwen 0.5B Chat"
    @AppStorage("UIAI.maxTokens") private var maxTokens: Double = 2048
    @AppStorage("UIAI.enableLogging") private var enableLogging: Bool = true
    @State private var selectedStyleKindRaw: String = UserDefaults.standard.string(forKey: "selectedUIAIStyleKind") ?? UIAIStyleKind.minimal.rawValue
    @State private var selectedColorSchemeRaw: String = UserDefaults.standard.string(forKey: "selectedUIAIColorScheme") ?? UIAIColorScheme.light.rawValue
    
    private let contentLogger = Logger(subsystem: "com.clevercoding.MLXChatApp", category: "UIAIContentView")
    
    private var selectedStyleKind: UIAIStyleKind {
        UIAIStyleKind(rawValue: selectedStyleKindRaw) ?? .minimal
    }
    private var selectedColorScheme: UIAIColorScheme {
        UIAIColorScheme(rawValue: selectedColorSchemeRaw) ?? .light
    }
    private var currentStyle: any UIAIStyle {
        let styleKind = UIAIStyleKind(rawValue: selectedStyleKindRaw) ?? .minimal
        let colorScheme = UIAIColorScheme(rawValue: selectedColorSchemeRaw) ?? .light
        let style = UIAIStyleRegistry.style(for: styleKind, colorScheme: colorScheme)
        contentLogger.info("currentStyle recomputed: styleKind=\(styleKind.rawValue), colorScheme=\(colorScheme.rawValue)")
        return style
    }
    
    init() {
        AppLogger.shared.debug("ContentView", "Initialized ContentView")
    }
    
    var body: some View {
        MainTabView(selectedStyleKindRaw: $selectedStyleKindRaw, selectedColorSchemeRaw: $selectedColorSchemeRaw)
            .id(selectedStyleKindRaw + selectedColorSchemeRaw)
            .uiaiStyle(currentStyle)
            .onChange(of: selectedStyleKindRaw) { newValue in
                UserDefaults.standard.set(newValue, forKey: "selectedUIAIStyleKind")
                AppLogger.shared.debug("ContentView", "Style kind changed to \(newValue)")
            }
            .onChange(of: selectedColorSchemeRaw) { newValue in
                UserDefaults.standard.set(newValue, forKey: "selectedUIAIColorScheme")
                contentLogger.info("selectedColorSchemeRaw changed to: \(newValue)")
            }
            .onAppear {
                AppLogger.shared.debug("ContentView", "Rendering ContentView body")
            }
    }
}

#Preview {
    ContentView()
} 
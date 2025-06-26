//
//  SampleChatApp.swift
//  MLXChatApp
//
//  Created as a sample app using the UIAI SwiftUI library.
//

import SwiftUI
import UIAI
import MLXEngine

@main
struct SampleChatApp: App {
    @AppStorage("UIAI.selectedModel") private var selectedModel: String = "Qwen 0.5B Chat"
    @AppStorage("UIAI.maxTokens") private var maxTokens: Double = 2048
    @AppStorage("UIAI.enableLogging") private var enableLogging: Bool = true
    
    var body: some Scene {
        WindowGroup {
            MainTabView(selectedModel: $selectedModel, maxTokens: $maxTokens, enableLogging: $enableLogging)
        }
    }
} 
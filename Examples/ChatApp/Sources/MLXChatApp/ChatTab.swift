//
//  ChatTab.swift
//  MLXChatApp
//
//  Extracted from SampleChatApp for clarity and modularity.
//

import SwiftUI
import UIAI
import MLXEngine

struct ChatTab: View {
    @Binding var selectedModel: String
    @Binding var maxTokens: Double
    @StateObject private var chatManager = ChatSessionManager()
    @State private var lastModel: String = ""
    
    var body: some View {
        ChatView()
            .onAppear {
                startSessionIfNeeded()
            }
            .onChange(of: selectedModel) { newModel in
                if newModel != lastModel {
                    let config = ModelConfiguration(
                        name: newModel,
                        hubId: newModel, // For demo, use name as hubId
                        description: "Chat model"
                    )
                    chatManager.startSession(model: config)
                    lastModel = newModel
                }
            }
    }
    
    private func startSessionIfNeeded() {
        if chatManager.messages.isEmpty || selectedModel != lastModel {
            let config = ModelConfiguration(
                name: selectedModel,
                hubId: selectedModel, // For demo, use name as hubId
                description: "Chat model"
            )
            chatManager.startSession(model: config)
            lastModel = selectedModel
        }
    }
} 
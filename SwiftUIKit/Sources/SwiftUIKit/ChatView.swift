//
//  ChatView.swift
//  UIAI
//
//  Created for MLXEngine Shared SwiftUI Library
//
//  A cross-platform SwiftUI view for LLM chat interfaces.
//  This is a stub for future expansion and integration with MLXEngine chat/session APIs.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// A SwiftUI view for LLM chat interfaces.
///
/// - Supports streaming, markdown, and chat history.
/// - Designed for iOS, macOS, visionOS, tvOS, and watchOS.
/// - Integrates with MLXEngine chat/session APIs.
public struct ChatView: View {
    public struct Message: Identifiable, Hashable {
        public enum Sender { case user, assistant }
        public let id: UUID = UUID()
        public let sender: Sender
        public let text: String
        public init(sender: Sender, text: String) {
            self.sender = sender
            self.text = text
        }
    }
    @StateObject private var manager = ChatSessionManager()
    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool
    @State private var errorMessage: String? = nil
    @State private var showError: Bool = false
    @State private var showResetConfirmation: Bool = false
    @Environment(\.uiaiStyle) private var uiaiStyle: any UIAIStyle
    
    public init() {}
    
    public var body: some View {
        #if os(iOS) || os(macOS) || os(visionOS)
        VStack(spacing: 0) {
            OnboardingBanner(title: "Welcome to Chat!", message: "Start a conversation with your AI assistant. Select a model in Settings if you want to change it.")
            if let errorMessage = errorMessage, showError {
                ErrorBanner(message: errorMessage, style: .error, isPresented: $showError)
            }
            HStack {
                Spacer()
                Button(role: .destructive) {
                    showResetConfirmation = true
                } label: {
                    Label("Reset Chat", systemImage: "arrow.counterclockwise")
                }
                .padding(.trailing)
            }
            if manager.messages.isEmpty {
                Button("Start Chat Session") {
                    // For demo, use a default model config
                    let config = ModelConfiguration(
                        name: "Qwen 0.5B Chat",
                        hubId: "mlx-community/Qwen1.5-0.5B-Chat-4bit",
                        description: "Small, fast chat model for testing and quick responses."
                    )
                    manager.startSession(model: config)
                }
                .padding()
            } else {
                ChatHistoryView(messages: manager.messages) { message in
                    AnyView(
                        HStack(alignment: .top) {
                            if message.sender == .assistant {
                                Image(systemName: "brain.head.profile")
                                    .foregroundColor(uiaiStyle.accentColor)
                            } else {
                                Image(systemName: "person.fill")
                                    .foregroundColor(uiaiStyle.successColor)
                            }
                            Text(message.text)
                                .padding(8)
                                .background(
                                    message.sender == .assistant ? uiaiStyle.backgroundColor : uiaiStyle.accentColor.opacity(0.15)
                                )
                                .foregroundColor(uiaiStyle.foregroundColor)
                                .cornerRadius(10)
                            Spacer()
                        }
                    )
                }
                Divider()
                ChatInputView(text: $inputText, onSend: {
                    Task {
                        await sendMessage()
                    }
                })
                    .disabled(manager.isStreaming)
                if manager.isStreaming {
                    HStack {
                        ProgressView()
                        Text("Assistant is typing...")
                            .font(.caption)
                            .foregroundColor(uiaiStyle.secondaryForegroundColor)
                    }
                    .padding(.bottom, 8)
                }
            }
        }
        .alert("Reset Chat?", isPresented: $showResetConfirmation) {
            Button("Reset", role: .destructive) { manager.reset() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will clear the chat history and start a new session.")
        }
        .background(uiaiStyle.backgroundColor.ignoresSafeArea())
        .onAppear {
            print("[ChatView] Appeared with style: \(type(of: uiaiStyle)), colorScheme: \(uiaiStyle.colorScheme)")
            #if canImport(UIKit)
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(uiaiStyle.backgroundColor)
            appearance.titleTextAttributes = [.foregroundColor: UIColor(uiaiStyle.foregroundColor)]
            UINavigationBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UINavigationBar.appearance().scrollEdgeAppearance = appearance
            }
            #endif
        }
        .onChange(of: uiaiStyle.colorScheme) { newValue in
            print("[ChatView] Color scheme changed to: \(newValue)")
        }
        #else
        Text("Chat is not yet available on this platform.")
            .foregroundColor(.secondary)
        #endif
    }
    
    private func sendMessage() async {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            try await manager.sendMessage(trimmed)
            inputText = ""
            isInputFocused = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

#if DEBUG
struct ChatView_Previews: PreviewProvider {
    static var previews: some View {
        ChatView()
            .frame(height: 400)
            .uiaiStyle(MinimalStyle(colorScheme: .light))
    }
}
#endif 
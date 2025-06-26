//
//  ChatSessionManager.swift
//  UIAI
//
//  Created for MLXEngine Shared SwiftUI Library
//
//  Manages chat state, messages, and interaction with MLXEngine's ChatSession.
//

import Foundation
import Combine
import MLXEngine

/// An observable object that manages chat state and interaction with MLXEngine's ChatSession.
///
/// - Supports sending user messages, receiving streaming assistant responses, and resetting the session.
/// - Designed for use with ChatView and other chat UIs.
@MainActor
public class ChatSessionManager: ObservableObject {
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
    @Published public private(set) var messages: [Message] = []
    @Published public var isStreaming: Bool = false
    private var chatSession: ChatSession?
    private var streamTask: Task<Void, Never>?
    
    public init() {}
    
    /// Starts a new chat session with the given model configuration.
    public func startSession(model: ModelConfiguration) {
        messages = []
        Task {
            do {
                let engine = try await InferenceEngine.loadModel(model)
                await MainActor.run {
                    self.chatSession = ChatSession(engine: engine)
                }
            } catch {
                await MainActor.run {
                    self.messages.append(Message(sender: .assistant, text: "[Error: \(error.localizedDescription)]"))
                }
            }
        }
    }
    
    /// Sends a user message and streams the assistant's response.
    public func sendMessage(_ text: String) {
        guard let chatSession = chatSession else { return }
        let userMsg = Message(sender: .user, text: text)
        messages.append(userMsg)
        isStreaming = true
        streamTask?.cancel()
        streamTask = Task { [weak self] in
            guard let self = self else { return }
            do {
                var response = ""
                for try await chunk in chatSession.streamResponse(text) {
                    response += chunk
                    if let last = self.messages.last, last.sender == .assistant {
                        self.messages[self.messages.count - 1] = Message(sender: .assistant, text: response)
                    } else {
                        self.messages.append(Message(sender: .assistant, text: response))
                    }
                }
            } catch {
                self.messages.append(Message(sender: .assistant, text: "[Error: \(error.localizedDescription)]"))
            }
            self.isStreaming = false
        }
    }
    
    /// Resets the chat session and clears messages.
    public func reset() {
        chatSession = nil
        messages = []
        isStreaming = false
        streamTask?.cancel()
        streamTask = nil
    }
} 
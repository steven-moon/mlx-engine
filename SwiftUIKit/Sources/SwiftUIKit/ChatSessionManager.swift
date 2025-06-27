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
        init(sender: Sender, text: String) {
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
        // TODO: Replace with real model loading logic
        self.chatSession = ChatSession()
    }
    
    /// Sends a user message and streams the assistant's response.
    public func sendMessage(_ text: String) async throws {
        guard let chatSession = chatSession else { 
            throw ChatError.noActiveSession 
        }
        let userMsg = Message(sender: .user, text: text)
        messages.append(userMsg)
        isStreaming = true
        streamTask?.cancel()
        streamTask = Task { [weak self] in
            guard let self = self else { return }
            do {
                var response = ""
                for try await chunk in try await chatSession.streamResponse(text) {
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

// --- Minimal stub for ChatSession ---
fileprivate class ChatSession {
    func streamResponse(_ text: String) async throws -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                for word in text.split(separator: " ") {
                    try? await Task.sleep(nanoseconds: 200_000_000)
                    continuation.yield(String(word) + " ")
                }
                continuation.finish()
            }
        }
    }
}

// --- Error types ---
public enum ChatError: Error, LocalizedError {
    case noActiveSession
    
    public var errorDescription: String? {
        switch self {
        case .noActiveSession:
            return "No active chat session"
        }
    }
} 
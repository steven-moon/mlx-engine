import Foundation

// MARK: - Chat Message Types

/// Represents a message in a chat conversation
public struct ChatMessage: Codable, Identifiable, Sendable {
    public let id: UUID
    public let role: Role
    public let content: String
    public let timestamp: Date
    
    public init(role: Role, content: String, id: UUID = UUID(), timestamp: Date = Date()) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
    
    /// The role of the message sender
    public enum Role: String, Codable, CaseIterable, Sendable {
        case system = "system"
        case user = "user"
        case assistant = "assistant"
    }
}

// MARK: - Chat Session

/// Manages a multi-turn conversation with an LLM
public final class ChatSession: @unchecked Sendable {
    private let engine: any LLMEngine
    private var messages: [ChatMessage] = []
    private let queue = DispatchQueue(label: "chat-session", qos: .userInitiated)
    
    public init(engine: any LLMEngine) {
        self.engine = engine
    }
    
    /// The current conversation history
    public var conversationHistory: [ChatMessage] {
        queue.sync { messages }
    }
    
    /// Adds a message to the conversation
    public func addMessage(_ role: ChatMessage.Role, content: String) async throws {
        let message = ChatMessage(role: role, content: content)
        queue.sync { messages.append(message) }
    }
    
    /// Generates a response to the given content
    public func generateResponse(_ content: String, params: GenerateParams = .init()) async throws -> String {
        // Add the user message
        try await addMessage(.user, content: content)
        
        // Format the conversation for the model
        let formattedPrompt = formatConversation()
        
        // Generate the response
        let response = try await engine.generate(formattedPrompt, params: params)
        
        // Add the assistant response
        try await addMessage(.assistant, content: response)
        
        return response
    }
    
    /// Streams a response to the given content
    public func streamResponse(_ content: String, params: GenerateParams = .init()) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    // Add the user message
                    try await self.addMessage(.user, content: content)
                    
                    // Format the conversation for the model
                    let formattedPrompt = self.formatConversation()
                    
                    // Stream the response
                    var fullResponse = ""
                    for try await token in self.engine.stream(formattedPrompt, params: params) {
                        fullResponse += token
                        continuation.yield(token)
                    }
                    
                    // Add the assistant response
                    try await self.addMessage(.assistant, content: fullResponse)
                    
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    /// Clears the conversation history
    public func clearHistory() {
        queue.sync { messages.removeAll() }
    }
    
    /// Removes the last message from the conversation
    public func removeLastMessage() {
        queue.sync { _ = messages.popLast() }
    }
    
    /// Gets the last message in the conversation
    public var lastMessage: ChatMessage? {
        queue.sync { messages.last }
    }
    
    /// Gets the number of messages in the conversation
    public var messageCount: Int {
        queue.sync { messages.count }
    }
    
    /// Formats the conversation history into a prompt for the model
    private func formatConversation() -> String {
        queue.sync {
            var formatted = ""
            
            for message in messages {
                switch message.role {
                case .system:
                    formatted += "System: \(message.content)\n\n"
                case .user:
                    formatted += "User: \(message.content)\n\n"
                case .assistant:
                    formatted += "Assistant: \(message.content)\n\n"
                }
            }
            
            // Add a final prompt for the assistant
            formatted += "Assistant: "
            
            return formatted
        }
    }
    
    /// Exports the conversation as a formatted string
    public func exportConversation() -> String {
        queue.sync {
            var export = "Chat Conversation\n"
            export += "================\n\n"
            
            for message in messages {
                export += "[\(message.role.rawValue.uppercased())] \(message.timestamp.formatted())\n"
                export += "\(message.content)\n\n"
            }
            
            return export
        }
    }
    
    /// Imports a conversation from a formatted string
    public func importConversation(_ conversation: String) {
        // TODO: Implement conversation import
        // This would parse the exported format and reconstruct the messages
    }
} 
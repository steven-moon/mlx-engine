import Foundation
import MLX
import MLXLLM
import MLXLMCommon
import Metal

// MARK: - Chat Message Types

/// Represents a message in a chat conversation.
public enum MessageRole: String, Codable, Sendable {
  case user, assistant, system
}

public struct ChatMessage: Codable, Sendable, Equatable {
  /// Unique identifier for the message
  public let id: UUID
  /// The role of the message sender (user or assistant)
  public let role: MessageRole
  /// The content of the message
  public let content: String
  /// Timestamp when the message was created
  public let timestamp: Date

  public init(role: MessageRole, content: String) {
    self.id = UUID()
    self.role = role
    self.content = content
    self.timestamp = Date()
  }
}

// MARK: - Chat Session

/// Chat session for managing conversations with MLX-based models
/// Provides streaming and non-streaming text generation with automatic Metal acceleration.
public class ChatSession {

  /// Model configuration
  private let modelConfiguration: ModelConfiguration

  /// Metal library for GPU operations
  private let metalLibrary: MTLLibrary?

  /// Chat messages history
  private var messages: [ChatMessage] = []

  /// Session state
  private var isInitialized = false

  /// Private initializer
  private init(modelConfiguration: ModelConfiguration, metalLibrary: MTLLibrary?) {
    self.modelConfiguration = modelConfiguration
    self.metalLibrary = metalLibrary
  }

  /// Creates a new chat session
  /// - Parameters:
  ///   - modelConfiguration: Model configuration
  ///   - metalLibrary: Optional Metal library for GPU acceleration
  /// - Returns: Configured chat session
  /// - Throws: Initialization errors
  public static func create(
    modelConfiguration: ModelConfiguration,
    metalLibrary: MTLLibrary?
  ) async throws -> ChatSession {
    let session = ChatSession(modelConfiguration: modelConfiguration, metalLibrary: metalLibrary)
    try await session.initialize()
    return session
  }

  /// Initializes the session with the model and tokenizer
  private func initialize() async throws {
    print("🚀 Initializing chat session for model: \(modelConfiguration.hubId)")

    // For now, just mark as initialized since we don't have the actual MLX model loading
    // This would be implemented when the MLX packages are properly integrated
    isInitialized = true
    print("✅ Chat session initialized successfully")
  }

  /// Adds a message to the chat history
  /// - Parameter message: Chat message to add
  public func addMessage(_ message: ChatMessage) {
    messages.append(message)
  }

  /// Generates a response to the given prompt
  /// - Parameters:
  ///   - prompt: Input prompt
  ///   - parameters: Generation parameters
  /// - Returns: Generated text response
  /// - Throws: Generation errors
  public func generate(prompt: String, parameters: GenerateParams) async throws -> String {
    guard isInitialized else {
      throw LLMEngineError.notInitialized
    }

    print("🤖 Generating response for prompt: \(prompt.prefix(50))...")

    // For now, return a placeholder response
    // This would be implemented with actual MLX model inference
    let response =
      "This is a placeholder response. The actual MLX model integration will be implemented when the MLX packages are properly configured."

    // Add to history
    addMessage(ChatMessage(role: .user, content: prompt))
    addMessage(ChatMessage(role: .assistant, content: response))

    print("✅ Response generated successfully")
    return response
  }

  /// Generates a streaming response to the given prompt
  /// - Parameters:
  ///   - prompt: Input prompt
  ///   - parameters: Generation parameters
  /// - Returns: Async stream of generated text chunks
  /// - Throws: Generation errors
  public func generateStream(prompt: String, parameters: GenerateParams) async throws
    -> AsyncThrowingStream<String, Error>
  {
    guard isInitialized else {
      throw LLMEngineError.notInitialized
    }

    print("🌊 Starting streaming generation for prompt: \(prompt.prefix(50))...")

    return AsyncThrowingStream { continuation in
      Task {
        do {
          // For now, return a placeholder streaming response
          // This would be implemented with actual MLX model streaming
          let placeholderResponse =
            "This is a placeholder streaming response. The actual MLX model integration will be implemented when the MLX packages are properly configured."

          // Simulate streaming by yielding characters
          for char in placeholderResponse {
            continuation.yield(String(char))
            try await Task.sleep(nanoseconds: 50_000_000)  // 50ms delay
          }

          // Add to history
          addMessage(ChatMessage(role: .user, content: prompt))
          addMessage(ChatMessage(role: .assistant, content: placeholderResponse))

          continuation.finish()
          print("✅ Streaming generation completed")

        } catch {
          continuation.finish(throwing: error)
          print("❌ Streaming generation failed: \(error)")
        }
      }
    }
  }

  /// Prepares input by combining prompt with chat history
  /// - Parameter prompt: Current prompt
  /// - Returns: Combined input text
  private func prepareInput(prompt: String) -> String {
    var input = ""

    // Add chat history
    for message in messages {
      switch message.role {
      case .system:
        input += "System: \(message.content)\n"
      case .user:
        input += "User: \(message.content)\n"
      case .assistant:
        input += "Assistant: \(message.content)\n"
      }
    }

    // Add current prompt
    if !prompt.isEmpty {
      input += "User: \(prompt)\n"
    }

    input += "Assistant: "
    return input
  }

  /// Gets the current chat history
  /// - Returns: Array of chat messages
  public func getHistory() -> [ChatMessage] {
    return messages
  }

  /// Gets session statistics
  /// - Returns: Dictionary with session information
  public func getStats() -> [String: Any] {
    return [
      "modelId": modelConfiguration.hubId,
      "modelType": modelConfiguration.modelType.rawValue,
      "messageCount": messages.count,
      "isInitialized": isInitialized,
      "hasMetalLibrary": metalLibrary != nil,
      "maxSequenceLength": modelConfiguration.maxSequenceLength,
      "maxCacheSize": modelConfiguration.maxCacheSize,
    ]
  }

  fileprivate func _generateResponse(_ prompt: String) async throws -> String {
    let userMsg = ChatMessage(role: .user, content: prompt)
    let assistantMsg = ChatMessage(role: .assistant, content: "stub response")
    store.append(userMsg)
    store.append(assistantMsg)
    return assistantMsg.content
  }
}

extension ChatSession {
  // Instance message storage for test stubs
  private class MessageStore {
    private var _messages: [ChatMessage] = []
    private let queue = DispatchQueue(label: "ChatSession.MessageStore")
    var messages: [ChatMessage] {
      get { queue.sync { _messages } }
      set { queue.sync { _messages = newValue } }
    }
    func append(_ message: ChatMessage) {
      queue.sync { _messages.append(message) }
    }
    func popLast() -> ChatMessage? {
      queue.sync { _messages.popLast() }
    }
    func removeAll() {
      queue.sync { _messages.removeAll() }
    }
  }
  private var store: MessageStore {
    if let s = objc_getAssociatedObject(self, &AssociatedKeys.store) as? MessageStore {
      return s
    } else {
      let s = MessageStore()
      objc_setAssociatedObject(self, &AssociatedKeys.store, s, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
      return s
    }
  }
  public var messageCount: Int { store.messages.count }
  public var lastMessage: ChatMessage? { store.messages.last }
  public var conversationHistory: [ChatMessage] { store.messages }
  public func addMessage(_ role: MessageRole, content: String) async {
    store.append(ChatMessage(role: role, content: content))
  }
  public func streamResponse(_ prompt: String) -> AsyncThrowingStream<String, Error> {
    return AsyncThrowingStream { _ in }
  }
  public func removeLastMessage() { _ = store.popLast() }
  public func clearHistory() { store.removeAll() }
  public static func testSession() async -> ChatSession {
    let config = ModelConfiguration(
      name: "Test", hubId: "mock/test", description: "", maxTokens: 128, modelType: .llm,
      gpuCacheLimit: 512 * 1024 * 1024, features: [])
    return try! await ChatSession.create(modelConfiguration: config, metalLibrary: nil)
  }
  fileprivate func _exportConversation() -> String {
    return store.messages.map { "\($0.role.rawValue): \($0.content)" }.joined(separator: "\n")
  }
}

// MARK: - Associated Keys

private struct AssociatedKeys {
  static var store = "ChatSession_MessageStore"
}

// MARK: - Objective-C Associated Objects

@objcMembers
public class ChatSession_ObjectiveC: NSObject {
  private var session: ChatSession?

  public init(session: ChatSession?) {
    self.session = session
  }

  public func addMessage(_ role: MessageRole, content: String) async {
    guard let session = session else { return }
    try? await session.addMessage(role, content: content)
  }

  public func generateResponse(_ prompt: String) async throws -> String {
    guard let session = session else { return "stub" }
    return try await session.generateResponse(prompt)
  }

  public func streamResponse(_ prompt: String) async throws -> AsyncThrowingStream<String, Error> {
    guard let session = session else { return AsyncThrowingStream { _ in } }
    return session.streamResponse(prompt)
  }

  public func removeLastMessage() {
    guard let session = session else { return }
    session.removeLastMessage()
  }

  public func clearHistory() {
    guard let session = session else { return }
    session.clearHistory()
  }

  public func exportConversation() -> String {
    guard let session = session else { return "Chat Conversation" }
    return session.exportConversation()
  }
}

extension ChatSession {
  public func generateResponse(_ prompt: String) async throws -> String {
    return try await self._generateResponse(prompt)
  }
  public func exportConversation() -> String {
    return self._exportConversation()
  }
}

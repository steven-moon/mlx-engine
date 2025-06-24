import XCTest
@testable import MLXEngine

@MainActor
final class ChatSessionTests: XCTestCase {
    var engine: InferenceEngine!
    var session: ChatSession!
    
    override func setUp() async throws {
        // Use a configuration that will trigger mock mode immediately
        // This avoids the noisy MLX runtime error messages
        let config = ModelConfiguration(
            name: "Mock Test Model",
            hubId: "mock/test-model",
            description: "Mock model for unit testing - will use mock implementation"
        )
        
        // Load the engine once for all tests to avoid repetitive loading
        // The mock implementation will be used since "mock/test-model" doesn't exist
        engine = try await InferenceEngine.loadModel(config) { _ in }
        session = ChatSession(engine: engine)
    }
    
    override func tearDown() async throws {
        // Clean up after all tests
        engine?.unload()
        engine = nil
        session = nil
    }
    
    func testChatSessionInitialization() {
        XCTAssertNotNil(session)
        XCTAssertEqual(session.messageCount, 0)
        XCTAssertNil(session.lastMessage)
    }
    
    func testAddMessage() async throws {
        try await session.addMessage(.user, content: "Hello")
        try await session.addMessage(.assistant, content: "Hi there!")
        
        XCTAssertEqual(session.messageCount, 2)
        XCTAssertEqual(session.lastMessage?.role, .assistant)
        XCTAssertEqual(session.lastMessage?.content, "Hi there!")
    }
    
    func testGenerateResponse() async throws {
        let response = try await session.generateResponse("What is 2+2?")
        
        XCTAssertFalse(response.isEmpty)
        XCTAssertEqual(session.messageCount, 2) // User message + assistant response
        XCTAssertEqual(session.conversationHistory[0].role, .user)
        XCTAssertEqual(session.conversationHistory[0].content, "What is 2+2?")
        XCTAssertEqual(session.conversationHistory[1].role, .assistant)
    }
    
    func testStreamResponse() async throws {
        let stream = session.streamResponse("Tell me a story")
        var tokens: [String] = []
        
        for try await token in stream {
            tokens.append(token)
        }
        
        XCTAssertGreaterThan(tokens.count, 0)
        XCTAssertEqual(session.messageCount, 2) // User message + assistant response
        XCTAssertEqual(session.conversationHistory[0].role, .user)
        XCTAssertEqual(session.conversationHistory[0].content, "Tell me a story")
        XCTAssertEqual(session.conversationHistory[1].role, .assistant)
    }
    
    func testClearHistory() async throws {
        try await session.addMessage(.user, content: "Hello")
        try await session.addMessage(.assistant, content: "Hi!")
        
        XCTAssertEqual(session.messageCount, 2)
        
        session.clearHistory()
        
        XCTAssertEqual(session.messageCount, 0)
        XCTAssertNil(session.lastMessage)
    }
    
    func testRemoveLastMessage() async throws {
        try await session.addMessage(.user, content: "Hello")
        try await session.addMessage(.assistant, content: "Hi!")
        
        XCTAssertEqual(session.messageCount, 2)
        
        session.removeLastMessage()
        
        XCTAssertEqual(session.messageCount, 1)
        XCTAssertEqual(session.lastMessage?.role, .user)
        XCTAssertEqual(session.lastMessage?.content, "Hello")
    }
    
    func testExportConversation() async throws {
        try await session.addMessage(.user, content: "Hello")
        try await session.addMessage(.assistant, content: "Hi there!")
        
        let export = session.exportConversation()
        
        XCTAssertTrue(export.contains("Chat Conversation"))
        XCTAssertTrue(export.contains("Hello"))
        XCTAssertTrue(export.contains("Hi there!"))
        XCTAssertTrue(export.contains("USER"))
        XCTAssertTrue(export.contains("ASSISTANT"))
    }
    
    func testConversationFormatting() async throws {
        try await session.addMessage(.system, content: "You are a helpful assistant")
        try await session.addMessage(.user, content: "Hello")
        try await session.addMessage(.assistant, content: "Hi!")
        try await session.addMessage(.user, content: "How are you?")
        
        // The conversation should be formatted properly for the model
        let response = try await session.generateResponse("Goodbye")
        
        XCTAssertFalse(response.isEmpty)
        // Should have 6 messages: 4 original + 2 new (user + assistant)
        XCTAssertEqual(session.messageCount, 6)
    }
    
    func testMessageTimestamps() async throws {
        let before = Date()
        try await session.addMessage(.user, content: "Hello")
        let after = Date()
        
        guard let message = session.lastMessage else {
            XCTFail("Message should exist")
            return
        }
        
        XCTAssertGreaterThanOrEqual(message.timestamp, before)
        XCTAssertLessThanOrEqual(message.timestamp, after)
    }
    
    func testMessageIds() async throws {
        try await session.addMessage(.user, content: "Hello")
        try await session.addMessage(.assistant, content: "Hi!")
        
        let messages = session.conversationHistory
        XCTAssertEqual(messages.count, 2)
        
        // Each message should have a unique ID
        let ids = messages.map { $0.id }
        XCTAssertEqual(Set(ids).count, 2)
    }
    
    func testConcurrentAccess() async throws {
        // Test that the session can handle concurrent access safely
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    try? await self.session.addMessage(.user, content: "Message \(i)")
                }
            }
        }
        
        XCTAssertEqual(session.messageCount, 10)
    }
} 
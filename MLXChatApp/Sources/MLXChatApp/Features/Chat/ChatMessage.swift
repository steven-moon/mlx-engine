import Foundation

struct ChatMessage: Identifiable, Codable, Hashable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
    let modelName: String?
    
    enum CodingKeys: String, CodingKey {
        case content, isUser, timestamp, modelName
    }

    init(content: String, isUser: Bool, modelName: String? = nil) {
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
        self.modelName = modelName
    }
}

extension ChatMessage {
    static let examples: [ChatMessage] = [
        ChatMessage(content: "Hello! How can you help me today?", isUser: true),
        ChatMessage(content: "Hi there! I'm an AI assistant powered by MLX. I can help you with questions, writing, coding, analysis, and many other tasks. What would you like to work on?", isUser: false, modelName: "Qwen 0.5B")
    ]
} 
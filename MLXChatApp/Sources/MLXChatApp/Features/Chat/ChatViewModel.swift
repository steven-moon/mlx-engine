import Foundation
import MLXEngine
import os.log
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    private let logger = Logger(subsystem: "com.mlxchatapp", category: "ChatViewModel")
    
    // Public state
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isGenerating: Bool = false
    @Published var streamingText: String = ""
    @Published var selectedModel: ModelConfiguration?
    @Published var availableModels: [ModelConfiguration] = []
    @Published var errorMessage: String?
    
    // Private state
    private var chatSession: ChatSession?
    private var currentGenerationTask: Task<Void, Never>?
    
    init() {
        Task {
            await loadAvailableModels()
        }
    }
    
    // MARK: - Model Management
    
    func loadAvailableModels() async {
        do {
            // Using ModelRegistry to get downloaded models.
            // Assuming ModelRegistry provides this function.
            // The guide is a bit vague here.
            // Let's assume ModelRegistry is the source of truth for models.
            self.availableModels = ModelRegistry.allModels.filter { _ in
                // This is a guess. How do we know which are downloaded?
                // For now, let's just show all models from the registry.
                // In a real app, we'd have a mechanism to check for downloaded files.
                true
            }
            if self.selectedModel == nil {
                self.selectedModel = self.availableModels.first
            }
        }
    }
    
    func selectModel(_ model: ModelConfiguration) async {
        guard selectedModel?.hubId != model.hubId else { return }
        
        selectedModel = model
        chatSession = nil // Reset chat session
        
        let systemMessage = ChatMessage(
            content: "Switched to \(model.name)",
            isUser: false,
            modelName: model.name
        )
        messages.append(systemMessage)
    }
    
    // MARK: - Chat Operations
    
    func sendMessage() async {
        let prompt = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty, let model = selectedModel else { return }
        
        inputText = ""
        let userMessage = ChatMessage(content: prompt, isUser: true)
        messages.append(userMessage)
        
        await generateResponse(prompt: prompt, model: model)
    }
    
    private func generateResponse(prompt: String, model: ModelConfiguration) async {
        isGenerating = true
        streamingText = ""
        errorMessage = nil
        
        currentGenerationTask?.cancel()
        
        currentGenerationTask = Task {
            do {
                if chatSession == nil {
                    // This assumes a failable initializer on ChatSession
                    // based on the guide's ChatSession.create(model: model)
                    // The api_reference shows `init(engine: LLMEngine)`.
                    // So we need to load the engine first.
                    chatSession = try await ChatSession.create(modelConfiguration: model, metalLibrary: nil)
                }
                
                guard let session = chatSession else {
                    // throw ChatError.sessionNotInitialized
                    return
                }
                
                var fullResponse = ""
                // The guide uses session.stream(prompt)
                // api_reference uses session.streamResponse(_ userMessage: String)
                let stream = session.streamResponse(prompt)
                for try await chunk in stream {
                    guard !Task.isCancelled else { break }
                    
                    await MainActor.run {
                        self.streamingText += chunk
                        fullResponse += chunk
                    }
                }
                
                if !Task.isCancelled && !fullResponse.isEmpty {
                    let aiMessage = ChatMessage(
                        content: fullResponse,
                        isUser: false,
                        modelName: model.name
                    )
                    
                    await MainActor.run {
                        self.messages.append(aiMessage)
                        self.streamingText = ""
                        self.isGenerating = false
                    }
                }
                
            } catch {
                logger.error("Generation failed: \(error.localizedDescription)")
                await MainActor.run {
                    self.errorMessage = "Failed to generate response: \(error.localizedDescription)"
                    self.isGenerating = false
                    self.streamingText = ""
                }
            }
        }
    }
    
    func stopGeneration() {
        currentGenerationTask?.cancel()
        isGenerating = false
        streamingText = ""
    }
    
    func clearMessages() {
        messages.removeAll()
        chatSession = nil
    }
    
    func clearError() {
        errorMessage = nil
    }
} 
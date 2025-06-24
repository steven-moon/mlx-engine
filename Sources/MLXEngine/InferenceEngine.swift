import Foundation

#if canImport(MLX) && canImport(MLXLLM) && canImport(MLXLMCommon)
import MLX
import MLXLLM
import MLXLMCommon
import os.log
#endif

// MARK: - Inference Engine Implementation

/// A simple, self-contained LLM engine that works out of the box
/// Uses MLX when available, falls back to mock implementation when not
public final class InferenceEngine: LLMEngine, @unchecked Sendable {
    private let config: ModelConfiguration
    private var isUnloaded = false
    private var maxTokens = 100
    
    // MLX components (optional)
    #if canImport(MLX) && canImport(MLXLLM) && canImport(MLXLMCommon)
    private var modelContainer: MLXLMCommon.ModelContainer?
    private var chatSession: MLXLMCommon.ChatSession?
    private let logger = Logger(subsystem: "com.mlxengine", category: "InferenceEngine")
    private var mlxAvailable = false
    #endif
    
    private init(config: ModelConfiguration) {
        self.config = config
        self.maxTokens = config.maxTokens
    }
    
    public static func loadModel(_ config: ModelConfiguration, progress: @escaping @Sendable (Double) -> Void = { _ in }) async throws -> InferenceEngine {
        let engine = InferenceEngine(config: config)
        try await engine.loadModelInternal(progress: progress)
        return engine
    }
    
    private func loadModelInternal(progress: @escaping @Sendable (Double) -> Void) async throws {
        #if canImport(MLX) && canImport(MLXLLM) && canImport(MLXLMCommon)
        // Check if this is a mock model (hub ID starts with "mock/")
        if config.hubId.hasPrefix("mock/") {
            print("🔧 Using mock implementation for test model: \(config.name)")
            try await loadMockModel(progress: progress)
            return
        }
        
        // Try to use MLX with better error handling
        do {
            try await loadMLXModel(progress: progress)
        } catch {
            // Log the error but continue with mock implementation
            let errorMessage = error.localizedDescription
            print("⚠️ MLX not available, using mock implementation: \(errorMessage)")
            
            // Check if it's a Metal library error
            if errorMessage.contains("metal") || 
               errorMessage.contains("steel_attention") || 
               errorMessage.contains("Unable to load function") ||
               errorMessage.contains("Function") && errorMessage.contains("was not found in the library") {
                print("🔧 Detected Metal library error - this is expected in some environments")
            }
            
            try await loadMockModel(progress: progress)
        }
        #else
        // Use mock implementation
        try await loadMockModel(progress: progress)
        #endif
    }
    
    #if canImport(MLX) && canImport(MLXLLM) && canImport(MLXLMCommon)
    private func loadMLXModel(progress: @escaping @Sendable (Double) -> Void) async throws {
        logger.info("🔧 Attempting to load MLX model: \(self.config.name)")
        
        // Set GPU memory limits
        MLX.GPU.set(cacheLimit: 512 * 1024 * 1024) // 512MB
        
        // Create MLX configuration
        let mlxConfig = MLXLMCommon.ModelConfiguration(
            id: self.config.hubId,
            defaultPrompt: self.config.defaultSystemPrompt ?? "Hello, how can I help you?"
        )
        
        // Load model container with comprehensive error handling
        let modelContainer: MLXLMCommon.ModelContainer
        do {
            modelContainer = try await LLMModelFactory.shared.loadContainer(
                configuration: mlxConfig
            ) { prog in
                progress(prog.fractionCompleted)
            }
        } catch {
            // Convert MLX errors to our error type
            let errorMessage = error.localizedDescription
            logger.error("❌ MLX model loading failed: \(errorMessage)")
            
            // Check for specific MLX runtime errors
            if errorMessage.contains("metal") || 
               errorMessage.contains("steel_attention") || 
               errorMessage.contains("Unable to load function") ||
               errorMessage.contains("Function") && errorMessage.contains("was not found in the library") ||
               errorMessage.contains("File not found") {
                throw MLXEngineError.mlxRuntimeError("MLX runtime not available: \(errorMessage)")
            } else {
                throw MLXEngineError.loadingFailed("Failed to load MLX model: \(errorMessage)")
            }
        }
        
        self.modelContainer = modelContainer
        
        // Create chat session
        let generateParameters = MLXLMCommon.GenerateParameters(
            maxTokens: self.maxTokens,
            temperature: 0.7,
            topP: 0.9
        )
        
        self.chatSession = MLXLMCommon.ChatSession(
            modelContainer,
            instructions: self.config.defaultSystemPrompt,
            generateParameters: generateParameters
        )
        
        self.mlxAvailable = true
        logger.info("✅ MLX model loaded successfully")
    }
    #endif
    
    private func loadMockModel(progress: @escaping @Sendable (Double) -> Void) async throws {
        // Simulate loading progress
        for i in 1...10 {
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
            progress(Double(i) / 10.0)
        }
        print("✅ Mock model loaded successfully")
    }
    
    public func generate(_ prompt: String, params: GenerateParams = .init()) async throws -> String {
        guard !isUnloaded else { throw EngineError.unloaded }
        
        #if canImport(MLX) && canImport(MLXLLM) && canImport(MLXLMCommon)
        if mlxAvailable, chatSession != nil {
            do {
                return try await generateWithMLX(prompt: prompt, params: params, chatSession: self.chatSession!)
            } catch {
                // If MLX generation fails, fall back to mock
                let errorMessage = error.localizedDescription
                logger.error("⚠️ MLX generation failed, falling back to mock: \(errorMessage)")
                
                // Check for fatal MLX runtime errors
                if errorMessage.contains("metal") || 
                   errorMessage.contains("steel_attention") || 
                   errorMessage.contains("Unable to load function") ||
                   errorMessage.contains("Function") && errorMessage.contains("was not found in the library") ||
                   errorMessage.contains("fatal") ||
                   errorMessage.contains("Fatal") {
                    logger.error("❌ Detected fatal MLX runtime error, disabling MLX for future requests")
                    mlxAvailable = false
                    chatSession = nil
                    modelContainer = nil
                }
                
                return try await generateMock(prompt: prompt, params: params)
            }
        }
        #endif
        
        return try await generateMock(prompt: prompt, params: params)
    }
    
    public func stream(_ prompt: String, params: GenerateParams = .init()) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task { @Sendable in
                do {
                    guard !self.isUnloaded else {
                        continuation.finish(throwing: EngineError.unloaded)
                        return
                    }
                    
                    #if canImport(MLX) && canImport(MLXLLM) && canImport(MLXLMCommon)
                    if self.mlxAvailable, self.chatSession != nil {
                        do {
                            try await self.streamWithMLX(prompt: prompt, params: params, chatSession: self.chatSession!, continuation: continuation)
                        } catch {
                            // If MLX streaming fails, fall back to mock
                            let errorMessage = error.localizedDescription
                            self.logger.error("⚠️ MLX streaming failed, falling back to mock: \(errorMessage)")
                            
                            // Check for fatal MLX runtime errors
                            if errorMessage.contains("metal") || 
                               errorMessage.contains("steel_attention") || 
                               errorMessage.contains("Unable to load function") ||
                               errorMessage.contains("Function") && errorMessage.contains("was not found in the library") ||
                               errorMessage.contains("fatal") ||
                               errorMessage.contains("Fatal") {
                                self.logger.error("❌ Detected fatal MLX runtime error, disabling MLX for future requests")
                                self.mlxAvailable = false
                                self.chatSession = nil
                                self.modelContainer = nil
                            }
                            
                            try await self.streamMock(prompt: prompt, params: params, continuation: continuation)
                        }
                    } else {
                        try await self.streamMock(prompt: prompt, params: params, continuation: continuation)
                    }
                    #else
                    try await self.streamMock(prompt: prompt, params: params, continuation: continuation)
                    #endif
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    public func unload() {
        isUnloaded = true
        
        #if canImport(MLX) && canImport(MLXLLM) && canImport(MLXLMCommon)
        if mlxAvailable {
            chatSession = nil
            modelContainer = nil
            mlxAvailable = false
            MLX.GPU.clearCache()
            logger.info("✅ MLX model unloaded")
        }
        #endif
        
        print("✅ Model unloaded")
    }
    
    // MARK: - MLX Implementation
    
    #if canImport(MLX) && canImport(MLXLLM) && canImport(MLXLMCommon)
    private func generateWithMLX(prompt: String, params: GenerateParams, chatSession: MLXLMCommon.ChatSession) async throws -> String {
        logger.info("🤖 Generating with MLX")
        
        // Update parameters if needed
        let generateParameters = MLXLMCommon.GenerateParameters(
            maxTokens: params.maxTokens,
            temperature: Float(params.temperature),
            topP: Float(params.topP)
        )
        
        let newChatSession = MLXLMCommon.ChatSession(
            modelContainer!,
            instructions: config.defaultSystemPrompt,
            generateParameters: generateParameters
        )
        
        let result = try await newChatSession.respond(to: prompt)
        logger.info("✅ MLX generation completed")
        
        return result
    }
    
    private func streamWithMLX(prompt: String, params: GenerateParams, chatSession: MLXLMCommon.ChatSession, continuation: AsyncThrowingStream<String, Error>.Continuation) async throws {
        logger.info("🤖 Streaming with MLX")
        
        let generateParameters = MLXLMCommon.GenerateParameters(
            maxTokens: params.maxTokens,
            temperature: Float(params.temperature),
            topP: Float(params.topP)
        )
        
        let newChatSession = MLXLMCommon.ChatSession(
            modelContainer!,
            instructions: config.defaultSystemPrompt,
            generateParameters: generateParameters
        )
        
        let stream = newChatSession.streamResponse(to: prompt)
        
        for try await chunk in stream {
            continuation.yield(chunk)
        }
        
        continuation.finish()
        logger.info("✅ MLX streaming completed")
    }
    #endif
    
    // MARK: - Mock Implementation
    
    private func generateMock(prompt: String, params: GenerateParams) async throws -> String {
        // Simulate processing time
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        
        return "[Mock Response] This is a simulated response to: '\(prompt)'. Temperature: \(params.temperature), Max Tokens: \(params.maxTokens)"
    }
    
    private func streamMock(prompt: String, params: GenerateParams, continuation: AsyncThrowingStream<String, Error>.Continuation) async throws {
        let response = "[Mock Streaming] This is a simulated streaming response to: '\(prompt)' "
        let tokens = response.components(separatedBy: " ")
        
        for token in tokens {
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
            continuation.yield(token + " ")
        }
        
        continuation.finish()
    }
}

// MARK: - Error Types

public enum EngineError: LocalizedError {
    case unloaded
    
    public var errorDescription: String? {
        switch self {
        case .unloaded:
            return "Engine has been unloaded"
        }
    }
}

public enum MLXEngineError: Error, LocalizedError {
    case mlxNotAvailable(String)
    case mlxRuntimeError(String)
    case modelNotLoaded
    case generationFailed(String)
    case loadingFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .mlxNotAvailable(let reason):
            return "MLX is not available: \(reason)"
        case .mlxRuntimeError(let reason):
            return "MLX runtime error: \(reason)"
        case .modelNotLoaded:
            return "No model is currently loaded"
        case .generationFailed(let reason):
            return "Text generation failed: \(reason)"
        case .loadingFailed(let reason):
            return "Model loading failed: \(reason)"
        }
    }
}

// MARK: - Platform Detection

#if targetEnvironment(simulator)
/// Error thrown when trying to use MLX on iOS Simulator
public enum SimulatorNotSupported: Error, LocalizedError {
    case mlxNotAvailable
    
    public var errorDescription: String? {
        return "MLX is not available on iOS Simulator. Please use a physical device or macOS."
    }
}
#endif 
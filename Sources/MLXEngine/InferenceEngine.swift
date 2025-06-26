import Foundation

#if canImport(MLX) && canImport(MLXLLM) && canImport(MLXLMCommon)
import MLX
import MLXLLM
import MLXLMCommon
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
    private var mlxAvailable = false
    #endif
    
    private init(config: ModelConfiguration) {
        self.config = config
        self.maxTokens = config.maxTokens
    }
    
    public static func loadModel(_ config: ModelConfiguration, progress: @escaping @Sendable (Double) -> Void = { _ in }) async throws -> InferenceEngine {
        #if canImport(MLX) && canImport(MLXLLM) && canImport(MLXLMCommon)
        AppLogger.shared.info("InferenceEngine", "[DIAGNOSTIC] MLX, MLXLLM, and MLXLMCommon are available at compile time.")
        #else
        AppLogger.shared.info("InferenceEngine", "[DIAGNOSTIC] MLX, MLXLLM, or MLXLMCommon are NOT available at compile time.")
        #endif
        let engine = InferenceEngine(config: config)
        try await engine.loadModelInternal(progress: progress)
        return engine
    }
    
    private func loadModelInternal(progress: @escaping @Sendable (Double) -> Void) async throws {
        #if canImport(MLX) && canImport(MLXLLM) && canImport(MLXLMCommon)
        AppLogger.shared.info("InferenceEngine", "[DIAGNOSTIC] Entering MLX model load logic. MLX should be available.", context: ["hubId": config.hubId])
        if config.hubId.hasPrefix("mock/") {
            AppLogger.shared.info("InferenceEngine", "🔧 Using mock implementation for test model", context: ["model": config.name])
            try await loadMockModel(progress: progress)
            return
        }
        do {
            try await loadMLXModel(progress: progress)
        } catch {
            let errorMessage = error.localizedDescription
            AppLogger.shared.error("InferenceEngine", "⚠️ MLX not available, using mock implementation", context: ["error": errorMessage])
            if errorMessage.contains("metal") || 
               errorMessage.contains("steel_attention") || 
               errorMessage.contains("Unable to load function") ||
               errorMessage.contains("Function") && errorMessage.contains("was not found in the library") {
                AppLogger.shared.info("InferenceEngine", "🔧 Detected Metal library error - this is expected in some environments")
            }
            try await loadMockModel(progress: progress)
        }
        #else
        AppLogger.shared.info("InferenceEngine", "[DIAGNOSTIC] MLX not available at runtime. Falling back to mock implementation.", context: ["hubId": config.hubId])
        try await loadMockModel(progress: progress)
        #endif
    }
    
    #if canImport(MLX) && canImport(MLXLLM) && canImport(MLXLMCommon)
    private func loadMLXModel(progress: @escaping @Sendable (Double) -> Void) async throws {
        AppLogger.shared.info("InferenceEngine", "🔧 Attempting to load MLX model", context: ["model": self.config.name])
        // Validate model directory and required files
        let modelDir = try FileManagerService.shared.getModelsDirectory().appendingPathComponent(config.hubId)
        let requiredFiles = ["main.mlx", "config.json", "tokenizer.json"]
        var missingFiles: [String] = []
        for file in requiredFiles {
            let filePath = modelDir.appendingPathComponent(file)
            if !FileManager.default.fileExists(atPath: filePath.path) {
                missingFiles.append(file)
            }
        }
        if !missingFiles.isEmpty {
            let presentFiles = (try? FileManager.default.contentsOfDirectory(atPath: modelDir.path)) ?? []
            AppLogger.shared.error("InferenceEngine", "❌ Required files missing in model directory", context: [
                "modelDir": modelDir.path,
                "missingFiles": missingFiles.joined(separator: ", "),
                "presentFiles": presentFiles.joined(separator: ", ")
            ])
            throw MLXEngineError.loadingFailed("Missing required files: \(missingFiles.joined(separator: ", ")) in \(modelDir.path)")
        }
        MLX.GPU.set(cacheLimit: 20 * 1024 * 1024)
        let mlxConfig = MLXLMCommon.ModelConfiguration(
            id: self.config.hubId,
            defaultPrompt: self.config.defaultSystemPrompt ?? "Hello, how can I help you?"
        )
        let modelContainer: MLXLMCommon.ModelContainer
        do {
            modelContainer = try await LLMModelFactory.shared.loadContainer(
                configuration: mlxConfig
            ) { prog in
                progress(prog.fractionCompleted)
            }
        } catch {
            let errorMessage = error.localizedDescription
            AppLogger.shared.error("InferenceEngine", "❌ MLX model loading failed", context: ["error": errorMessage])
            if errorMessage.contains("metal") || 
               errorMessage.contains("steel_attention") || 
               errorMessage.contains("Unable to load function") ||
               (errorMessage.contains("Function") && errorMessage.contains("was not found in the library")) ||
               errorMessage.contains("File not found") {
                throw MLXEngineError.mlxRuntimeError("MLX runtime not available: \(errorMessage)")
            } else {
                throw MLXEngineError.loadingFailed("Failed to load MLX model: \(errorMessage)")
            }
        }
        self.modelContainer = modelContainer
        self.mlxAvailable = true
        self.chatSession = MLXLMCommon.ChatSession(
            modelContainer,
            instructions: config.defaultSystemPrompt
        )
        AppLogger.shared.info("InferenceEngine", "✅ MLX model loaded successfully", context: ["model": self.config.name])
    }
    #endif
    
    private func loadMockModel(progress: @escaping @Sendable (Double) -> Void) async throws {
        AppLogger.shared.info("InferenceEngine", "✅ Mock model loaded successfully", context: ["model": config.name])
        // Simulate loading progress
        for i in 1...10 {
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
            progress(Double(i) / 10.0)
        }
    }
    
    public func generate(_ prompt: String, params: GenerateParams = .init()) async throws -> String {
        guard !isUnloaded else { throw EngineError.unloaded }
        
        #if canImport(MLX) && canImport(MLXLLM) && canImport(MLXLMCommon)
        AppLogger.shared.info("InferenceEngine", "[DIAGNOSTIC] MLX, MLXLLM, and MLXLMCommon are available at runtime for inference.")
        if mlxAvailable, let chatSession = chatSession {
            do {
                return try await generateWithMLX(prompt: prompt, params: params, chatSession: chatSession)
            } catch {
                let errorMessage = error.localizedDescription
                AppLogger.shared.error("InferenceEngine", "[DIAGNOSTIC] MLX inference error", context: ["error": errorMessage])
                AppLogger.shared.error("InferenceEngine", "⚠️ MLX generation failed, falling back to mock", context: ["error": errorMessage])
                if errorMessage.contains("metal") || 
                   errorMessage.contains("steel_attention") || 
                   errorMessage.contains("Unable to load function") ||
                   errorMessage.contains("Function") && errorMessage.contains("was not found in the library") ||
                   errorMessage.contains("fatal") ||
                   errorMessage.contains("Fatal") {
                    AppLogger.shared.error("InferenceEngine", "❌ Detected fatal MLX runtime error, disabling MLX for future requests")
                    mlxAvailable = false
                    self.chatSession = nil
                    self.modelContainer = nil
                }
                return try await generateMock(prompt: prompt, params: params)
            }
        } else {
            AppLogger.shared.info("InferenceEngine", "[DIAGNOSTIC] MLX is not available for inference.", context: ["mlxAvailable": "\(mlxAvailable)", "chatSession": "\(String(describing: chatSession))"])
        }
        #else
        AppLogger.shared.info("InferenceEngine", "[DIAGNOSTIC] MLX not available at runtime for inference. Falling back to mock.")
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
                            AppLogger.shared.error("InferenceEngine", "⚠️ MLX streaming failed, falling back to mock: \(errorMessage)")
                            
                            // Check for fatal MLX runtime errors
                            if errorMessage.contains("metal") || 
                               errorMessage.contains("steel_attention") || 
                               errorMessage.contains("Unable to load function") ||
                               errorMessage.contains("Function") && errorMessage.contains("was not found in the library") ||
                               errorMessage.contains("fatal") ||
                               errorMessage.contains("Fatal") {
                                AppLogger.shared.error("InferenceEngine", "❌ Detected fatal MLX runtime error, disabling MLX for future requests")
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
            AppLogger.shared.info("InferenceEngine", "✅ MLX model unloaded", context: ["model": self.config.name])
        }
        #endif
        
        AppLogger.shared.info("InferenceEngine", "✅ Model unloaded", context: ["model": self.config.name])
    }
    
    // MARK: - MLX Implementation
    
    #if canImport(MLX) && canImport(MLXLLM) && canImport(MLXLMCommon)
    private func generateWithMLX(prompt: String, params: GenerateParams, chatSession: MLXLMCommon.ChatSession) async throws -> String {
        AppLogger.shared.info("InferenceEngine", "🤖 Generating with MLX")
        
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
        AppLogger.shared.info("InferenceEngine", "✅ MLX generation completed")
        
        return result
    }
    
    private func streamWithMLX(prompt: String, params: GenerateParams, chatSession: MLXLMCommon.ChatSession, continuation: AsyncThrowingStream<String, Error>.Continuation) async throws {
        AppLogger.shared.info("InferenceEngine", "🤖 Streaming with MLX")
        
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
        AppLogger.shared.info("InferenceEngine", "✅ MLX streaming completed")
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
    
    /// Returns the set of supported features for this engine instance.
    ///
    /// Use this to check for LoRA, quantization, VLM, embedding, diffusion, custom prompts, or multi-modal support at runtime.
    ///
    /// TODO: Detect and enable these features when implemented:
    ///   - .loraAdapters
    ///   - .quantizationSupport
    ///   - .visionLanguageModels
    ///   - .embeddingModels
    ///   - .diffusionModels
    ///   - .customPrompts
    ///   - .multiModalInput
    public static var supportedFeatures: Set<LLMEngineFeatures> {
        // For now, return empty set (no advanced features yet)
        return []
    }

    /// Loads a LoRA adapter for the current model (stub).
    ///
    /// - Parameter adapterURL: The file URL of the LoRA adapter to load.
    /// - Throws: An error if LoRA is not supported or loading fails.
    public func loadLoRAAdapter(from adapterURL: URL) async throws {
        guard Self.supportedFeatures.contains(.loraAdapters) else {
            throw MLXEngineError.featureNotSupported("LoRA adapters are not supported by this engine.")
        }
        throw MLXEngineError.featureNotSupported("LoRA adapter loading is not implemented yet.")
    }

    /// Applies a loaded LoRA adapter for inference (stub).
    ///
    /// - Parameter adapterName: The name or identifier of the loaded adapter.
    /// - Throws: An error if LoRA is not supported or application fails.
    public func applyLoRAAdapter(named adapterName: String) throws {
        guard Self.supportedFeatures.contains(.loraAdapters) else {
            throw MLXEngineError.featureNotSupported("LoRA adapters are not supported by this engine.")
        }
        throw MLXEngineError.featureNotSupported("LoRA adapter application is not implemented yet.")
    }

    /// Loads a quantization configuration for the current model (stub).
    ///
    /// - Parameter quantizationType: The quantization type to load (e.g., "4bit", "8bit").
    /// - Throws: An error if quantization is not supported or loading fails.
    public func loadQuantization(_ quantizationType: String) async throws {
        guard Self.supportedFeatures.contains(.quantizationSupport) else {
            throw MLXEngineError.featureNotSupported("Quantization is not supported by this engine.")
        }
        throw MLXEngineError.featureNotSupported("Quantization loading is not implemented yet.")
    }

    /// Loads a vision-language model (VLM) component (stub).
    ///
    /// - Throws: An error if VLM is not supported or loading fails.
    public func loadVisionLanguageModel() async throws {
        guard Self.supportedFeatures.contains(.visionLanguageModels) else {
            throw MLXEngineError.featureNotSupported("Vision-language models are not supported by this engine.")
        }
        throw MLXEngineError.featureNotSupported("VLM loading is not implemented yet.")
    }

    /// Loads an embedding model component (stub).
    ///
    /// - Throws: An error if embedding models are not supported or loading fails.
    public func loadEmbeddingModel() async throws {
        guard Self.supportedFeatures.contains(.embeddingModels) else {
            throw MLXEngineError.featureNotSupported("Embedding models are not supported by this engine.")
        }
        throw MLXEngineError.featureNotSupported("Embedding model loading is not implemented yet.")
    }

    /// Loads a diffusion model component (stub).
    ///
    /// - Throws: An error if diffusion models are not supported or loading fails.
    public func loadDiffusionModel() async throws {
        guard Self.supportedFeatures.contains(.diffusionModels) else {
            throw MLXEngineError.featureNotSupported("Diffusion models are not supported by this engine.")
        }
        throw MLXEngineError.featureNotSupported("Diffusion model loading is not implemented yet.")
    }

    /// Sets a custom system/user prompt for the model (stub).
    ///
    /// - Parameter prompt: The custom prompt to set.
    /// - Throws: An error if custom prompts are not supported.
    public func setCustomPrompt(_ prompt: String) throws {
        guard Self.supportedFeatures.contains(.customPrompts) else {
            throw MLXEngineError.featureNotSupported("Custom prompts are not supported by this engine.")
        }
        throw MLXEngineError.featureNotSupported("Custom prompt setting is not implemented yet.")
    }

    /// Loads multi-modal input support (stub).
    ///
    /// - Throws: An error if multi-modal input is not supported or loading fails.
    public func loadMultiModalInput() async throws {
        guard Self.supportedFeatures.contains(.multiModalInput) else {
            throw MLXEngineError.featureNotSupported("Multi-modal input is not supported by this engine.")
        }
        throw MLXEngineError.featureNotSupported("Multi-modal input loading is not implemented yet.")
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
    case featureNotSupported(String)
    
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
        case .featureNotSupported(let reason):
            return "Feature not supported: \(reason)"
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
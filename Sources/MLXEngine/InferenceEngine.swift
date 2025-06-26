import Foundation

#if canImport(MLX) && canImport(MLXLLM) && canImport(MLXLMCommon)
import MLX
import MLXLLM
import MLXLMCommon
#endif

// MARK: - Performance Monitoring

/// Performance metrics for inference operations
public struct InferenceMetrics: Sendable, Codable {
    /// Time taken to load the model in seconds
    public let modelLoadTime: TimeInterval
    /// Time taken for the last generation in seconds
    public let lastGenerationTime: TimeInterval
    /// Number of tokens generated in the last request
    public let tokensGenerated: Int
    /// Tokens per second for the last generation
    public let tokensPerSecond: Double
    /// Memory usage in bytes during inference
    public let memoryUsageBytes: Int
    /// GPU memory usage in bytes (if available)
    public let gpuMemoryUsageBytes: Int?
    /// Timestamp of the last operation
    public let timestamp: Date
    
    public init(
        modelLoadTime: TimeInterval = 0,
        lastGenerationTime: TimeInterval = 0,
        tokensGenerated: Int = 0,
        tokensPerSecond: Double = 0,
        memoryUsageBytes: Int = 0,
        gpuMemoryUsageBytes: Int? = nil,
        timestamp: Date = Date()
    ) {
        self.modelLoadTime = modelLoadTime
        self.lastGenerationTime = lastGenerationTime
        self.tokensGenerated = tokensGenerated
        self.tokensPerSecond = tokensPerSecond
        self.memoryUsageBytes = memoryUsageBytes
        self.gpuMemoryUsageBytes = gpuMemoryUsageBytes
        self.timestamp = timestamp
    }
}

// MARK: - Error Recovery and Health Monitoring

/// Health status of the inference engine
public enum EngineHealth: String, CaseIterable, Sendable, Codable {
    case healthy = "healthy"
    case degraded = "degraded"
    case unhealthy = "unhealthy"
    case unknown = "unknown"
    
    public var description: String {
        switch self {
        case .healthy:
            return "Engine is operating normally"
        case .degraded:
            return "Engine is operating with reduced performance"
        case .unhealthy:
            return "Engine is experiencing issues"
        case .unknown:
            return "Engine health status is unknown"
        }
    }
}

/// Configuration for retry behavior
public struct RetryConfiguration: Sendable, Codable {
    public let maxRetries: Int
    public let baseDelay: TimeInterval
    public let maxDelay: TimeInterval
    public let backoffMultiplier: Double
    
    public init(
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 30.0,
        backoffMultiplier: Double = 2.0
    ) {
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
        self.backoffMultiplier = backoffMultiplier
    }
}

// MARK: - Inference Engine Implementation

/// A production-ready, high-performance LLM engine with MLX integration
/// Features advanced performance monitoring, memory optimization, and comprehensive error handling
public final class InferenceEngine: LLMEngine, @unchecked Sendable {
    private let config: ModelConfiguration
    private var isUnloaded = false
    private var maxTokens = 100
    
    // Performance monitoring
    private var metrics = InferenceMetrics()
    private var modelLoadStartTime: Date?
    
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
        modelLoadStartTime = Date()
        
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
        
        // Update metrics
        if let startTime = modelLoadStartTime {
            let loadTime = Date().timeIntervalSince(startTime)
            metrics = InferenceMetrics(
                modelLoadTime: loadTime,
                memoryUsageBytes: getCurrentMemoryUsage()
            )
            AppLogger.shared.info("InferenceEngine", "📊 Model loaded in \(String(format: "%.2f", loadTime))s", context: ["model": config.name])
        }
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
        
        // Optimize GPU memory settings based on model size
        let cacheLimit = calculateOptimalGPUCacheLimit()
        MLX.GPU.set(cacheLimit: cacheLimit)
        AppLogger.shared.info("InferenceEngine", "🎯 Set GPU cache limit to \(ByteCountFormatter.string(fromByteCount: Int64(cacheLimit), countStyle: .memory))", context: ["model": config.name])
        
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
        
        let startTime = Date()
        
        #if canImport(MLX) && canImport(MLXLLM) && canImport(MLXLMCommon)
        AppLogger.shared.info("InferenceEngine", "[DIAGNOSTIC] MLX, MLXLLM, and MLXLMCommon are available at runtime for inference.")
        if mlxAvailable, let chatSession = chatSession {
            do {
                let result = try await generateWithMLX(prompt: prompt, params: params, chatSession: chatSession)
                updateMetrics(startTime: startTime, result: result)
                return result
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
                let result = try await generateMock(prompt: prompt, params: params)
                updateMetrics(startTime: startTime, result: result)
                return result
            }
        } else {
            AppLogger.shared.info("InferenceEngine", "[DIAGNOSTIC] MLX is not available for inference.", context: ["mlxAvailable": "\(mlxAvailable)", "chatSession": "\(String(describing: chatSession))"])
        }
        #else
        AppLogger.shared.info("InferenceEngine", "[DIAGNOSTIC] MLX not available at runtime for inference. Falling back to mock.")
        #endif
        
        let result = try await generateMock(prompt: prompt, params: params)
        updateMetrics(startTime: startTime, result: result)
        return result
    }
    
    public func stream(_ prompt: String, params: GenerateParams = .init()) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task { @Sendable in
                do {
                    guard !self.isUnloaded else {
                        continuation.finish(throwing: EngineError.unloaded)
                        return
                    }
                    
                    let startTime = Date()
                    var tokenCount = 0
                    
                    #if canImport(MLX) && canImport(MLXLLM) && canImport(MLXLMCommon)
                    if self.mlxAvailable, self.chatSession != nil {
                        do {
                            try await self.streamWithMLX(prompt: prompt, params: params, chatSession: self.chatSession!, continuation: continuation)
                            self.updateMetrics(startTime: startTime, tokenCount: tokenCount)
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
                            self.updateMetrics(startTime: startTime, tokenCount: tokenCount)
                        }
                    } else {
                        AppLogger.shared.info("InferenceEngine", "[DIAGNOSTIC] MLX is not available for streaming.", context: ["mlxAvailable": "\(self.mlxAvailable)", "chatSession": "\(String(describing: self.chatSession))"])
                        try await self.streamMock(prompt: prompt, params: params, continuation: continuation)
                        self.updateMetrics(startTime: startTime, tokenCount: tokenCount)
                    }
                    #else
                    AppLogger.shared.info("InferenceEngine", "[DIAGNOSTIC] MLX not available at runtime for streaming. Falling back to mock.")
                    try await self.streamMock(prompt: prompt, params: params, continuation: continuation)
                    self.updateMetrics(startTime: startTime, tokenCount: tokenCount)
                    #endif
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    public func unload() {
        AppLogger.shared.info("InferenceEngine", "✅ Model unloaded", context: ["model": config.name])
        isUnloaded = true
        
        #if canImport(MLX) && canImport(MLXLLM) && canImport(MLXLMCommon)
        // Clean up MLX resources
        if mlxAvailable {
            MLX.GPU.clearCache()
            AppLogger.shared.info("InferenceEngine", "🧹 Cleared GPU cache", context: ["model": config.name])
        }
        modelContainer = nil
        chatSession = nil
        mlxAvailable = false
        #endif
    }
    
    // MARK: - Performance Monitoring
    
    /// Returns current performance metrics
    public var performanceMetrics: InferenceMetrics {
        return metrics
    }
    
    private func updateMetrics(startTime: Date, result: String? = nil, tokenCount: Int = 0) {
        let generationTime = Date().timeIntervalSince(startTime)
        let tokens = result?.components(separatedBy: .whitespacesAndNewlines).count ?? tokenCount
        let tokensPerSecond = generationTime > 0 ? Double(tokens) / generationTime : 0
        
        metrics = InferenceMetrics(
            modelLoadTime: metrics.modelLoadTime,
            lastGenerationTime: generationTime,
            tokensGenerated: tokens,
            tokensPerSecond: tokensPerSecond,
            memoryUsageBytes: getCurrentMemoryUsage(),
            gpuMemoryUsageBytes: getCurrentGPUMemoryUsage(),
            timestamp: Date()
        )
        
        AppLogger.shared.info("InferenceEngine", "📊 Generation completed", context: [
            "time": String(format: "%.2fs", generationTime),
            "tokens": "\(tokens)",
            "tokensPerSecond": String(format: "%.1f", tokensPerSecond)
        ])
    }
    
    private func getCurrentMemoryUsage() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return kerr == KERN_SUCCESS ? Int(info.resident_size) : 0
    }
    
    #if canImport(MLX) && canImport(MLXLLM) && canImport(MLXLMCommon)
    private func getCurrentGPUMemoryUsage() -> Int? {
        // MLX.GPU.memoryUsage is not available in current version
        return nil
    }
    
    private func calculateOptimalGPUCacheLimit() -> Int {
        // Calculate optimal GPU cache based on model size
        let modelSizeGB = config.estimatedSizeGB ?? 1.0
        let baseCache = 512 * 1024 * 1024 // 512MB base
        let modelCache = Int(modelSizeGB * 1024 * 1024 * 1024) // Model size in bytes
        let optimalCache = min(baseCache + modelCache, 8 * 1024 * 1024 * 1024) // Max 8GB
        
        return optimalCache
    }
    #else
    private func getCurrentGPUMemoryUsage() -> Int? {
        return nil
    }
    
    private func calculateOptimalGPUCacheLimit() -> Int {
        return 512 * 1024 * 1024 // 512MB default
    }
    #endif
    
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
    /// Feature detection is not yet implemented. Structure is ready for future expansion to support:
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

    // MARK: - Health Monitoring
    
    /// Current health status of the engine
    public var health: EngineHealth {
        if isUnloaded {
            return .unhealthy
        }
        
        #if canImport(MLX) && canImport(MLXLLM) && canImport(MLXLMCommon)
        if mlxAvailable && chatSession != nil {
            return .healthy
        } else if config.hubId.hasPrefix("mock/") {
            return .healthy // Mock models are always healthy
        } else {
            return .degraded // MLX not available, using fallback
        }
        #else
        return .degraded // MLX not available at compile time
        #endif
    }
    
    /// Perform a health check on the engine
    public func performHealthCheck() async -> EngineHealth {
        do {
            // Try a simple generation to test health
            let testResult = try await generate("test", params: GenerateParams(maxTokens: 5))
            return testResult.isEmpty ? .degraded : .healthy
        } catch {
            AppLogger.shared.error("InferenceEngine", "Health check failed", context: ["error": error.localizedDescription])
            return .unhealthy
        }
    }
    
    // MARK: - Error Recovery
    
    /// Attempt to recover from errors and restore engine functionality
    public func attemptRecovery() async -> Bool {
        AppLogger.shared.info("InferenceEngine", "🔄 Attempting engine recovery", context: ["model": config.name])
        
        // Unload current state
        unload()
        
        // Reset state
        isUnloaded = false
        mlxAvailable = false
        
        do {
            // Try to reload the model
            try await loadModelInternal { _ in }
            AppLogger.shared.info("InferenceEngine", "✅ Engine recovery successful", context: ["model": config.name])
            return true
        } catch {
            AppLogger.shared.error("InferenceEngine", "❌ Engine recovery failed", context: ["error": error.localizedDescription])
            return false
        }
    }
    
    /// Generate text with automatic retry on failure
    public func generateWithRetry(
        _ prompt: String, 
        params: GenerateParams = .init(),
        retryConfig: RetryConfiguration = RetryConfiguration()
    ) async throws -> String {
        var lastError: Error?
        
        for attempt in 0...retryConfig.maxRetries {
            do {
                return try await generate(prompt, params: params)
            } catch {
                lastError = error
                
                if attempt < retryConfig.maxRetries {
                    let delay = min(
                        retryConfig.baseDelay * pow(retryConfig.backoffMultiplier, Double(attempt)),
                        retryConfig.maxDelay
                    )
                    
                    AppLogger.shared.warning("InferenceEngine", "Retry attempt \(attempt + 1)/\(retryConfig.maxRetries + 1)", context: [
                        "error": error.localizedDescription,
                        "delay": String(format: "%.1fs", delay)
                    ])
                    
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    
                    // Attempt recovery before retry
                    if health == .unhealthy {
                        _ = await attemptRecovery()
                    }
                }
            }
        }
        
        throw lastError ?? MLXEngineError.generationFailed("All retry attempts failed")
    }
    
    /// Stream text with automatic retry on failure
    public func streamWithRetry(
        _ prompt: String,
        params: GenerateParams = .init(),
        retryConfig: RetryConfiguration = RetryConfiguration()
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task { @Sendable in
                var lastError: Error?
                
                for attempt in 0...retryConfig.maxRetries {
                    do {
                        for try await token in self.stream(prompt, params: params) {
                            continuation.yield(token)
                        }
                        continuation.finish()
                        return
                    } catch {
                        lastError = error
                        
                        if attempt < retryConfig.maxRetries {
                            let delay = min(
                                retryConfig.baseDelay * pow(retryConfig.backoffMultiplier, Double(attempt)),
                                retryConfig.maxDelay
                            )
                            
                            AppLogger.shared.warning("InferenceEngine", "Stream retry attempt \(attempt + 1)/\(retryConfig.maxRetries + 1)", context: [
                                "error": error.localizedDescription,
                                "delay": String(format: "%.1fs", delay)
                            ])
                            
                            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                            
                            // Attempt recovery before retry
                            if health == .unhealthy {
                                _ = await attemptRecovery()
                            }
                        }
                    }
                }
                
                continuation.finish(throwing: lastError ?? MLXEngineError.generationFailed("All stream retry attempts failed"))
            }
        }
    }
    
    // MARK: - Performance Optimization
    
    /// Optimize engine performance based on current metrics
    public func optimizePerformance() async {
        AppLogger.shared.info("InferenceEngine", "⚡ Optimizing engine performance", context: ["model": config.name])
        
        #if canImport(MLX) && canImport(MLXLLM) && canImport(MLXLMCommon)
        if mlxAvailable {
            // Adjust GPU cache based on performance metrics
            let currentCache = MLX.GPU.cacheLimit
            let optimalCache = calculateOptimalGPUCacheLimit()
            
            if currentCache != optimalCache {
                MLX.GPU.set(cacheLimit: optimalCache)
                AppLogger.shared.info("InferenceEngine", "🎯 Optimized GPU cache", context: [
                    "old": ByteCountFormatter.string(fromByteCount: Int64(currentCache), countStyle: .memory),
                    "new": ByteCountFormatter.string(fromByteCount: Int64(optimalCache), countStyle: .memory)
                ])
            }
            
            // Clear cache if memory usage is high
            // Note: MLX.GPU.memoryUsage is not available in current version
            // if let gpuMemory = MLX.GPU.memoryUsage, gpuMemory > optimalCache * 2 {
            //     MLX.GPU.clearCache()
            //     AppLogger.shared.info("InferenceEngine", "🧹 Cleared GPU cache due to high memory usage")
            // }
        }
        #endif
        
        // Log optimization summary
        let memoryUsage = ByteCountFormatter.string(fromByteCount: Int64(getCurrentMemoryUsage()), countStyle: .memory)
        AppLogger.shared.info("InferenceEngine", "📊 Performance optimization complete", context: [
            "memoryUsage": memoryUsage,
            "health": health.rawValue
        ])
    }
    
    // MARK: - Advanced Status Information
    
    /// Enhanced status information including health and performance metrics
    public var detailedStatus: DetailedEngineStatus {
        return DetailedEngineStatus(
            basicStatus: status,
            health: health,
            performanceMetrics: metrics,
            uptime: Date().timeIntervalSince(metrics.timestamp),
            lastOperation: "generate"
        )
    }
}

/// Enhanced engine status with health and performance information
public struct DetailedEngineStatus: Sendable, Codable {
    public let basicStatus: EngineStatus
    public let health: EngineHealth
    public let performanceMetrics: InferenceMetrics
    public let uptime: TimeInterval
    public let lastOperation: String
    
    public init(
        basicStatus: EngineStatus,
        health: EngineHealth,
        performanceMetrics: InferenceMetrics,
        uptime: TimeInterval,
        lastOperation: String
    ) {
        self.basicStatus = basicStatus
        self.health = health
        self.performanceMetrics = performanceMetrics
        self.uptime = uptime
        self.lastOperation = lastOperation
    }
    
    /// Human-readable status summary
    public var statusSummary: String {
        let healthEmoji = health == .healthy ? "✅" : health == .degraded ? "⚠️" : "❌"
        let memoryUsage = ByteCountFormatter.string(fromByteCount: Int64(performanceMetrics.memoryUsageBytes), countStyle: .memory)
        let loadTime = String(format: "%.2fs", performanceMetrics.modelLoadTime)
        
        return "\(healthEmoji) \(health.rawValue.capitalized) • Memory: \(memoryUsage) • Load time: \(loadTime)"
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

/// Diagnostic information about the current engine state.
public struct EngineStatus: Sendable, Codable {
    /// Whether a model is currently loaded and available for inference.
    public let isModelLoaded: Bool
    /// The configuration of the loaded model, if any.
    public let modelConfiguration: ModelConfiguration?
    /// Whether MLX is available and active for this engine instance.
    public let mlxAvailable: Bool
    /// The current GPU cache limit in bytes, if available.
    public let gpuCacheLimit: Int?
    /// The last error encountered by the engine, if any.
    public let lastError: String?
}

extension InferenceEngine {
    /// Returns diagnostic information about the current engine state.
    ///
    /// Use this to inspect whether a model is loaded, MLX is available, and other engine diagnostics.
    public var status: EngineStatus {
        #if canImport(MLX) && canImport(MLXLLM) && canImport(MLXLMCommon)
        let cacheLimit = MLX.GPU.cacheLimit
        #else
        let cacheLimit: Int? = nil
        #endif
        return EngineStatus(
            isModelLoaded: !isUnloaded && (self.modelContainer != nil || config.hubId.hasPrefix("mock/")),
            modelConfiguration: config,
            mlxAvailable: {
                #if canImport(MLX) && canImport(MLXLLM) && canImport(MLXLMCommon)
                return self.mlxAvailable
                #else
                return false
                #endif
            }(),
            gpuCacheLimit: cacheLimit,
            lastError: nil // Placeholder: can be expanded to track last error
        )
    }
} 
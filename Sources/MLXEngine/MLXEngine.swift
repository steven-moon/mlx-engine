//
// MLXEngine.swift
//
// Usage Example:
//
// import MLXEngine
//
// let config = ModelConfiguration(
//     name: "Qwen 0.5B Chat",
//     hubId: "mlx-community/Qwen1.5-0.5B-Chat-4bit",
//     description: "Qwen 0.5B Chat model (4-bit quantized)",
//     parameters: "0.5B",
//     quantization: "4bit",
//     architecture: "Qwen",
//     maxTokens: 4096
// )
//
// Task {
//     let engine = try await InferenceEngine.loadModel(config) { progress in
//         print("Loading progress: \(progress * 100)%")
//     }
//     let result = try await engine.generate("Hello, world!", params: .init())
//     print(result)
// }
//

import Foundation
import CommonCrypto
import MLX
import MLXLLM
import MLXLMCommon
import Metal

// MARK: - Core Types

/// Configuration for MLX-based models
public struct ModelConfiguration: Codable, Sendable {
    // MARK: - Core Fields
    public let name: String
    public let hubId: String
    public let description: String
    public var parameters: String? // Optional
    public var quantization: String? // Optional
    public var architecture: String? // Optional
    public let maxTokens: Int
    public let estimatedSizeGB: Double? // Optional
    public let defaultSystemPrompt: String? // Optional
    public let endOfTextTokens: [String]? // Optional
    // New/advanced fields
    public let modelType: ModelType
    public let gpuCacheLimit: Int
    public let features: Set<LLMEngineFeatures>
    // Download/engine metadata (legacy/test support)
    public var engineType: String?
    public var downloadURL: String?
    public var isDownloaded: Bool?
    public var localPath: String?

    // MARK: - Main Initializer
    public init(
        name: String,
        hubId: String,
        description: String = "",
        parameters: String? = nil,
        quantization: String? = nil,
        architecture: String? = nil,
        maxTokens: Int = 1024,
        estimatedSizeGB: Double? = nil,
        defaultSystemPrompt: String? = nil,
        endOfTextTokens: [String]? = nil,
        modelType: ModelType = .llm,
        gpuCacheLimit: Int = 512 * 1024 * 1024,
        features: Set<LLMEngineFeatures> = [],
        engineType: String? = nil,
        downloadURL: String? = nil,
        isDownloaded: Bool? = nil,
        localPath: String? = nil
    ) {
        self.name = name
        self.hubId = hubId
        self.description = description
        self.parameters = parameters
        self.quantization = quantization
        self.architecture = architecture
        self.maxTokens = maxTokens
        self.estimatedSizeGB = estimatedSizeGB
        self.defaultSystemPrompt = defaultSystemPrompt
        self.endOfTextTokens = endOfTextTokens
        self.modelType = modelType
        self.gpuCacheLimit = gpuCacheLimit
        self.features = features
        self.engineType = engineType
        self.downloadURL = downloadURL
        self.isDownloaded = isDownloaded
        self.localPath = localPath
    }

    // MARK: - Legacy/Minimal Initializer for Backward Compatibility
    public init(
        name: String,
        hubId: String,
        description: String = "",
        maxTokens: Int = 1024,
        estimatedSizeGB: Double? = nil,
        defaultSystemPrompt: String? = nil
    ) {
        self.init(
            name: name,
            hubId: hubId,
            description: description,
            parameters: nil,
            quantization: nil,
            architecture: nil,
            maxTokens: maxTokens,
            estimatedSizeGB: estimatedSizeGB,
            defaultSystemPrompt: defaultSystemPrompt,
            endOfTextTokens: nil,
            modelType: .llm,
            gpuCacheLimit: 512 * 1024 * 1024,
            features: [],
            engineType: nil,
            downloadURL: nil,
            isDownloaded: nil,
            localPath: nil
        )
    }

    // MARK: - Computed Properties for Compatibility
    public var isSmallModel: Bool {
        if let params = parameters?.lowercased() {
            return params.contains("0.5b") || params.contains("1b") || params.contains("1.5b") || params.contains("2b") || params.contains("3b")
        }
        return false
    }
    public var displaySize: String {
        if let size = estimatedSizeGB {
            return String(format: "%.1f GB", size)
        }
        return "Unknown"
    }
    public var displayInfo: String {
        let arch = architecture ?? "?"
        let params = parameters ?? "?"
        let quant = quantization ?? "?"
        return "\(arch) • \(params) • \(quant)"
    }
    public var estimatedMemoryGB: Double {
        estimatedSizeGB ?? 0.0
    }
    public var maxSequenceLength: Int { maxTokens }
    public var maxCacheSize: Int { gpuCacheLimit }
    // Add more helpers as needed

    public func withExtractedMetadata() -> ModelConfiguration {
        // Stub: return self for now
        return self
    }
    public mutating func extractMetadataFromId() {
        // Stub: do nothing for now
    }
}

/// Model types supported by MLXEngine
public enum ModelType: String, CaseIterable, Codable, Sendable {
    case llm = "llm"
    case vlm = "vlm"
    case embedding = "embedding"
    case diffusion = "diffusion"
}

/// Generation parameters for text generation
public struct GenerateParams: Codable, Sendable {
    /// Maximum number of tokens to generate
    public var maxTokens: Int
    
    /// Temperature for sampling (0.0 to 2.0)
    public var temperature: Double
    
    /// Top-p sampling parameter (0.0 to 1.0)
    public var topP: Double
    
    /// Top-k sampling parameter
    public var topK: Int
    
    /// Stop sequences
    public var stopTokens: [String]
    
    /// Repetition penalty
    public let repetitionPenalty: Float
    
    /// Initializes generation parameters
    /// - Parameters:
    ///   - maxTokens: Maximum tokens to generate
    ///   - temperature: Sampling temperature
    ///   - topP: Top-p sampling parameter
    ///   - topK: Top-k sampling parameter
    ///   - stopSequences: Stop sequences
    ///   - repetitionPenalty: Repetition penalty
    public init(maxTokens: Int = 128, temperature: Double = 0.7, topP: Double = 0.9, topK: Int = 40, stopTokens: [String] = [], repetitionPenalty: Float = 1.0) {
        self.maxTokens = maxTokens
        self.temperature = temperature
        self.topP = topP
        self.topK = topK
        self.stopTokens = stopTokens
        self.repetitionPenalty = repetitionPenalty
    }
}

/// Image generation parameters
public struct ImageGenerationParams {
    /// Image width
    public let width: Int
    
    /// Image height
    public let height: Int
    
    /// Number of denoising steps
    public let steps: Int
    
    /// Guidance scale
    public let guidanceScale: Float
    
    /// Initializes image generation parameters
    /// - Parameters:
    ///   - width: Image width
    ///   - height: Image height
    ///   - steps: Number of denoising steps
    ///   - guidanceScale: Guidance scale
    public init(
        width: Int = 512,
        height: Int = 512,
        steps: Int = 20,
        guidanceScale: Float = 7.5
    ) {
        self.width = width
        self.height = height
        self.steps = steps
        self.guidanceScale = guidanceScale
    }
}

/// Feature flags for experimental or optional engine features.
///
/// Use these to check for support and enable/disable features at runtime.
public enum LLMEngineFeatures: String, CaseIterable, Codable, Sendable {
    /// Enable LoRA adapter support (training/inference)
    case loraAdapters
    /// Enable quantization support (4bit, 8bit, fp16, etc.)
    case quantizationSupport
    /// Enable vision-language model (VLM) support
    case visionLanguageModels
    /// Enable embedding model support (text embedding, semantic search)
    case embeddingModels
    /// Enable diffusion model support (image generation)
    case diffusionModels
    /// Enable custom system/user prompt support
    case customPrompts
    /// Enable multi-modal input (text, image, etc.)
    case multiModalInput
    /// Enable model training and fine-tuning
    case modelTraining
    /// Enable model evaluation and benchmarking
    case modelEvaluation
    /// Enable conversation memory and context management
    case conversationMemory
    /// Enable streaming text generation
    case streamingGeneration
    /// Enable batch processing for multiple inputs
    case batchProcessing
    /// Enable model caching and optimization
    case modelCaching
    /// Enable performance monitoring and metrics
    case performanceMonitoring
    /// Enable model conversion and format support
    case modelConversion
    /// Enable distributed inference across devices
    case distributedInference
    /// Enable model compression and optimization
    case modelCompression
    /// Enable custom tokenizer support
    case customTokenizers
    /// Enable model versioning and management
    case modelVersioning
    /// Enable secure model loading and validation
    case secureModelLoading
    /// Enable model explainability and interpretability
    case modelExplainability
    // Add future feature flags here
}

/// Protocol for engines capable of LLM inference.
///
/// Conformers must be concurrency-safe and support async/await.
public protocol LLMEngine: Sendable {
    /// Loads a model with the specified configuration and progress callback.
    static func loadModel(_ config: ModelConfiguration, progress: @escaping @Sendable (Double) -> Void) async throws -> Self
    /// Generates text from a prompt using one-shot completion.
    func generate(_ prompt: String, params: GenerateParams) async throws -> String
    /// Generates text from a prompt using streaming completion.
    func stream(_ prompt: String, params: GenerateParams) -> AsyncThrowingStream<String, Error>
    /// Unloads the model and frees associated resources.
    func unload()
}

// MARK: - File Manager Service



// MARK: - Model Downloader

/// Downloads and manages MLX models from Hugging Face Hub.
///
/// Use this actor to search for, download, and verify models.
///
/// Example:
/// ```swift
/// let downloader = ModelDownloader()
/// let models = try await downloader.searchModels(query: "qwen")
/// ```
public actor ModelDownloader {
    private let huggingFaceAPI = HuggingFaceAPI.shared
    private let fileManager = FileManagerService.shared
    private let optimizedDownloader: OptimizedDownloader?
    
    public init() {
        // Try to initialize optimized downloader, fallback to nil if Hub library not available
        #if canImport(Hub)
        self.optimizedDownloader = OptimizedDownloader()
        #else
        self.optimizedDownloader = nil
        #endif
    }
    
    /// Searches for MLX-compatible models on Hugging Face Hub
    public func searchModels(query: String, limit: Int = 20) async throws -> [ModelConfiguration] {
        let huggingFaceModels = try await huggingFaceAPI.searchModels(query: query, limit: limit)
        
        AppLogger.shared.info("MLXEngine", "🔍 Found \(huggingFaceModels.count) models from Hugging Face search")
        
        // Filter for MLX-compatible models and convert to our format
        let filteredModels = huggingFaceModels
            .filter { model in
                // More flexible filtering - include models that might be MLX compatible
                let isMLXCompatible = model.tags?.contains("mlx") == true ||
                    model.id.lowercased().contains("mlx") ||
                    model.id.contains("mlx-community") ||
                    model.id.contains("lmstudio-community") || // Include lmstudio models
                    (model.tags?.contains("text-generation") == true && 
                     (model.id.lowercased().contains("mistral") || 
                      model.id.lowercased().contains("llama") || 
                      model.id.lowercased().contains("qwen") ||
                      model.id.lowercased().contains("phi") ||
                      model.id.lowercased().contains("gemma")))
                
                if !isMLXCompatible {
                    AppLogger.shared.info("MLXEngine", "❌ Filtered out: \(model.id) (tags: \(model.tags?.joined(separator: ", ") ?? "none"))")
                }
                
                return isMLXCompatible
            }
            .map { $0.toModelConfiguration() }
        
        AppLogger.shared.info("MLXEngine", "✅ Kept \(filteredModels.count) MLX-compatible models")
        return filteredModels
    }
    
    /// Downloads a model to the local cache with optimized downloader if available
    public func downloadModel(_ config: ModelConfiguration, progress: @escaping @Sendable (Double) -> Void) async throws -> URL {
        // Generate a correlation ID for this download operation
        let correlationId = UUID().uuidString
        AppLogger.shared.info("MLXEngine", "🚀 Using optimized downloader for faster downloads", context: ["correlationId": correlationId])
        if let optimizedDownloader = optimizedDownloader {
            return try await optimizedDownloader.downloadModelWithResume(config, progress: { prog in
                AppLogger.shared.info("MLXEngine", "[Progress] Downloading model...", context: ["progress": String(format: "%.2f", prog), "correlationId": correlationId])
                progress(prog)
            })
        } else {
            AppLogger.shared.warning("MLXEngine", "⚠️ Using fallback downloader (optimized downloader not available)", context: ["correlationId": correlationId])
            return try await downloadModelFallback(config, progress: { prog in
                AppLogger.shared.info("MLXEngine", "[Progress] Downloading model (fallback)...", context: ["progress": String(format: "%.2f", prog), "correlationId": correlationId])
                progress(prog)
            })
        }
    }
    
    /// Fallback download implementation using the original method (now downloads all files)
    private func downloadModelFallback(_ config: ModelConfiguration, progress: @escaping @Sendable (Double) -> Void) async throws -> URL {
        let modelsDirectory = try fileManager.ensureModelsDirectoryExists()
        let modelDirectory = modelsDirectory.appendingPathComponent(config.hubId)
        try FileManager.default.createDirectory(at: modelDirectory, withIntermediateDirectories: true)
        // Download all files in the repo
        let allFiles = try await huggingFaceAPI.listModelFiles(modelId: config.hubId)
        if allFiles.isEmpty {
            throw NSError(domain: "ModelDownloader", code: -1, userInfo: [NSLocalizedDescriptionKey: "No files found in model repo: \(config.hubId)"])
        }
        for (index, fileName) in allFiles.enumerated() {
            let destinationURL = modelDirectory.appendingPathComponent(fileName)
            let destinationDir = destinationURL.deletingLastPathComponent()
            if !FileManager.default.fileExists(atPath: destinationDir.path) {
                try FileManager.default.createDirectory(at: destinationDir, withIntermediateDirectories: true)
            }
            try await huggingFaceAPI.downloadModel(
                modelId: config.hubId,
                fileName: fileName,
                to: destinationURL
            ) { fileProgress, _, _ in
                let overallProgress = (Double(index) + fileProgress) / Double(allFiles.count)
                progress(overallProgress)
            }
        }
        // Patch: Symlink or copy model.safetensors to main.mlx if main.mlx is missing
        let mainMLXPath = modelDirectory.appendingPathComponent("main.mlx").path
        let safetensorsPath = modelDirectory.appendingPathComponent("model.safetensors").path
        if !FileManager.default.fileExists(atPath: mainMLXPath), FileManager.default.fileExists(atPath: safetensorsPath) {
            do {
                #if os(macOS) || os(Linux)
                try? FileManager.default.removeItem(atPath: mainMLXPath)
                try FileManager.default.createSymbolicLink(atPath: mainMLXPath, withDestinationPath: safetensorsPath)
                #else
                // On iOS/tvOS/watchOS, symlinks may not be allowed; fallback to copy
                try? FileManager.default.removeItem(atPath: mainMLXPath)
                try FileManager.default.copyItem(atPath: safetensorsPath, toPath: mainMLXPath)
                #endif
                AppLogger.shared.info("ModelDownloader", "Patched: Linked model.safetensors to main.mlx for MLX compatibility", context: ["modelDir": modelDirectory.path])
            } catch {
                AppLogger.shared.warning("ModelDownloader", "Failed to patch main.mlx symlink/copy: \(error)", context: ["modelDir": modelDirectory.path])
            }
        }
        return modelDirectory
    }
    
    /// Gets model information before downloading (optimized version if available)
    public func getModelInfo(modelId: String) async throws -> ModelInfo? {
        if let optimizedDownloader = optimizedDownloader {
            return try await optimizedDownloader.getModelInfo(modelId: modelId)
        }
        return nil
    }
    
    /// Verifies file integrity using SHA-256 checksum
    public func verifyFileChecksum(fileURL: URL, expectedSHA256: String) async throws -> Bool {
        let data = try Data(contentsOf: fileURL)
        let calculatedSHA256 = calculateSHA256(data: data)
        return calculatedSHA256.lowercased() == expectedSHA256.lowercased()
    }
    
    /// Simple SHA-256 implementation using CryptoKit
    private func calculateSHA256(data: Data) -> String {
        // Use the global sha256Hex function from SHA256Helper.swift
        return sha256Hex(data: data)
    }
    
    /// Gets the list of downloaded models
    public func getDownloadedModels() async throws -> [ModelConfiguration] {
        // Use optimized downloader if available for better model detection
        if let optimizedDownloader = optimizedDownloader {
            return try await optimizedDownloader.getDownloadedModels()
        }
        
        // Fallback to original implementation
        let modelsDirectory = try fileManager.getModelsDirectory()
        
        guard FileManager.default.fileExists(atPath: modelsDirectory.path) else {
            return []
        }
        
        let modelDirectories = try FileManager.default.contentsOfDirectory(
            at: modelsDirectory,
            includingPropertiesForKeys: nil
        )
        
        return modelDirectories.compactMap { url in
            // Check if this is a model directory (contains model files)
            let hasConfig = FileManager.default.fileExists(atPath: url.appendingPathComponent("config.json").path)
            let hasTokenizer = FileManager.default.fileExists(atPath: url.appendingPathComponent("tokenizer.json").path)
            let hasModel = FileManager.default.fileExists(atPath: url.appendingPathComponent("model.safetensors").path)
            
            guard hasConfig && hasTokenizer && hasModel else { return nil }
            
            // Create a basic configuration for the downloaded model
            return ModelConfiguration(
                name: url.lastPathComponent,
                hubId: url.lastPathComponent,
                description: "Downloaded model"
            )
        }
    }
    
    /// Cleans up incomplete downloads
    public func cleanupIncompleteDownloads() async throws {
        if let optimizedDownloader = optimizedDownloader {
            try await optimizedDownloader.cleanupIncompleteDownloads()
        }
    }
}

/// Main MLXEngine class that provides unified access to MLX-based AI models
/// with automatic Metal library compilation and robust fallback mechanisms.
public final class MLXEngine: LLMEngine, @unchecked Sendable {
    
    /// Engine configuration
    public let configuration: ModelConfiguration
    
    /// Current chat session
    private var currentSession: ChatSession?
    
    /// Metal library for GPU operations
    private var metalLibrary: MTLLibrary?
    
    /// Engine initialization status
    private var isInitialized = false
    
    /// Private initializer
    private init(configuration: ModelConfiguration) {
        self.configuration = configuration
    }
    
    /// Loads a model with the specified configuration and progress callback.
    /// - Parameters:
    ///   - config: Model configuration
    ///   - progress: Progress callback
    /// - Returns: Initialized MLXEngine instance
    /// - Throws: Engine initialization errors
    public static func loadModel(_ config: ModelConfiguration, progress: @escaping @Sendable (Double) -> Void) async throws -> MLXEngine {
        let engine = MLXEngine(configuration: config)
        try await engine.initialize(progress: progress)
        return engine
    }
    
    /// Initializes the engine with Metal library and MLX setup
    /// - Parameter progress: Progress callback
    /// - Throws: Initialization errors
    private func initialize(progress: @escaping @Sendable (Double) -> Void) async throws {
        progress(0.1)
        
        // Initialize Metal library
        try initializeMetalLibrary()
        progress(0.3)
        
        // Set GPU cache limit for memory safety
        MLX.GPU.set(cacheLimit: configuration.gpuCacheLimit)
        progress(0.4)
        
        // Initialize MLX with the model
        try initializeMLX()
        progress(0.6)
        
        // Create chat session
        try await createChatSession()
        progress(0.8)
        
        isInitialized = true
        progress(1.0)
    }
    
    /// Initializes the Metal library with automatic fallback mechanisms
    private func initializeMetalLibrary() throws {
        print("🔧 Initializing Metal library...")
        
        let compilationStatus = MetalLibraryBuilder.buildLibrary()
        
        switch compilationStatus {
        case .success(let library):
            self.metalLibrary = library
            
            // Validate the library
            if MetalLibraryBuilder.validateLibrary(library) {
                print("✅ Metal library initialized successfully")
            } else {
                print("⚠️ Metal library validation failed, but continuing...")
            }
            
        case .failure(let error):
            print("❌ Metal library initialization failed: \(error)")
            
            // Check if we're on iOS Simulator
            #if targetEnvironment(simulator)
            throw LLMEngineError.simulatorNotSupported
            #else
            // On real hardware, try to continue without Metal
            print("⚠️ Continuing without Metal acceleration")
            #endif
            
        case .notSupported(let reason):
            print("⚠️ Metal not supported: \(reason)")
            #if targetEnvironment(simulator)
            throw LLMEngineError.simulatorNotSupported
            #else
            print("⚠️ Continuing without Metal acceleration")
            #endif
        }
    }
    
    /// Initializes MLX with the configured model
    private func initializeMLX() throws {
        print("🚀 Initializing MLX with model: \(configuration.hubId)")
        
        // Set up MLX configuration based on model type
        switch configuration.modelType {
        case .llm:
            try initializeLLM()
        case .vlm:
            try initializeVLM()
        case .embedding:
            try initializeEmbedding()
        case .diffusion:
            try initializeDiffusion()
        }
    }
    
    /// Initializes LLM model
    private func initializeLLM() throws {
        // LLM initialization is handled lazily when needed
        print("📝 LLM model ready for initialization")
    }
    
    /// Initializes VLM model
    private func initializeVLM() throws {
        // VLM initialization is handled lazily when needed
        print("🖼️ VLM model ready for initialization")
    }
    
    /// Initializes embedding model
    private func initializeEmbedding() throws {
        // Embedding initialization is handled lazily when needed
        print("🔍 Embedding model ready for initialization")
    }
    
    /// Initializes diffusion model
    private func initializeDiffusion() throws {
        // Diffusion initialization is handled lazily when needed
        print("🎨 Diffusion model ready for initialization")
    }
    
    /// Creates a chat session
    private func createChatSession() async throws {
        let session = try await ChatSession.create(
            modelConfiguration: configuration,
            metalLibrary: metalLibrary
        )
        currentSession = session
    }
    
    // MARK: - LLMEngine Protocol Implementation
    
    public func generate(_ prompt: String, params: GenerateParams) async throws -> String {
        guard isInitialized else {
            throw LLMEngineError.notInitialized
        }
        
        guard let session = currentSession else {
            throw LLMEngineError.notInitialized
        }
        
        // Generate response
        return try await session.generate(prompt: prompt, parameters: params)
    }
    
    public func stream(_ prompt: String, params: GenerateParams) -> AsyncThrowingStream<String, Error> {
        guard isInitialized, let session = currentSession else {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: LLMEngineError.notInitialized)
            }
        }
        // Bridge async to sync using Task
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let stream = try await session.generateStream(prompt: prompt, parameters: params)
                    for try await token in stream {
                        continuation.yield(token)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    public func unload() {
        print("🧹 Unloading MLXEngine...")
        
        // Clear current session
        currentSession = nil
        
        // Clear Metal library
        metalLibrary = nil
        
        // Reset MLX GPU cache
        MLX.GPU.clearCache()
        
        isInitialized = false
        print("✅ MLXEngine unloaded successfully")
    }
}

public enum LLMEngineError: Error, LocalizedError, Codable, Sendable {
    case notInitialized
    case custom(String)
    case simulatorNotSupported
    
    public var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "Engine not initialized"
        case .custom(let msg):
            return msg
        case .simulatorNotSupported:
            return "MLX is not available on iOS Simulator. Please use a physical device or macOS."
        }
    }
} 
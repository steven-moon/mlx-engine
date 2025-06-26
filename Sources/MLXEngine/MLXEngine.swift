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

// MARK: - Core Types

/// A comprehensive configuration describing an LLM model.
///
/// Use this struct to describe a model you want to load or search for.
///
/// Example:
/// ```swift
/// let config = ModelConfiguration(
///     name: "Qwen 0.5B Chat",
///     hubId: "mlx-community/Qwen1.5-0.5B-Chat-4bit",
///     description: "Qwen 0.5B Chat model (4-bit quantized)",
///     parameters: "0.5B",
///     quantization: "4bit",
///     architecture: "Qwen",
///     maxTokens: 4096
/// )
/// ```
public struct ModelConfiguration: Sendable, Codable, Hashable, Identifiable {
    /// Unique identifier for the model configuration (defaults to hubId)
    public let id: String
    /// Display name for the model
    public let name: String
    /// Hugging Face Hub ID for the model
    public let hubId: String
    /// Human-readable description of the model
    public let description: String
    /// Number of parameters (e.g., "3B"), if available
    public var parameters: String?
    /// Quantization type (e.g., "4bit", "8bit"), if available
    public var quantization: String?
    /// Model architecture (e.g., "Llama", "Qwen"), if available
    public var architecture: String?
    /// Maximum number of tokens supported by the model
    public let maxTokens: Int
    /// Estimated model size in GB, if available
    public let estimatedSizeGB: Double?
    /// Default system prompt for the model, if any
    public let defaultSystemPrompt: String?
    /// End-of-text tokens for the model, if any
    public let endOfTextTokens: [String]?
    /// Engine type (e.g., "mlx", "llama.cpp")
    public var engineType: String?
    /// Download URL for the model (if available)
    public var downloadURL: String?
    /// Whether the model is downloaded locally (for local state)
    public var isDownloaded: Bool?
    /// Local path to the model (if downloaded)
    public var localPath: String?
    
    public init(
        id: String? = nil,
        name: String,
        hubId: String,
        description: String = "",
        parameters: String? = nil,
        quantization: String? = nil,
        architecture: String? = nil,
        maxTokens: Int = 4096,
        estimatedSizeGB: Double? = nil,
        defaultSystemPrompt: String? = nil,
        endOfTextTokens: [String]? = nil,
        engineType: String? = nil,
        downloadURL: String? = nil,
        isDownloaded: Bool? = nil,
        localPath: String? = nil
    ) {
        self.id = id ?? hubId
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
        self.engineType = engineType
        self.downloadURL = downloadURL
        self.isDownloaded = isDownloaded
        self.localPath = localPath
    }
    
    /// Extracts metadata from the hub ID
    public mutating func extractMetadataFromId() {
        let components = hubId.components(separatedBy: "/")
        if components.count >= 2 {
            let modelName = components[1]
            // Extract parameters (support both B and b, flexible patterns)
            if let paramMatch = modelName.range(of: #"\d+\.?\d*[Bb]"#, options: .regularExpression) {
                self.parameters = String(modelName[paramMatch]).uppercased()
            }
            // Extract quantization
            if modelName.lowercased().contains("4bit") {
                self.quantization = "4bit"
            } else if modelName.lowercased().contains("8bit") {
                self.quantization = "8bit"
            } else if modelName.lowercased().contains("fp16") {
                self.quantization = "fp16"
            }
            // Extract architecture
            let lower = modelName.lowercased()
            if lower.contains("qwen") {
                self.architecture = "Qwen"
            } else if lower.contains("llama") {
                self.architecture = "Llama"
            } else if lower.contains("mistral") {
                self.architecture = "Mistral"
            } else if lower.contains("phi") {
                self.architecture = "Phi"
            } else if lower.contains("gemma") {
                self.architecture = "Gemma"
            }
        }
    }
    
    /// Computed property to determine if this is a small model suitable for mobile
    public var isSmallModel: Bool {
        guard let params = parameters?.lowercased() else { return false }
        return params.contains("0.5b") || params.contains("1b") || params.contains("1.5b") || params.contains("2b") || params.contains("3b")
    }
    
    /// Estimated memory requirements in GB
    public var estimatedMemoryGB: Double {
        if let size = estimatedSizeGB {
            return size * 1.2 // Add 20% overhead for inference
        }
        
        guard let params = parameters?.lowercased() else { return 2.0 }
        
        if params.contains("0.5b") { return 1.0 }
        else if params.contains("1b") { return 2.0 }
        else if params.contains("1.5b") { return 3.0 }
        else if params.contains("2b") { return 4.0 }
        else if params.contains("3b") { return 6.0 }
        else if params.contains("7b") { return 14.0 }
        else if params.contains("8b") { return 16.0 }
        else if params.contains("13b") { return 26.0 }
        else { return 8.0 }
    }
    
    /// Returns a display string for the model's size or parameters.
    public var displaySize: String {
        if let estimatedSizeGB = estimatedSizeGB {
            return String(format: "%.1f GB", estimatedSizeGB)
        } else if let params = parameters {
            return params
        }
        return "Unknown"
    }
    
    /// Returns a display string for architecture, parameters, and quantization.
    public var displayInfo: String {
        var info: [String] = []
        if let arch = architecture { info.append(arch) }
        if let params = parameters { info.append(params) }
        if let quant = quantization { info.append(quant) }
        return info.joined(separator: " • ")
    }
    
    /// Extracts metadata from the hubId if not already set.
    public func withExtractedMetadata() -> ModelConfiguration {
        var copy = self
        let components = hubId.components(separatedBy: "/")
        if components.count >= 2 {
            let modelName = components[1].lowercased()
            if copy.parameters == nil {
                if let paramMatch = modelName.range(of: #"\d+\.?\d*b"#, options: .regularExpression) {
                    copy.parameters = String(modelName[paramMatch]).uppercased()
                }
            }
            if copy.quantization == nil {
                if modelName.contains("4bit") { copy.quantization = "4bit" }
                else if modelName.contains("8bit") { copy.quantization = "8bit" }
                else if modelName.contains("fp16") { copy.quantization = "fp16" }
            }
            if copy.architecture == nil {
                if modelName.contains("qwen") { copy.architecture = "Qwen" }
                else if modelName.contains("llama") { copy.architecture = "Llama" }
                else if modelName.contains("mistral") { copy.architecture = "Mistral" }
                else if modelName.contains("phi") { copy.architecture = "Phi" }
                else if modelName.contains("gemma") { copy.architecture = "Gemma" }
                else if modelName.contains("tinyllama") { copy.architecture = "TinyLlama" }
            }
        }
        return copy
    }
}

/// Parameters for text generation.
///
/// Controls the sampling and stopping behavior of the LLM.
public struct GenerateParams: Sendable, Hashable {
    /// Maximum number of tokens to generate
    public var maxTokens: Int
    /// Sampling temperature (higher = more random)
    public var temperature: Double
    /// Nucleus sampling probability
    public var topP: Double
    /// Top-K sampling
    public var topK: Int
    /// Stop generation if any of these tokens are produced
    public var stopTokens: [String]
    
    public init(
        maxTokens: Int = 100,
        temperature: Double = 0.7,
        topP: Double = 0.9,
        topK: Int = 40,
        stopTokens: [String] = []
    ) {
        self.maxTokens = maxTokens
        self.temperature = temperature
        self.topP = topP
        self.topK = topK
        self.stopTokens = stopTokens
    }
}

/// Feature flags for experimental or optional engine features.
///
/// Use these to check for support and enable/disable features at runtime.
public enum LLMEngineFeatures: String, CaseIterable, Sendable {
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
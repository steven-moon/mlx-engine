import Foundation
import CommonCrypto

// MARK: - Core Types

/// A comprehensive configuration describing an LLM model.
public struct ModelConfiguration: Sendable, Codable, Hashable, Identifiable {
    public let id: String
    public let name: String
    public let hubId: String
    public let description: String
    public var parameters: String?
    public var quantization: String?
    public var architecture: String?
    public let maxTokens: Int
    public let estimatedSizeGB: Double?
    public let defaultSystemPrompt: String?
    public let endOfTextTokens: [String]?
    
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
        endOfTextTokens: [String]? = nil
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
    }
    
    /// Extracts metadata from the hub ID
    public mutating func extractMetadataFromId() {
        let components = hubId.components(separatedBy: "/")
        if components.count >= 2 {
            let modelName = components[1]
            
            // Extract parameters
            if let paramMatch = modelName.range(of: #"\d+\.?\d*B"#, options: .regularExpression) {
                self.parameters = String(modelName[paramMatch])
            }
            
            // Extract quantization
            if modelName.contains("4bit") {
                self.quantization = "4bit"
            } else if modelName.contains("8bit") {
                self.quantization = "8bit"
            } else if modelName.contains("fp16") {
                self.quantization = "fp16"
            }
            
            // Extract architecture
            if modelName.lowercased().contains("qwen") {
                self.architecture = "Qwen"
            } else if modelName.lowercased().contains("llama") {
                self.architecture = "Llama"
            } else if modelName.lowercased().contains("mistral") {
                self.architecture = "Mistral"
            } else if modelName.lowercased().contains("phi") {
                self.architecture = "Phi"
            } else if modelName.lowercased().contains("gemma") {
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
}

/// Generation parameters for text generation.
public struct GenerateParams: Sendable, Hashable {
    public var maxTokens: Int
    public var temperature: Double
    public var topP: Double
    public var topK: Int
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

/// A protocol representing a loaded LLM engine.
public protocol LLMEngine: Sendable {
    static func loadModel(_ config: ModelConfiguration, progress: @escaping @Sendable (Double) -> Void) async throws -> Self
    func generate(_ prompt: String, params: GenerateParams) async throws -> String
    func stream(_ prompt: String, params: GenerateParams) -> AsyncThrowingStream<String, Error>
    func unload()
}

// MARK: - File Manager Service



// MARK: - Model Downloader

/// Downloads and manages MLX models from Hugging Face Hub.
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
        
        print("🔍 Found \(huggingFaceModels.count) models from Hugging Face search")
        
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
                    print("❌ Filtered out: \(model.id) (tags: \(model.tags?.joined(separator: ", ") ?? "none"))")
                }
                
                return isMLXCompatible
            }
            .map { $0.toModelConfiguration() }
        
        print("✅ Kept \(filteredModels.count) MLX-compatible models")
        return filteredModels
    }
    
    /// Downloads a model to the local cache with optimized downloader if available
    public func downloadModel(_ config: ModelConfiguration, progress: @escaping @Sendable (Double) -> Void) async throws -> URL {
        // Use optimized downloader if available
        if let optimizedDownloader = optimizedDownloader {
            print("🚀 Using optimized downloader for faster downloads")
            return try await optimizedDownloader.downloadModelWithResume(config, progress: progress)
        } else {
            print("⚠️ Using fallback downloader (optimized downloader not available)")
            return try await downloadModelFallback(config, progress: progress)
        }
    }
    
    /// Fallback download implementation using the original method
    private func downloadModelFallback(_ config: ModelConfiguration, progress: @escaping @Sendable (Double) -> Void) async throws -> URL {
        let modelsDirectory = try fileManager.ensureModelsDirectoryExists()
        let modelDirectory = modelsDirectory.appendingPathComponent(config.hubId)
        
        // Create model directory
        try FileManager.default.createDirectory(at: modelDirectory, withIntermediateDirectories: true)
        
        // Download essential files
        let filesToDownload = ["config.json", "tokenizer.json", "model.safetensors"]
        
        for (index, fileName) in filesToDownload.enumerated() {
            let destinationURL = modelDirectory.appendingPathComponent(fileName)
            
            try await huggingFaceAPI.downloadModel(
                modelId: config.hubId,
                fileName: fileName,
                to: destinationURL
            ) { fileProgress in
                let overallProgress = (Double(index) + fileProgress) / Double(filesToDownload.count)
                progress(overallProgress)
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
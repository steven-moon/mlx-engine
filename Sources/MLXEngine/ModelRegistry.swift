import Foundation

/// Pre-configured collection of popular MLX-compatible models
/// 
/// **Agent Workflow Test**: This comment demonstrates the complete build → test → simulate cycle
public struct ModelRegistry {
    
    // MARK: - Model Type Definitions
    
    /// Model type categories (LLM, VLM, Embedder, Diffusion)
    public enum ModelType: String, CaseIterable {
        case llm = "LLM"           // Large Language Model
        case vlm = "VLM"           // Vision Language Model
        case embedder = "Embedder" // Text Embedding Model
        case diffusion = "Diffusion" // Image Generation Model
        case training = "Training" // Training/Finetuning Models
        case evaluation = "Evaluation" // Model Evaluation Models
        case compression = "Compression" // Model Compression Models
        
        /// Human-readable description of the model type
        public var description: String {
            switch self {
            case .llm:
                return "Text generation and conversation"
            case .vlm:
                return "Image understanding and analysis"
            case .embedder:
                return "Text embedding and semantic search"
            case .diffusion:
                return "Image generation from text"
            case .training:
                return "Model training and fine-tuning"
            case .evaluation:
                return "Model evaluation and benchmarking"
            case .compression:
                return "Model compression and optimization"
            }
        }
        
        /// Required features for this model type
        public var requiredFeatures: Set<LLMEngineFeatures> {
            switch self {
            case .llm:
                return [.streamingGeneration, .conversationMemory]
            case .vlm:
                return [.visionLanguageModels, .multiModalInput, .streamingGeneration]
            case .embedder:
                return [.embeddingModels, .batchProcessing]
            case .diffusion:
                return [.diffusionModels, .multiModalInput]
            case .training:
                return [.modelTraining, .performanceMonitoring]
            case .evaluation:
                return [.modelEvaluation, .performanceMonitoring]
            case .compression:
                return [.modelCompression, .quantizationSupport]
            }
        }
    }
    
    // MARK: - Model Discovery and Filtering
    
    /// Search criteria for finding models
    public struct SearchCriteria {
        public let query: String?
        public let maxParameters: String?
        public let minParameters: String?
        public let architecture: String?
        public let quantization: String?
        public let maxSizeGB: Double?
        public let modelType: ModelType?
        public let isSmallModel: Bool?
        
        public init(
            query: String? = nil,
            maxParameters: String? = nil,
            minParameters: String? = nil,
            architecture: String? = nil,
            quantization: String? = nil,
            maxSizeGB: Double? = nil,
            modelType: ModelType? = nil,
            isSmallModel: Bool? = nil
        ) {
            self.query = query
            self.maxParameters = maxParameters
            self.minParameters = minParameters
            self.architecture = architecture
            self.quantization = quantization
            self.maxSizeGB = maxSizeGB
            self.modelType = modelType
            self.isSmallModel = isSmallModel
        }
    }
    
    /// Search for models matching the given criteria
    public static func searchModels(criteria: SearchCriteria) -> [ModelConfiguration] {
        let allModels = getAllModels()
        
        return allModels.filter { model in
            // Query filter
            if let query = criteria.query, !query.isEmpty {
                let searchText = "\(model.name) \(model.description) \(model.architecture ?? "")".lowercased()
                if !searchText.contains(query.lowercased()) {
                    return false
                }
            }
            
            // Parameter range filter
            if let maxParams = criteria.maxParameters {
                if let modelParams = model.parameters, modelParams > maxParams {
                    return false
                }
            }
            
            if let minParams = criteria.minParameters {
                if let modelParams = model.parameters, modelParams < minParams {
                    return false
                }
            }
            
            // Architecture filter
            if let architecture = criteria.architecture {
                if model.architecture?.lowercased() != architecture.lowercased() {
                    return false
                }
            }
            
            // Quantization filter
            if let quantization = criteria.quantization {
                if model.quantization?.lowercased() != quantization.lowercased() {
                    return false
                }
            }
            
            // Size filter
            if let maxSize = criteria.maxSizeGB {
                if let modelSize = model.estimatedSizeGB, modelSize > maxSize {
                    return false
                }
            }
            
            // Model type filter
            if let modelType = criteria.modelType {
                if !isModelOfType(model, type: modelType) {
                    return false
                }
            }
            
            // Small model filter
            if let isSmall = criteria.isSmallModel {
                if model.isSmallModel != isSmall {
                    return false
                }
            }
            
            return true
        }
    }
    
    /// Search for models with query and type
    public static func searchModels(query: String, type: ModelType) -> [ModelConfiguration] {
        return searchModels(criteria: SearchCriteria(query: query, modelType: type))
    }
    
    /// Get the model type for a given model configuration
    public static func getModelType(_ model: ModelConfiguration) -> ModelType {
        if isModelOfType(model, type: .vlm) {
            return .vlm
        } else if isModelOfType(model, type: .embedder) {
            return .embedder
        } else if isModelOfType(model, type: .diffusion) {
            return .diffusion
        } else {
            return .llm
        }
    }
    
    /// Get recommended models for different use cases
    public static func getRecommendedModels(for useCase: UseCase) -> [ModelConfiguration] {
        switch useCase {
        case .mobileDevelopment:
            return searchModels(criteria: SearchCriteria(
                maxSizeGB: 1.0,
                isSmallModel: true
            ))
        case .desktopDevelopment:
            return searchModels(criteria: SearchCriteria(
                maxSizeGB: 4.0,
                modelType: .llm
            ))
        case .highQualityGeneration:
            return searchModels(criteria: SearchCriteria(
                minParameters: "7B",
                modelType: .llm
            ))
        case .fastInference:
            return searchModels(criteria: SearchCriteria(
                maxParameters: "3B",
                isSmallModel: true
            ))
        case .visionTasks:
            return searchModels(criteria: SearchCriteria(
                modelType: .vlm
            ))
        case .embeddingTasks:
            return searchModels(criteria: SearchCriteria(
                modelType: .embedder
            ))
        case .imageGeneration:
            return searchModels(criteria: SearchCriteria(
                modelType: .diffusion
            ))
        }
    }
    
    /// Use cases for model recommendations
    public enum UseCase {
        case mobileDevelopment
        case desktopDevelopment
        case highQualityGeneration
        case fastInference
        case visionTasks
        case embeddingTasks
        case imageGeneration
    }
    
    /// Get models optimized for specific device capabilities
    public static func getModelsForDevice(memoryGB: Double, isMobile: Bool = false) -> [ModelConfiguration] {
        let maxModelSize = isMobile ? min(memoryGB * 0.3, 2.0) : min(memoryGB * 0.5, 8.0)
        
        return searchModels(criteria: SearchCriteria(
            maxSizeGB: maxModelSize,
            isSmallModel: isMobile
        ))
    }
    
    /// Get the best model for a given prompt and constraints
    public static func getBestModel(
        for prompt: String,
        maxTokens: Int = 1000,
        maxSizeGB: Double? = nil,
        preferSpeed: Bool = false
    ) -> ModelConfiguration? {
        let allModels = getAllModels()
        
        // Filter by size constraint
        let sizeFiltered = maxSizeGB != nil ? 
            allModels.filter { $0.estimatedSizeGB ?? 0 <= maxSizeGB! } : 
            allModels
        
        // Score models based on requirements
        let scoredModels = sizeFiltered.map { model -> (ModelConfiguration, Double) in
            var score = 0.0
            
            // Context length score
            if model.maxTokens >= maxTokens {
                score += 10.0
            } else {
                score -= Double(maxTokens - model.maxTokens) * 0.1
            }
            
            // Size efficiency score
            if let size = model.estimatedSizeGB {
                if preferSpeed {
                    score += (10.0 - size) * 2.0 // Prefer smaller models for speed
                } else {
                    score += (10.0 - size) // Prefer smaller models for efficiency
                }
            }
            
            // Parameter count score
            if let params = model.parameters {
                let paramValue = extractParameterValue(params)
                if preferSpeed {
                    score += (10.0 - paramValue) * 2.0 // Prefer smaller models for speed
                } else {
                    score += paramValue * 0.5 // Prefer larger models for quality
                }
            }
            
            return (model, score)
        }
        
        return scoredModels.max(by: { $0.1 < $1.1 })?.0
    }
    
    // MARK: - Helper Methods
    
    private static func getAllModels() -> [ModelConfiguration] {
        return [
            tinyLlama11B,
            qwen05B,
            llama32_1B,
            llama32_3B,
            phi31Mini,
            gemma2_2B,
            llama31_8B,
            mistral7B,
            llava16_3B,
            bgeSmallEn,
            llava15_7B,
            bgeLargeEn,
            stableDiffusionXL,
            llama32_3B_fp16
        ]
    }
    
    private static func isModelOfType(_ model: ModelConfiguration, type: ModelType) -> Bool {
        switch type {
        case .llm:
            return !isModelOfType(model, type: .vlm) && 
                   !isModelOfType(model, type: .embedder) && 
                   !isModelOfType(model, type: .diffusion)
        case .vlm:
            return model.architecture?.lowercased().contains("llava") == true
        case .embedder:
            return model.architecture?.lowercased().contains("bge") == true
        case .diffusion:
            return model.architecture?.lowercased().contains("stable") == true ||
                   model.architecture?.lowercased().contains("diffusion") == true
        case .training:
            return false
        case .evaluation:
            return false
        case .compression:
            return false
        }
    }
    
    private static func extractParameterValue(_ paramString: String) -> Double {
        let lower = paramString.lowercased()
        if lower.contains("b") {
            let number = lower.replacingOccurrences(of: "b", with: "")
            return Double(number) ?? 0.0
        }
        return 0.0
    }
    
    // MARK: - Model Definitions (internal)
    
    internal static let tinyLlama11B = ModelConfiguration(
        name: "TinyLlama 1.1B Chat",
        hubId: "mlx-community/TinyLlama-1.1B-Chat-v1.0-4bit",
        description: "Ultra-compact model for mobile devices and testing",
        parameters: "1.1B",
        quantization: "4bit",
        architecture: "TinyLlama",
        maxTokens: 2048,
        estimatedSizeGB: 0.6,
        defaultSystemPrompt: "You are a helpful assistant that provides concise and accurate responses.",
        endOfTextTokens: ["<|im_end|>"],
        modelType: .llm,
        gpuCacheLimit: 512 * 1024 * 1024,
        features: []
    )
    
    internal static let qwen05B = ModelConfiguration(
        name: "Qwen 1.5 0.5B Chat",
        hubId: "mlx-community/Qwen1.5-0.5B-Chat-4bit",
        description: "Small, fast chat model good for testing and quick responses",
        parameters: "0.5B",
        quantization: "4bit",
        architecture: "Qwen",
        maxTokens: 4096,
        estimatedSizeGB: 0.3,
        modelType: .llm,
        gpuCacheLimit: 512 * 1024 * 1024,
        features: []
    )
    
    internal static let llama32_1B = ModelConfiguration(
        name: "Llama 3.2 1B",
        hubId: "mlx-community/Llama-3.2-1B-4bit",
        description: "Fast and efficient 1B parameter model",
        parameters: "1B",
        quantization: "4bit",
        architecture: "Llama",
        maxTokens: 4096,
        estimatedSizeGB: 0.6,
        modelType: .llm,
        gpuCacheLimit: 512 * 1024 * 1024,
        features: []
    )
    
    internal static let llama32_3B = ModelConfiguration(
        name: "Llama 3.2 3B",
        hubId: "mlx-community/Llama-3.2-3B-4bit",
        description: "Good quality 3B parameter model with reasonable speed",
        parameters: "3B",
        quantization: "4bit",
        architecture: "Llama",
        maxTokens: 4096,
        estimatedSizeGB: 1.8,
        modelType: .llm,
        gpuCacheLimit: 512 * 1024 * 1024,
        features: []
    )
    
    internal static let phi31Mini = ModelConfiguration(
        name: "Phi-3.1 Mini",
        hubId: "mlx-community/Phi-3.1-mini-4bit",
        description: "Microsoft's efficient Phi-3.1 Mini model",
        parameters: "3.8B",
        quantization: "4bit",
        architecture: "Phi",
        maxTokens: 4096,
        estimatedSizeGB: 2.3,
        modelType: .llm,
        gpuCacheLimit: 512 * 1024 * 1024,
        features: []
    )
    
    internal static let gemma2_2B = ModelConfiguration(
        name: "Gemma 2 2B",
        hubId: "mlx-community/gemma-2-2b-4bit",
        description: "Google's efficient Gemma 2 2B model",
        parameters: "2B",
        quantization: "4bit",
        architecture: "Gemma",
        maxTokens: 4096,
        estimatedSizeGB: 1.2,
        modelType: .llm,
        gpuCacheLimit: 512 * 1024 * 1024,
        features: []
    )
    
    internal static let llama31_8B = ModelConfiguration(
        name: "Llama 3.1 8B Instruct",
        hubId: "mlx-community/Meta-Llama-3.1-8B-Instruct-4bit",
        description: "High-performance model for complex reasoning tasks",
        parameters: "8B",
        quantization: "4bit",
        architecture: "Llama",
        maxTokens: 8192,
        estimatedSizeGB: 4.9,
        modelType: .llm,
        gpuCacheLimit: 512 * 1024 * 1024,
        features: []
    )
    
    internal static let mistral7B = ModelConfiguration(
        name: "Mistral 7B Instruct",
        hubId: "mlx-community/Mistral-7B-Instruct-v0.3-4bit",
        description: "High-quality instruction-following model",
        parameters: "7B",
        quantization: "4bit",
        architecture: "Mistral",
        maxTokens: 8192,
        estimatedSizeGB: 4.2,
        defaultSystemPrompt: "You are a helpful assistant.",
        endOfTextTokens: ["</s>"],
        modelType: .llm,
        gpuCacheLimit: 512 * 1024 * 1024,
        features: []
    )
    
    internal static let llava16_3B = ModelConfiguration(
        name: "LLaVA 1.6 3B",
        hubId: "mlx-community/llava-v1.6-3b-4bit",
        description: "Vision language model for image understanding and analysis",
        parameters: "3B",
        quantization: "Q4_K_M",
        architecture: "LLaVA",
        maxTokens: 4096,
        estimatedSizeGB: 2.1,
        defaultSystemPrompt: "You are a helpful assistant that can analyze and describe images.",
        endOfTextTokens: ["<|im_end|>"],
        modelType: .vlm,
        gpuCacheLimit: 512 * 1024 * 1024,
        features: [.visionLanguageModels, .multiModalInput, .streamingGeneration]
    )
    
    internal static let bgeSmallEn = ModelConfiguration(
        name: "BGE Small En",
        hubId: "mlx-community/bge-small-en-v1.5-4bit",
        description: "Efficient text embedding model for semantic search and similarity",
        parameters: "384M",
        quantization: "Q4_K_M",
        architecture: "BGE",
        maxTokens: 512,
        estimatedSizeGB: 0.2,
        defaultSystemPrompt: "",
        endOfTextTokens: nil,
        modelType: .embedding,
        gpuCacheLimit: 512 * 1024 * 1024,
        features: [.embeddingModels, .batchProcessing]
    )
    
    internal static let llava15_7B = ModelConfiguration(
        name: "LLaVA 1.5 7B",
        hubId: "mlx-community/llava-v1.5-7b-4bit",
        description: "Vision language model for image understanding and analysis (LLaVA 1.5 7B)",
        parameters: "7B",
        quantization: "4bit",
        architecture: "LLaVA",
        maxTokens: 4096,
        estimatedSizeGB: 4.2,
        defaultSystemPrompt: "You are a helpful assistant that can analyze and describe images.",
        endOfTextTokens: ["<|im_end|>"],
        modelType: .vlm,
        gpuCacheLimit: 512 * 1024 * 1024,
        features: [.visionLanguageModels, .multiModalInput, .streamingGeneration]
    )

    internal static let bgeLargeEn = ModelConfiguration(
        name: "BGE Large En",
        hubId: "mlx-community/bge-large-en-v1.5-4bit",
        description: "High-quality text embedding model for semantic search and similarity (BGE Large)",
        parameters: "1.2B",
        quantization: "4bit",
        architecture: "BGE",
        maxTokens: 1024,
        estimatedSizeGB: 0.7,
        defaultSystemPrompt: nil,
        endOfTextTokens: nil,
        modelType: .embedding,
        gpuCacheLimit: 512 * 1024 * 1024,
        features: [.embeddingModels, .batchProcessing]
    )

    internal static let stableDiffusionXL = ModelConfiguration(
        name: "Stable Diffusion XL",
        hubId: "mlx-community/stable-diffusion-xl-base-1.0-4bit",
        description: "Image generation model (Stable Diffusion XL)",
        parameters: "2.3B",
        quantization: "4bit",
        architecture: "StableDiffusionXL",
        maxTokens: 77,
        estimatedSizeGB: 2.5,
        defaultSystemPrompt: "Generate a high-quality image from the given prompt.",
        endOfTextTokens: nil,
        modelType: .diffusion,
        gpuCacheLimit: 512 * 1024 * 1024,
        features: [.diffusionModels, .multiModalInput]
    )

    internal static let llama32_3B_fp16 = ModelConfiguration(
        name: "Llama 3.2 3B FP16",
        hubId: "mlx-community/Llama-3.2-3B-fp16",
        description: "Llama 3.2 3B model with FP16 quantization",
        parameters: "3B",
        quantization: "fp16",
        architecture: "Llama",
        maxTokens: 4096,
        estimatedSizeGB: 3.2,
        defaultSystemPrompt: nil,
        endOfTextTokens: nil,
        modelType: .llm,
        gpuCacheLimit: 512 * 1024 * 1024,
        features: []
    )
    
    // MARK: - Test Models
    
    /// Mock test model for testing and development
    public static let mock_test = ModelConfiguration(
        name: "Mock Test Model",
        hubId: "mock/test-model",
        description: "Mock model for testing",
        maxTokens: 100,
        estimatedSizeGB: 0.1,
        defaultSystemPrompt: "You are a test assistant.",
        modelType: .llm,
        gpuCacheLimit: 512 * 1024 * 1024,
        features: []
    )
    
    // MARK: - Public API
    
    /// Returns all pre-configured models
    public static var allModels: [ModelConfiguration] {
        [
            tinyLlama11B,
            qwen05B,
            llama32_1B,
            llama32_3B,
            phi31Mini,
            gemma2_2B,
            llama31_8B,
            mistral7B,
            llava16_3B,
            bgeSmallEn,
            // New models for feature coverage:
            llava15_7B,      // VLM
            bgeLargeEn,      // Embedding
            stableDiffusionXL, // Diffusion
            llama32_3B_fp16, // Quantization (fp16)
            mock_test        // Test model
        ]
    }
    
    /// Finds a model by its hub ID
    public static func findModel(by hubId: String) -> ModelConfiguration? {
        allModels.first { $0.hubId == hubId }
    }
    
    /// Finds a model by its display name
    public static func findModelByName(_ name: String) -> ModelConfiguration? {
        allModels.first { $0.name == name }
    }
    
    /// Finds models by architecture
    public static func findModels(by architecture: String) -> [ModelConfiguration] {
        allModels.filter { $0.architecture?.lowercased() == architecture.lowercased() }
    }
    
    /// Finds models suitable for mobile devices (small models)
    public static func findMobileSuitableModels() -> [ModelConfiguration] {
        allModels.filter { $0.isSmallModel }
    }
    
    // MARK: - Model Size Categories
    
    /// Returns small models (≤3B parameters)
    public static var smallModels: [ModelConfiguration] {
        allModels.filter { $0.isSmallModel }
    }
    
    /// Returns medium models (3B-8B parameters)
    public static var mediumModels: [ModelConfiguration] {
        allModels.filter { model in
            guard let params = model.parameters?.lowercased() else { return false }
            return params.contains("3b") || params.contains("7b") || params.contains("8b")
        }
    }
    
    /// Returns large models (>8B parameters)
    public static var largeModels: [ModelConfiguration] {
        allModels.filter { model in
            guard let params = model.parameters?.lowercased() else { return false }
            return params.contains("13b") || params.contains("14b") || params.contains("30b")
        }
    }
    
    // MARK: - Advanced Search Methods
    
    /// Finds models within a parameter range
    public static func findModels(parameterRange: ClosedRange<Double>) -> [ModelConfiguration] {
        allModels.filter { model in
            guard let params = model.parameters?.lowercased() else { return false }
            
            let paramValue: Double
            if params.contains("0.5b") { paramValue = 0.5 }
            else if params.contains("1b") { paramValue = 1.0 }
            else if params.contains("1.5b") { paramValue = 1.5 }
            else if params.contains("2b") { paramValue = 2.0 }
            else if params.contains("3b") { paramValue = 3.0 }
            else if params.contains("7b") { paramValue = 7.0 }
            else if params.contains("8b") { paramValue = 8.0 }
            else if params.contains("13b") { paramValue = 13.0 }
            else if params.contains("30b") { paramValue = 30.0 }
            else { return false }
            
            return parameterRange.contains(paramValue)
        }
    }
    
    /// Finds models by quantization type
    public static func findModels(byQuantization quantization: String) -> [ModelConfiguration] {
        allModels.filter { $0.quantization?.lowercased() == quantization.lowercased() }
    }
    
    /// Searches models by query (name, architecture, or parameters)
    public static func searchModels(query: String) -> [ModelConfiguration] {
        let lowercasedQuery = query.lowercased()
        return allModels.filter { model in
            model.name.lowercased().contains(lowercasedQuery) ||
            model.architecture?.lowercased().contains(lowercasedQuery) == true ||
            model.parameters?.lowercased().contains(lowercasedQuery) == true ||
            model.hubId.lowercased().contains(lowercasedQuery)
        }
    }
    
    // MARK: - Legacy Support (for backward compatibility)
    
    /// Legacy property for backward compatibility
    @available(*, deprecated, message: "Use allModels instead")
    public static let qwen_0_5B = qwen05B
    
    /// Legacy property for backward compatibility
    @available(*, deprecated, message: "Use allModels instead")
    public static let llama_3_2_3B = llama32_3B
    
    /// Legacy property for backward compatibility
    @available(*, deprecated, message: "Use allModels instead")
    public static let mistral_7B = mistral7B
    
    /// Returns all models supporting at least the given minimum maxTokens (context length)
    public static func modelsSupporting(minTokens: Int) -> [ModelConfiguration] {
        allModels.filter { $0.maxTokens >= minTokens }
    }
    
    /// Returns the top recommended models for the current device (by RAM and platform)
    public static func recommendedModelsForCurrentDevice(limit: Int = 3) async -> [ModelConfiguration] {
        let memoryGB = Double(ProcessInfo.processInfo.physicalMemory) / (1024 * 1024 * 1024)
        #if os(iOS)
        let platform = "iOS"
        #elseif os(macOS)
        let platform = "macOS"
        #elseif os(tvOS)
        let platform = "tvOS"
        #elseif os(watchOS)
        let platform = "watchOS"
        #elseif os(visionOS)
        let platform = "visionOS"
        #else
        let platform = "Unknown"
        #endif
        // Only include models that fit in RAM with a 20% safety margin
        let compatible = allModels.filter { $0.estimatedMemoryGB < memoryGB * 0.8 }
        // Sort by size (largest that fits), then by maxTokens
        let sorted = compatible.sorted {
            if $0.estimatedMemoryGB != $1.estimatedMemoryGB {
                return $0.estimatedMemoryGB > $1.estimatedMemoryGB
            }
            return $0.maxTokens > $1.maxTokens
        }
        return Array(sorted.prefix(limit))
    }

    /// Checks if a model is supported on a device with the given RAM (GB) and platform
    public static func isModelSupported(_ model: ModelConfiguration, ramGB: Double, platform: String) -> Bool {
        // For now, only check RAM; can add platform-specific logic later
        return model.estimatedMemoryGB < ramGB * 0.8
    }
} 
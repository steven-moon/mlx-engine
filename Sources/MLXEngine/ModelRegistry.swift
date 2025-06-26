import Foundation

/// A registry of well-known MLX-compatible models with comprehensive metadata.
public struct ModelRegistry {
    
    // MARK: - Model Type Definitions
    
    /// Model type categories (LLM, VLM, Embedder, Diffusion)
    internal enum ModelType: String, CaseIterable {
        case llm = "LLM"           // Large Language Model
        case vlm = "VLM"           // Vision Language Model
        case embedder = "Embedder" // Text Embedding Model
        case diffusion = "Diffusion" // Image Generation Model
        
        /// Human-readable description of the model type
        var description: String {
            switch self {
            case .llm:
                return "Text generation and conversation"
            case .vlm:
                return "Image understanding and analysis"
            case .embedder:
                return "Text embedding and semantic search"
            case .diffusion:
                return "Image generation from text"
            }
        }
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
        endOfTextTokens: ["<|im_end|>"]
    )
    
    internal static let qwen05B = ModelConfiguration(
        name: "Qwen 1.5 0.5B Chat",
        hubId: "mlx-community/Qwen1.5-0.5B-Chat-4bit",
        description: "Small, fast chat model good for testing and quick responses",
        parameters: "0.5B",
        quantization: "4bit",
        architecture: "Qwen",
        maxTokens: 4096,
        estimatedSizeGB: 0.3
    )
    
    internal static let llama32_1B = ModelConfiguration(
        name: "Llama 3.2 1B",
        hubId: "mlx-community/Llama-3.2-1B-4bit",
        description: "Fast and efficient 1B parameter model",
        parameters: "1B",
        quantization: "4bit",
        architecture: "Llama",
        maxTokens: 4096,
        estimatedSizeGB: 0.6
    )
    
    internal static let llama32_3B = ModelConfiguration(
        name: "Llama 3.2 3B",
        hubId: "mlx-community/Llama-3.2-3B-4bit",
        description: "Good quality 3B parameter model with reasonable speed",
        parameters: "3B",
        quantization: "4bit",
        architecture: "Llama",
        maxTokens: 4096,
        estimatedSizeGB: 1.8
    )
    
    internal static let phi31Mini = ModelConfiguration(
        name: "Phi-3.1 Mini",
        hubId: "mlx-community/Phi-3.1-mini-4bit",
        description: "Microsoft's efficient Phi-3.1 Mini model",
        parameters: "3.8B",
        quantization: "4bit",
        architecture: "Phi",
        maxTokens: 4096,
        estimatedSizeGB: 2.3
    )
    
    internal static let gemma2_2B = ModelConfiguration(
        name: "Gemma 2 2B",
        hubId: "mlx-community/gemma-2-2b-4bit",
        description: "Google's efficient Gemma 2 2B model",
        parameters: "2B",
        quantization: "4bit",
        architecture: "Gemma",
        maxTokens: 4096,
        estimatedSizeGB: 1.2
    )
    
    internal static let llama31_8B = ModelConfiguration(
        name: "Llama 3.1 8B Instruct",
        hubId: "mlx-community/Meta-Llama-3.1-8B-Instruct-4bit",
        description: "High-performance model for complex reasoning tasks",
        parameters: "8B",
        quantization: "4bit",
        architecture: "Llama",
        maxTokens: 8192,
        estimatedSizeGB: 4.9
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
        endOfTextTokens: ["</s>"]
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
        endOfTextTokens: ["<|im_end|>"]
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
        endOfTextTokens: nil
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
        endOfTextTokens: ["<|im_end|>"]
        // Feature: visionLanguageModels
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
        endOfTextTokens: nil
        // Feature: embeddingModels
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
        endOfTextTokens: nil
        // Feature: diffusionModels
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
        endOfTextTokens: nil
        // Feature: quantizationSupport
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
            llama32_3B_fp16  // Quantization (fp16)
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
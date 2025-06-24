import Foundation

/// A registry of well-known MLX-compatible models with comprehensive metadata.
public struct ModelRegistry {
    
    // MARK: - Model Type Definitions
    
    public enum ModelType: String, CaseIterable {
        case llm = "LLM"           // Large Language Model
        case vlm = "VLM"           // Vision Language Model
        case embedder = "Embedder" // Text Embedding Model
        case diffusion = "Diffusion" // Image Generation Model
        
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
            }
        }
    }
    
    // MARK: - Small Models (0.5B - 3B parameters)
    
    /// Ultra-compact model for testing and mobile devices
    public static let tinyLlama11B = ModelConfiguration(
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
    
    /// Small, efficient chat model
    public static let qwen05B = ModelConfiguration(
        name: "Qwen 1.5 0.5B Chat",
        hubId: "mlx-community/Qwen1.5-0.5B-Chat-4bit",
        description: "Small, fast chat model good for testing and quick responses",
        parameters: "0.5B",
        quantization: "4bit",
        architecture: "Qwen",
        maxTokens: 4096,
        estimatedSizeGB: 0.3
    )
    
    /// Fast and efficient 1B parameter model
    public static let llama32_1B = ModelConfiguration(
        name: "Llama 3.2 1B",
        hubId: "mlx-community/Llama-3.2-1B-4bit",
        description: "Fast and efficient 1B parameter model",
        parameters: "1B",
        quantization: "4bit",
        architecture: "Llama",
        maxTokens: 4096,
        estimatedSizeGB: 0.6
    )
    
    /// Good quality 3B parameter model
    public static let llama32_3B = ModelConfiguration(
        name: "Llama 3.2 3B",
        hubId: "mlx-community/Llama-3.2-3B-4bit",
        description: "Good quality 3B parameter model with reasonable speed",
        parameters: "3B",
        quantization: "4bit",
        architecture: "Llama",
        maxTokens: 4096,
        estimatedSizeGB: 1.8
    )
    
    // MARK: - Medium Models (3B - 8B parameters)
    
    /// Microsoft's efficient Phi-3.1 Mini model
    public static let phi31Mini = ModelConfiguration(
        name: "Phi-3.1 Mini",
        hubId: "mlx-community/Phi-3.1-mini-4bit",
        description: "Microsoft's efficient Phi-3.1 Mini model",
        parameters: "3.8B",
        quantization: "4bit",
        architecture: "Phi",
        maxTokens: 4096,
        estimatedSizeGB: 2.3
    )
    
    /// Google's efficient Gemma 2 2B model
    public static let gemma2_2B = ModelConfiguration(
        name: "Gemma 2 2B",
        hubId: "mlx-community/gemma-2-2b-4bit",
        description: "Google's efficient Gemma 2 2B model",
        parameters: "2B",
        quantization: "4bit",
        architecture: "Gemma",
        maxTokens: 4096,
        estimatedSizeGB: 1.2
    )
    
    // MARK: - Large Models (8B+ parameters)
    
    /// High-performance model for complex reasoning tasks
    public static let llama31_8B = ModelConfiguration(
        name: "Llama 3.1 8B Instruct",
        hubId: "mlx-community/Meta-Llama-3.1-8B-Instruct-4bit",
        description: "High-performance model for complex reasoning tasks",
        parameters: "8B",
        quantization: "4bit",
        architecture: "Llama",
        maxTokens: 8192,
        estimatedSizeGB: 4.9
    )
    
    /// Popular Mistral 7B model
    public static let mistral7B = ModelConfiguration(
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
    
    // MARK: - Vision Language Models
    
    /// Vision language model for image understanding
    public static let llava16_3B = ModelConfiguration(
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
    
    // MARK: - Text Embedding Models
    
    /// Efficient text embedding model for semantic search
    public static let bgeSmallEn = ModelConfiguration(
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
    
    // MARK: - Model Collections
    
    /// All available model configurations, sorted by type and size
    public static var allModels: [ModelConfiguration] {
        [
            // Small LLM models first
            tinyLlama11B,
            qwen05B,
            llama32_1B,
            llama32_3B,
            // Medium LLM models
            phi31Mini,
            gemma2_2B,
            // Large LLM models
            llama31_8B,
            mistral7B,
            // Vision Language Models
            llava16_3B,
            // Text Embedding Models
            bgeSmallEn
        ]
    }
    
    /// Small models suitable for mobile devices and testing
    public static var smallModels: [ModelConfiguration] {
        [tinyLlama11B, qwen05B, llama32_1B]
    }
    
    /// Medium models for balanced performance
    public static var mediumModels: [ModelConfiguration] {
        [llama32_3B, phi31Mini, gemma2_2B]
    }
    
    /// Large models for high-performance devices
    public static var largeModels: [ModelConfiguration] {
        [llama31_8B, mistral7B]
    }
    
    /// Text-only language models
    public static var textModels: [ModelConfiguration] {
        [
            tinyLlama11B, qwen05B, llama32_1B, llama32_3B,
            phi31Mini, gemma2_2B, llama31_8B, mistral7B
        ]
    }
    
    /// Vision language models for image understanding
    public static var visionModels: [ModelConfiguration] {
        [llava16_3B]
    }
    
    /// Text embedding models for semantic search
    public static var embeddingModels: [ModelConfiguration] {
        [bgeSmallEn]
    }
    
    /// Models suitable for mobile devices (< 2GB)
    public static var mobileOptimizedModels: [ModelConfiguration] {
        allModels.filter { ($0.estimatedSizeGB ?? 0) < 2.0 }
    }
    
    /// Recommended starter models for new users
    public static var starterModels: [ModelConfiguration] {
        [tinyLlama11B, qwen05B, llama32_1B]
    }
    
    // MARK: - Search and Filter Methods
    
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
    
    /// Finds models by parameter count range
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
            else { return false }
            
            return parameterRange.contains(paramValue)
        }
    }
    
    /// Finds models by quantization type
    public static func findModels(byQuantization quantization: String) -> [ModelConfiguration] {
        allModels.filter { $0.quantization?.lowercased() == quantization.lowercased() }
    }
    
    /// Searches models by text query (name, architecture, or parameters)
    public static func searchModels(query: String) -> [ModelConfiguration] {
        let lowercasedQuery = query.lowercased()
        
        return allModels.filter { model in
            // Search in name
            if model.name.lowercased().contains(lowercasedQuery) {
                return true
            }
            
            // Search in hub ID
            if model.hubId.lowercased().contains(lowercasedQuery) {
                return true
            }
            
            // Search in architecture
            if let architecture = model.architecture?.lowercased(),
               architecture.contains(lowercasedQuery) {
                return true
            }
            
            // Search in parameters
            if let parameters = model.parameters?.lowercased(),
               parameters.contains(lowercasedQuery) {
                return true
            }
            
            // Search in quantization
            if let quantization = model.quantization?.lowercased(),
               quantization.contains(lowercasedQuery) {
                return true
            }
            
            return false
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
} 
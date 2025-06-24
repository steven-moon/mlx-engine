import Foundation
import os.log

/// Comprehensive MLX model search utility for Hugging Face Hub
public class MLXModelSearchUtility: @unchecked Sendable {
    public static let shared = MLXModelSearchUtility()
    
    private let huggingFaceAPI = HuggingFaceAPI.shared
    private let logger = Logger(subsystem: "com.mlxengine", category: "MLXModelSearch")
    
    private init() {}
    
    // MARK: - Model Type Definitions
    
    public enum ModelType: String, CaseIterable {
        case textGeneration = "text-generation"
        case textToImage = "text-to-image"
        case imageToText = "image-to-text"
        case imageClassification = "image-classification"
        case objectDetection = "object-detection"
        case segmentation = "image-segmentation"
        case embedding = "feature-extraction"
        case translation = "translation"
        case summarization = "summarization"
        case questionAnswering = "question-answering"
        case conversational = "conversational"
        
        public var displayName: String {
            switch self {
            case .textGeneration: return "Text Generation"
            case .textToImage: return "Text to Image"
            case .imageToText: return "Image to Text"
            case .imageClassification: return "Image Classification"
            case .objectDetection: return "Object Detection"
            case .segmentation: return "Image Segmentation"
            case .embedding: return "Embeddings"
            case .translation: return "Translation"
            case .summarization: return "Summarization"
            case .questionAnswering: return "Question Answering"
            case .conversational: return "Conversational"
            }
        }
        
        var searchHint: String {
            switch self {
            case .textGeneration:
                return "text"
            case .textToImage:
                return "image"
            case .imageToText:
                return "image"
            case .imageClassification:
                return "image"
            case .conversational:
                return "chat"
            case .embedding:
                return "embed"
            default:
                return ""
            }
        }
    }
    
    public enum ModelSize: String, CaseIterable {
        case tiny = "tiny"      // < 100M
        case small = "small"    // 100M - 1B
        case medium = "medium"  // 1B - 7B
        case large = "large"    // 7B - 13B
        case xlarge = "xlarge"  // > 13B
        
        public var maxSizeMB: Int {
            switch self {
            case .tiny: return 100
            case .small: return 1000
            case .medium: return 7000
            case .large: return 13000
            case .xlarge: return 50000
            }
        }
        
        var searchTerm: String {
            switch self {
            case .tiny: return "0.5b"
            case .small: return "1b"
            case .medium: return "3b"
            case .large: return "7b"
            case .xlarge: return "13b"
            }
        }
    }
    
    public enum Quantization: String, CaseIterable {
        case fp32 = "fp32"
        case fp16 = "fp16"
        case q8_0 = "q8_0"
        case q4_k_m = "q4_k_m"
        case q4_0 = "q4_0"
        
        public var displayName: String {
            switch self {
            case .fp32: return "FP32 (32-bit)"
            case .fp16: return "FP16 (16-bit)"
            case .q8_0: return "Q8_0 (8-bit)"
            case .q4_k_m: return "Q4_K_M (4-bit)"
            case .q4_0: return "Q4_0 (4-bit)"
            }
        }
        
        var searchTerm: String {
            switch self {
            case .fp32: return "fp32"
            case .fp16: return "fp16"
            case .q8_0: return "q8_0"
            case .q4_k_m: return "q4_k_m"
            case .q4_0: return "q4_0"
            }
        }
    }
    
    // MARK: - Search Criteria
    
    public struct SearchCriteria: CustomStringConvertible {
        public let modelType: ModelType?
        public let modelSize: ModelSize?
        public let quantization: Quantization?
        public let maxFileSizeMB: Int?
        public let architecture: String?
        public let tags: [String]?
        public let minDownloads: Int?
        public let minLikes: Int?
        public let excludeArchitectures: [String]?
        
        public init(
            modelType: ModelType? = nil,
            modelSize: ModelSize? = nil,
            quantization: Quantization? = nil,
            maxFileSizeMB: Int? = nil,
            architecture: String? = nil,
            tags: [String]? = nil,
            minDownloads: Int? = nil,
            minLikes: Int? = nil,
            excludeArchitectures: [String]? = nil
        ) {
            self.modelType = modelType
            self.modelSize = modelSize
            self.quantization = quantization
            self.maxFileSizeMB = maxFileSizeMB
            self.architecture = architecture
            self.tags = tags
            self.minDownloads = minDownloads
            self.minLikes = minLikes
            self.excludeArchitectures = excludeArchitectures
        }
        
        public var description: String {
            var parts: [String] = []
            if let modelType = modelType { parts.append("type: \(modelType.displayName)") }
            if let modelSize = modelSize { parts.append("size: \(modelSize.rawValue)") }
            if let quantization = quantization { parts.append("quantization: \(quantization.displayName)") }
            if let maxFileSizeMB = maxFileSizeMB { parts.append("maxSize: \(maxFileSizeMB)MB") }
            if let architecture = architecture { parts.append("architecture: \(architecture)") }
            if let minDownloads = minDownloads { parts.append("minDownloads: \(minDownloads)") }
            if let minLikes = minLikes { parts.append("minLikes: \(minLikes)") }
            if let excludeArchitectures = excludeArchitectures { parts.append("exclude: \(excludeArchitectures.joined(separator: ", "))") }
            return parts.isEmpty ? "default" : parts.joined(separator: ", ")
        }
    }
    
    // MARK: - Search Results
    
    public struct SearchResult {
        public let model: HuggingFaceModel
        public let score: Double
        public let matchedCriteria: [String]
        public let estimatedSizeMB: Int?
        public let downloadURL: String?
        
        public init(model: HuggingFaceModel, score: Double, matchedCriteria: [String], estimatedSizeMB: Int? = nil, downloadURL: String? = nil) {
            self.model = model
            self.score = score
            self.matchedCriteria = matchedCriteria
            self.estimatedSizeMB = estimatedSizeMB
            self.downloadURL = downloadURL
        }
    }
    
    // MARK: - Main Search Methods
    
    /// Searches for MLX models based on criteria
    public func searchMLXModels(criteria: SearchCriteria) async throws -> [HuggingFaceModel] {
        logger.info("🔍 Searching MLX models with criteria: \(criteria)")
        
        var allResults: [HuggingFaceModel] = []
        
        // Strategy 1: Try specific search first
        let searchStrategies = buildSearchStrategies(for: criteria)
        
        for (index, strategy) in searchStrategies.enumerated() {
            logger.info("📝 Search strategy \(index + 1): \(strategy)")
            
            do {
                let results = try await huggingFaceAPI.searchModels(query: strategy, limit: 50)
                logger.info("📊 Found \(results.count) models with strategy: \(strategy)")
                
                // Apply robust filtering
                let filteredResults = applyRobustFiltering(models: results, criteria: criteria)
                logger.info("✅ Filtered to \(filteredResults.count) matching models")
                
                allResults.append(contentsOf: filteredResults)
                
                // If we found enough results, break early
                if allResults.count >= 30 {
                    break
                }
            } catch {
                logger.warning("⚠️ Search strategy \(strategy) failed: \(error.localizedDescription)")
                continue
            }
        }
        
        // If we still don't have enough results, try broader searches
        if allResults.count < 10 {
            logger.info("🔄 Trying broader search strategies for more results")
            let broaderResults = try await performBroaderSearch(criteria: criteria)
            allResults.append(contentsOf: broaderResults)
        }
        
        // Remove duplicates and sort by relevance
        let uniqueResults = removeDuplicates(from: allResults)
        let sortedResults = sortByRelevance(models: uniqueResults, criteria: criteria)
        
        logger.info("🎯 Final results: \(sortedResults.count) unique models")
        
        return sortedResults
    }
    
    /// Converts HuggingFaceModel to ModelConfiguration for MLXEngine compatibility
    public func convertToModelConfiguration(_ model: HuggingFaceModel) -> ModelConfiguration {
        let parameters = model.extractParameters()
        let quantization = model.extractQuantization()
        let architecture = model.extractArchitecture()
        let estimatedSizeGB = Double(model.getEstimatedSizeMB() ?? 0) / 1024.0
        
        return ModelConfiguration(
            name: model.id,
            hubId: model.id,
            description: "Model from Hugging Face Hub",
            parameters: parameters,
            quantization: quantization,
            architecture: architecture,
            maxTokens: 4096,
            estimatedSizeGB: estimatedSizeGB > 0 ? estimatedSizeGB : nil,
            defaultSystemPrompt: "You are a helpful assistant.",
            endOfTextTokens: nil
        )
    }
    
    // MARK: - Private Methods
    
    private func performBroaderSearch(criteria: SearchCriteria) async throws -> [HuggingFaceModel] {
        var results: [HuggingFaceModel] = []
        
        // Try very broad searches
        let broadQueries = [
            "mlx",
            "mlx-community",
            "lmstudio-community mlx"
        ]
        
        for query in broadQueries {
            do {
                let models = try await huggingFaceAPI.searchModels(query: query, limit: 30)
                let filtered = applyVeryLenientFiltering(models: models, criteria: criteria)
                results.append(contentsOf: filtered)
                
                if results.count >= 20 {
                    break
                }
            } catch {
                logger.warning("⚠️ Broad search '\(query)' failed: \(error.localizedDescription)")
            }
        }
        
        return results
    }
    
    private func applyRobustFiltering(models: [HuggingFaceModel], criteria: SearchCriteria) -> [HuggingFaceModel] {
        return models.filter { model in
            // First, ensure model is accessible
            guard model.isAccessible() else {
                return false
            }
            
            // Check if model has MLX compatibility
            guard model.hasMLXFiles() else {
                return false
            }
            
            // Check model type with multiple fallbacks
            if let expectedType = criteria.modelType {
                if !matchesModelType(model: model, expectedType: expectedType) {
                    return false
                }
            }
            
            // Check architecture with flexibility
            if let expectedArch = criteria.architecture {
                if !matchesArchitecture(model: model, expectedArch: expectedArch) {
                    return false
                }
            }
            
            // Check excluded architectures
            if let excludedArchs = criteria.excludeArchitectures {
                if isExcludedArchitecture(model: model, excludedArchs: excludedArchs) {
                    return false
                }
            }
            
            // Check file size with estimation
            if let maxSize = criteria.maxFileSizeMB, maxSize > 0 {
                if let estimatedSize = model.getEstimatedSizeMB() {
                    if estimatedSize > maxSize {
                        return false
                    }
                }
            }
            
            // Check popularity with lenient thresholds
            if let minDownloads = criteria.minDownloads {
                let downloads = model.downloads ?? 0
                if downloads < minDownloads {
                    return false
                }
            }
            
            if let minLikes = criteria.minLikes {
                let likes = model.likes ?? 0
                if likes < minLikes {
                    return false
                }
            }
            
            return true
        }
    }
    
    private func applyVeryLenientFiltering(models: [HuggingFaceModel], criteria: SearchCriteria) -> [HuggingFaceModel] {
        return models.filter { model in
            // Only basic checks for very lenient filtering
            guard model.isAccessible() else {
                return false
            }
            
            // Very basic MLX check
            if let tags = model.tags {
                if !tags.contains(where: { $0.lowercased() == "mlx" }) {
                    return false
                }
            } else if let libraryName = model.library_name {
                if libraryName.lowercased() != "mlx" {
                    return false
                }
            } else {
                // If no clear MLX indication, check name
                if !model.id.lowercased().contains("mlx") {
                    return false
                }
            }
            
            return true
        }
    }
    
    private func matchesModelType(model: HuggingFaceModel, expectedType: ModelType) -> Bool {
        // Check pipeline tag first
        if let pipelineTag = model.pipeline_tag {
            if pipelineTag == expectedType.rawValue {
                return true
            }
            
            // Try alternative pipeline tags
            let alternativeTags = getAlternativePipelineTags(for: expectedType)
            if alternativeTags.contains(pipelineTag) {
                return true
            }
        }
        
        // Check model name for hints
        let modelName = model.id.lowercased()
        if modelName.contains(expectedType.searchHint) {
            return true
        }
        
        // Check tags for type hints
        if let tags = model.tags {
            for tag in tags {
                if tag.contains(expectedType.searchHint) {
                    return true
                }
            }
        }
        
        // Check cardData for type information
        if let cardData = model.cardData {
            if let pipeline = cardData["pipeline_tag"]?.value as? String {
                if pipeline == expectedType.rawValue {
                    return true
                }
            }
        }
        
        return false
    }
    
    private func matchesArchitecture(model: HuggingFaceModel, expectedArch: String) -> Bool {
        let expectedArchLower = expectedArch.lowercased()
        
        // Check extracted architecture
        if let modelArch = model.extractArchitecture()?.lowercased() {
            if modelArch.contains(expectedArchLower) {
                return true
            }
        }
        
        // Check model name
        let modelName = model.id.lowercased()
        if modelName.contains(expectedArchLower) {
            return true
        }
        
        // Check tags
        if let tags = model.tags {
            for tag in tags {
                if tag.lowercased().contains(expectedArchLower) {
                    return true
                }
            }
        }
        
        // Check cardData
        if let cardData = model.cardData {
            if let arch = cardData["architecture"]?.value as? String {
                if arch.lowercased().contains(expectedArchLower) {
                    return true
                }
            }
        }
        
        return false
    }
    
    private func isExcludedArchitecture(model: HuggingFaceModel, excludedArchs: [String]) -> Bool {
        for excludedArch in excludedArchs {
            if matchesArchitecture(model: model, expectedArch: excludedArch) {
                return true
            }
        }
        return false
    }
    
    private func buildSearchStrategies(for criteria: SearchCriteria) -> [String] {
        var strategies: [String] = []
        
        // Strategy 1: MLX + model type
        if let modelType = criteria.modelType {
            strategies.append("mlx \(modelType.rawValue)")
        }
        
        // Strategy 2: MLX + size
        if let modelSize = criteria.modelSize {
            strategies.append("mlx \(modelSize.searchTerm)")
        }
        
        // Strategy 3: MLX + architecture
        if let architecture = criteria.architecture {
            strategies.append("mlx \(architecture)")
        }
        
        // Strategy 4: MLX + quantization
        if let quantization = criteria.quantization {
            strategies.append("mlx \(quantization.searchTerm)")
        }
        
        // Strategy 5: Just MLX (broadest search)
        strategies.append("mlx")
        
        // Strategy 6: MLX + popular terms
        strategies.append("mlx community")
        strategies.append("mlx-community")
        
        return strategies
    }
    
    private func getAlternativePipelineTags(for modelType: ModelType) -> [String] {
        switch modelType {
        case .textGeneration:
            return ["text-generation", "text2text-generation", "conversational"]
        case .conversational:
            return ["conversational", "text-generation", "text2text-generation"]
        case .embedding:
            return ["feature-extraction", "embeddings"]
        case .imageClassification:
            return ["image-classification", "image-to-text"]
        case .textToImage:
            return ["text-to-image", "image-generation"]
        case .imageToText:
            return ["image-to-text", "image-classification"]
        default:
            return [modelType.rawValue]
        }
    }
    
    private func removeDuplicates(from models: [HuggingFaceModel]) -> [HuggingFaceModel] {
        var seen = Set<String>()
        return models.filter { model in
            if seen.contains(model.id) {
                return false
            } else {
                seen.insert(model.id)
                return true
            }
        }
    }
    
    private func sortByRelevance(models: [HuggingFaceModel], criteria: SearchCriteria) -> [HuggingFaceModel] {
        return models.sorted { model1, model2 in
            // Sort by downloads (popularity) first
            let downloads1 = model1.downloads ?? 0
            let downloads2 = model2.downloads ?? 0
            if downloads1 != downloads2 {
                return downloads1 > downloads2
            }
            
            // Then by likes
            let likes1 = model1.likes ?? 0
            let likes2 = model2.likes ?? 0
            if likes1 != likes2 {
                return likes1 > likes2
            }
            
            // Then by trending score
            let trending1 = model1.trendingScore ?? 0
            let trending2 = model2.trendingScore ?? 0
            if trending1 != trending2 {
                return trending1 > trending2
            }
            
            // Then by name (alphabetical)
            return model1.id < model2.id
        }
    }
} 
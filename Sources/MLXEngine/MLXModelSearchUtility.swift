import Foundation

/// Hugging Face Hub API client for searching and downloading models
public final class MLXModelSearchUtility: @unchecked Sendable {
    public static let shared = MLXModelSearchUtility()
    
    private let huggingFaceAPI = HuggingFaceAPI.shared
    
    private init() {}
    // ... (rest of the real implementation from the sample project, with all public API and types) ...
} 
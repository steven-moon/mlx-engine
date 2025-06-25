import Foundation
// import Hub  // Removed: No such module available in SPM or MLX

/// Optimized model downloader using the Hub library for faster, more reliable downloads.
/// TODO: Re-implement using URLSession or another supported downloader. The 'Hub' module is not available.
public actor OptimizedDownloader {
    private let fileManager = FileManagerService.shared
    private let downloadBase: URL
    
    public init() {
        // Configure download base
        #if os(macOS)
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("MLXEngine/Models")
        #else
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("MLXModels")
        #endif
        self.downloadBase = base
    }
    
    /// Downloads a model using the optimized Hub library.
    public func downloadModel(_ config: ModelConfiguration, progress: @escaping @Sendable (Double) -> Void) async throws -> URL {
        throw NSError(domain: "OptimizedDownloader", code: -1, userInfo: [NSLocalizedDescriptionKey: "Hub-based download not implemented. Replace with URLSession or supported downloader."])
    }
    
    /// Downloads a model with resume capability
    public func downloadModelWithResume(_ config: ModelConfiguration, progress: @escaping @Sendable (Double) -> Void) async throws -> URL {
        // Check if model already exists
        let modelDirectory = downloadBase.appendingPathComponent(config.hubId)
        if FileManager.default.fileExists(atPath: modelDirectory.path) {
            print("📁 Model already exists at: \(modelDirectory.path)")
            // Verify existing files
            if try await verifyDownloadedModel(at: modelDirectory, config: config) {
                print("✅ Existing model is valid, skipping download")
                progress(1.0)
                return modelDirectory
            } else {
                print("⚠️ Existing model is incomplete, resuming download...")
                try FileManager.default.removeItem(at: modelDirectory)
            }
        }
        return try await downloadModel(config, progress: progress)
    }
    
    /// Verifies that a downloaded model has all required files
    private func verifyDownloadedModel(at directory: URL, config: ModelConfiguration) async throws -> Bool {
        let requiredFiles = ["config.json", "tokenizer.json"]
        let optionalFiles = ["model.safetensors", "pytorch_model.bin", "model.gguf"]
        // Check for required files
        for fileName in requiredFiles {
            let filePath = directory.appendingPathComponent(fileName)
            if !FileManager.default.fileExists(atPath: filePath.path) {
                print("❌ Missing required file: \(fileName)")
                return false
            }
        }
        // Check for at least one model file
        var hasModelFile = false
        for fileName in optionalFiles {
            let filePath = directory.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: filePath.path) {
                hasModelFile = true
                print("✅ Found model file: \(fileName)")
                break
            }
        }
        if !hasModelFile {
            print("❌ No model weights file found")
            return false
        }
        print("✅ Model verification passed")
        return true
    }
    
    /// Gets information about a model from the Hub.
    public func getModelInfo(modelId: String) async throws -> ModelInfo {
        throw NSError(domain: "OptimizedDownloader", code: -1, userInfo: [NSLocalizedDescriptionKey: "Hub-based info not implemented. Replace with supported method."])
    }
    
    /// Calculates the total size of files to download
    private func calculateTotalSize(filenames: [String], modelId: String) async throws -> Int64 {
        var totalSize: Int64 = 0
        for filename in filenames {
            do {
                let url = URL(string: "https://huggingface.co/\(modelId)/resolve/main/\(filename)")!
                let (_, response) = try await URLSession.shared.data(from: url)
                if let httpResponse = response as? HTTPURLResponse {
                    totalSize += httpResponse.expectedContentLength
                }
            } catch {
                // Skip files that can't be checked
                continue
            }
        }
        return totalSize
    }
    
    /// Returns all downloaded models.
    public func getDownloadedModels() async throws -> [ModelConfiguration] {
        return [] // Placeholder
    }
    
    /// Cleans up incomplete downloads.
    public func cleanupIncompleteDownloads() async throws {
        // No-op for now
    }
}

// MARK: - Supporting Types

/// Information about a downloaded model.
public struct ModelInfo: Sendable {
    public let modelId: String
    public let totalFiles: Int
    public let modelFiles: Int
    public let configFiles: Int
    public let estimatedSizeGB: Double
    public let filenames: [String]
}

/// Errors related to optimized model downloading.
public enum OptimizedDownloadError: Error, LocalizedError {
    case downloadFailed(String)
    case modelInfoFailed(String)
    case verificationFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .downloadFailed(let message):
            return "Download failed: \(message)"
        case .modelInfoFailed(let message):
            return "Failed to get model info: \(message)"
        case .verificationFailed(let message):
            return "Model verification failed: \(message)"
        }
    }
} 
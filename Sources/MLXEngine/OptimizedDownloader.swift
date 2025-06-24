import Foundation
import Hub

/// Optimized model downloader using the Hub library for faster, more reliable downloads
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
    
    /// Downloads a model using the optimized Hub library
    public func downloadModel(_ config: ModelConfiguration, progress: @escaping @Sendable (Double) -> Void) async throws -> URL {
        let startTime = CFAbsoluteTimeGetCurrent()
        print("🚀 Starting optimized download for: \(config.hubId)")
        print("📁 Download base: \(downloadBase.path)")
        let hubApi = HubApi(downloadBase: downloadBase, useBackgroundSession: false)
        do {
            // Use Hub library's snapshot method for optimized downloads
            let modelDirectory = try await hubApi.snapshot(
                from: config.hubId,
                matching: ["*.safetensors", "*.json", "*.model"],
                progressHandler: { hubProgress in
                    let overallProgress = hubProgress.fractionCompleted
                    progress(overallProgress)
                    // Print detailed progress information
                    let percentage = Int(overallProgress * 100)
                    let completedFiles = hubProgress.completedUnitCount
                    let totalFiles = hubProgress.totalUnitCount
                    if totalFiles > 0 {
                        print("\r📊 Progress: \(percentage)% (\(completedFiles)/\(totalFiles) files)", terminator: "")
                        fflush(stdout)
                    }
                }
            )
            let downloadTime = CFAbsoluteTimeGetCurrent() - startTime
            print("\n✅ Download completed in \(String(format: "%.2f", downloadTime))s")
            print("📁 Model saved to: \(modelDirectory.path)")
            // Verify the downloaded files
            _ = try await verifyDownloadedModel(at: modelDirectory, config: config)
            return modelDirectory
        } catch {
            let downloadTime = CFAbsoluteTimeGetCurrent() - startTime
            print("\n❌ Download failed after \(String(format: "%.2f", downloadTime))s")
            throw OptimizedDownloadError.downloadFailed(error.localizedDescription)
        }
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
    
    /// Gets information about a model before downloading
    public func getModelInfo(modelId: String) async throws -> ModelInfo {
        let hubApi = HubApi(downloadBase: downloadBase, useBackgroundSession: false)
        do {
            let filenames = try await hubApi.getFilenames(from: modelId)
            let modelFiles = filenames.filter { $0.hasSuffix(".safetensors") || $0.hasSuffix(".bin") || $0.hasSuffix(".gguf") }
            let configFiles = filenames.filter { $0.hasSuffix(".json") }
            let totalSize = try await calculateTotalSize(filenames: filenames, modelId: modelId)
            return ModelInfo(
                modelId: modelId,
                totalFiles: filenames.count,
                modelFiles: modelFiles.count,
                configFiles: configFiles.count,
                estimatedSizeGB: Double(totalSize) / (1024 * 1024 * 1024),
                filenames: filenames
            )
        } catch {
            throw OptimizedDownloadError.modelInfoFailed(error.localizedDescription)
        }
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
    
    /// Lists all downloaded models
    public func getDownloadedModels() async throws -> [ModelConfiguration] {
        let modelsDirectory = downloadBase
        guard FileManager.default.fileExists(atPath: modelsDirectory.path) else {
            return []
        }
        let modelDirectories = try FileManager.default.contentsOfDirectory(
            at: modelsDirectory,
            includingPropertiesForKeys: nil
        )
        return modelDirectories.compactMap { url -> ModelConfiguration? in
            // Check if this is a model directory (contains model files)
            let hasConfig = FileManager.default.fileExists(atPath: url.appendingPathComponent("config.json").path)
            let hasTokenizer = FileManager.default.fileExists(atPath: url.appendingPathComponent("tokenizer.json").path)
            let hasModel = FileManager.default.fileExists(atPath: url.appendingPathComponent("model.safetensors").path) ||
                          FileManager.default.fileExists(atPath: url.appendingPathComponent("pytorch_model.bin").path) ||
                          FileManager.default.fileExists(atPath: url.appendingPathComponent("model.gguf").path)
            guard hasConfig && hasTokenizer && hasModel else { return nil as ModelConfiguration? }
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
        let modelsDirectory = downloadBase
        guard FileManager.default.fileExists(atPath: modelsDirectory.path) else {
            return
        }
        let modelDirectories = try FileManager.default.contentsOfDirectory(
            at: modelsDirectory,
            includingPropertiesForKeys: nil
        )
        for modelDirectory in modelDirectories {
            let hasConfig = FileManager.default.fileExists(atPath: modelDirectory.appendingPathComponent("config.json").path)
            let hasTokenizer = FileManager.default.fileExists(atPath: modelDirectory.appendingPathComponent("tokenizer.json").path)
            let hasModel = FileManager.default.fileExists(atPath: modelDirectory.appendingPathComponent("model.safetensors").path) ||
                          FileManager.default.fileExists(atPath: modelDirectory.appendingPathComponent("pytorch_model.bin").path) ||
                          FileManager.default.fileExists(atPath: modelDirectory.appendingPathComponent("model.gguf").path)
            // If missing required files, remove the directory
            if !hasConfig || !hasTokenizer || !hasModel {
                try FileManager.default.removeItem(at: modelDirectory)
                print("🧹 Cleaned up incomplete download: \(modelDirectory.lastPathComponent)")
            }
        }
    }
}

// MARK: - Supporting Types

public struct ModelInfo: Sendable {
    public let modelId: String
    public let totalFiles: Int
    public let modelFiles: Int
    public let configFiles: Int
    public let estimatedSizeGB: Double
    public let filenames: [String]
}

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
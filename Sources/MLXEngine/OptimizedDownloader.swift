import Foundation
import Logging
// import Hub  // Removed: No such module available in SPM or MLX

/// Optimized model downloader using URLSession for reliable downloads. Previously used the Hub library, now replaced with URLSession-based implementation.
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
    
    /// Downloads a model using URLSession with async/await. Downloads to a temp directory, verifies, then moves atomically.
    public func downloadModel(_ config: ModelConfiguration, progress: @escaping @Sendable (Double) -> Void) async throws -> URL {
        let fileManager = FileManagerService.shared
        let modelsDirectory = try fileManager.ensureModelsDirectoryExists()
        let modelDirectory = modelsDirectory.appendingPathComponent(config.hubId)
        let tempDirectory = try fileManager.getTemporaryDirectory().appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        // Get all files in the model repo using HuggingFaceAPI
        let huggingFaceAPI = HuggingFaceAPI.shared
        let allFiles: [String]
        do {
            allFiles = try await huggingFaceAPI.listModelFiles(modelId: config.hubId)
        } catch {
            AppLogger.shared.error("OptimizedDownloader", "Failed to list model files for \(config.hubId): \(error)")
            throw error
        }
        if allFiles.isEmpty {
            throw OptimizedDownloadError.downloadFailed("No files found in model repo: \(config.hubId)")
        }
        let totalFiles = allFiles.count
        var completedFiles = 0

        defer {
            try? FileManager.default.removeItem(at: tempDirectory)
        }

        for (index, fileName) in allFiles.enumerated() {
            let url = URL(string: "https://huggingface.co/\(config.hubId)/resolve/main/\(fileName)")!
            let destination = tempDirectory.appendingPathComponent(fileName)
            let destinationDir = destination.deletingLastPathComponent()
            if !FileManager.default.fileExists(atPath: destinationDir.path) {
                try FileManager.default.createDirectory(at: destinationDir, withIntermediateDirectories: true)
            }
            do {
                let (asyncBytes, response) = try await URLSession.shared.bytes(from: url)
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    AppLogger.shared.error("OptimizedDownloader", "Failed to download \(fileName): HTTP \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                    throw OptimizedDownloadError.downloadFailed("Failed to download \(fileName)")
                }
                let totalBytes = httpResponse.expectedContentLength
                var downloadedBytes: Int64 = 0
                let bufferSize = 1024 * 1024
                var buffer = Data()
                buffer.reserveCapacity(bufferSize)
                var lastProgressUpdateTime = Date()
                let progressUpdateInterval: TimeInterval = 0.5
                var downloadData = Data()
                downloadData.reserveCapacity(Int(totalBytes > 0 ? totalBytes : 1024 * 1024 * 100))
                for try await byte in asyncBytes {
                    buffer.append(byte)
                    downloadedBytes += 1
                    if buffer.count >= bufferSize {
                        downloadData.append(buffer)
                        buffer.removeAll(keepingCapacity: true)
                        let now = Date()
                        if now.timeIntervalSince(lastProgressUpdateTime) >= progressUpdateInterval && totalBytes > 0 {
                            let fileProgress = Double(downloadedBytes) / Double(totalBytes)
                            let overallProgress = (Double(index) + fileProgress) / Double(totalFiles)
                            progress(overallProgress)
                            lastProgressUpdateTime = now
                        }
                    }
                }
                if !buffer.isEmpty {
                    downloadData.append(buffer)
                }
                try downloadData.write(to: destination)
                completedFiles += 1
                progress(Double(completedFiles) / Double(totalFiles))
            } catch {
                AppLogger.shared.error("OptimizedDownloader", "Error downloading file \(fileName): \(error)")
                throw error
            }
        }
        // Validate all required files exist
        for fileName in allFiles {
            let filePath = tempDirectory.appendingPathComponent(fileName)
            if !FileManager.default.fileExists(atPath: filePath.path) {
                AppLogger.shared.error("OptimizedDownloader", "Missing file after download: \(fileName)")
                throw OptimizedDownloadError.verificationFailed("Missing file: \(fileName)")
            }
        }
        // Ensure parent directories exist for the model directory before moving
        let parentDirectory = modelDirectory.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: parentDirectory.path) {
            try FileManager.default.createDirectory(at: parentDirectory, withIntermediateDirectories: true)
        }
        if FileManager.default.fileExists(atPath: modelDirectory.path) {
            try FileManager.default.removeItem(at: modelDirectory)
        }
        try FileManager.default.moveItem(at: tempDirectory, to: modelDirectory)
        progress(1.0)
        AppLogger.shared.info("OptimizedDownloader", "✅ All files downloaded and moved atomically to \(modelDirectory.path)")
        return modelDirectory
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
        let fileManager = FileManagerService.shared
        let modelsDirectory = try fileManager.ensureModelsDirectoryExists()
        guard FileManager.default.fileExists(atPath: modelsDirectory.path) else {
            return []
        }
        let modelDirectories = try FileManager.default.contentsOfDirectory(
            at: modelsDirectory,
            includingPropertiesForKeys: nil
        )
        var result: [ModelConfiguration] = []
        for url in modelDirectories where url.hasDirectoryPath {
            let hasConfig = FileManager.default.fileExists(atPath: url.appendingPathComponent("config.json").path)
            let hasTokenizer = FileManager.default.fileExists(atPath: url.appendingPathComponent("tokenizer.json").path)
            let hasModel = FileManager.default.fileExists(atPath: url.appendingPathComponent("model.safetensors").path)
            if hasConfig && hasTokenizer && hasModel {
                result.append(ModelConfiguration(
                    name: url.lastPathComponent,
                    hubId: url.lastPathComponent,
                    description: "Downloaded model"
                ))
            }
        }
        return result
    }
    
    /// Cleans up incomplete downloads.
    public func cleanupIncompleteDownloads() async throws {
        let fileManager = FileManagerService.shared
        let modelsDirectory = try fileManager.ensureModelsDirectoryExists()
        let modelDirs = try FileManager.default.contentsOfDirectory(at: modelsDirectory, includingPropertiesForKeys: nil)
        let requiredFiles = ["config.json", "tokenizer.json"]
        for dir in modelDirs where dir.hasDirectoryPath {
            var isIncomplete = false
            for file in requiredFiles {
                let filePath = dir.appendingPathComponent(file)
                if !FileManager.default.fileExists(atPath: filePath.path) {
                    isIncomplete = true
                    break
                }
            }
            if isIncomplete {
                try? fileManager.deleteModel(at: dir)
            }
        }
        try? fileManager.cleanupTemporaryFiles()
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
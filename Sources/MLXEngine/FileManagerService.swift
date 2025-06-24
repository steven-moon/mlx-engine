import Foundation
import os.log

/// Cross-platform file management service for MLXEngine
public class FileManagerService: @unchecked Sendable {
    private let logger = Logger(subsystem: "com.mlxengine", category: "FileManagerService")
    
    public static let shared: FileManagerService = {
        let service = FileManagerService()
        return service
    }()
    
    private init() {
        logger.info("📁 FileManagerService initialized")
    }
    
    /// Gets the models directory, creating it if it doesn't exist
    /// Uses platform-appropriate directories: iOS documents vs macOS application support
    public func getModelsDirectory() throws -> URL {
        logger.info("📁 Getting models directory")
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let baseDirectory: URL
        
        #if os(iOS)
        // iOS: Use app's documents directory
        baseDirectory = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let modelsDirectory = baseDirectory.appendingPathComponent("Models")
        #else
        // macOS: Use application support directory
        let appSupport = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let appDirectory = appSupport.appendingPathComponent("MLXEngine", isDirectory: true)
        let modelsDirectory = appDirectory.appendingPathComponent("Models")
        #endif
        
        // Create directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: modelsDirectory.path) {
            try FileManager.default.createDirectory(
                at: modelsDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
            logger.info("📁 Created models directory at: \(modelsDirectory.path)")
        }
        
        let getTime = CFAbsoluteTimeGetCurrent() - startTime
        logger.info("📁 Got models directory in \(String(format: "%.3f", getTime))s")
        
        return modelsDirectory
    }
    
    /// Ensures the models directory exists and returns its URL
    public func ensureModelsDirectoryExists() throws -> URL {
        return try getModelsDirectory()
    }
    
    /// Checks if a model is already downloaded
    public func isModelDownloaded(modelId: String) async -> Bool {
        do {
            let modelsDirectory = try getModelsDirectory()
            let modelDirectory = modelsDirectory.appendingPathComponent(modelId)
            return FileManager.default.fileExists(atPath: modelDirectory.path)
        } catch {
            return false
        }
    }
    
    /// Gets the local path for a downloaded model
    public func getModelPath(modelId: String) throws -> URL {
        let modelsDirectory = try getModelsDirectory()
        return modelsDirectory.appendingPathComponent(modelId)
    }
    
    /// Gets the cache directory for temporary files
    public func getCacheDirectory() throws -> URL {
        logger.info("📁 Getting cache directory")
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let cacheDirectory = try FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        
        let mlxCacheDirectory = cacheDirectory.appendingPathComponent("MLXEngine")
        
        // Create directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: mlxCacheDirectory.path) {
            try FileManager.default.createDirectory(
                at: mlxCacheDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
            logger.info("📁 Created cache directory at: \(mlxCacheDirectory.path)")
        }
        
        let getTime = CFAbsoluteTimeGetCurrent() - startTime
        logger.info("📁 Got cache directory in \(String(format: "%.3f", getTime))s")
        
        return mlxCacheDirectory
    }
    
    /// Gets the application support directory for configuration files
    public func getApplicationSupportDirectory() throws -> URL {
        logger.info("📁 Getting Application Support directory")
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let appSupport = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        
        let appDirectory = appSupport.appendingPathComponent("MLXEngine", isDirectory: true)
        
        // Create app directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: appDirectory.path) {
            try FileManager.default.createDirectory(
                at: appDirectory, 
                withIntermediateDirectories: true,
                attributes: nil
            )
            logger.info("📁 Created application support directory at: \(appDirectory.path)")
        }
        
        let getTime = CFAbsoluteTimeGetCurrent() - startTime
        logger.info("📁 Got application support directory in \(String(format: "%.3f", getTime))s")
        
        return appDirectory
    }
    
    /// Gets the temporary directory for downloads in progress
    public func getTemporaryDirectory() throws -> URL {
        logger.info("📁 Getting temporary directory")
        
        let tempDirectory = FileManager.default.temporaryDirectory
        let mlxTempDirectory = tempDirectory.appendingPathComponent("MLXEngine")
        
        // Create directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: mlxTempDirectory.path) {
            try FileManager.default.createDirectory(
                at: mlxTempDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
            logger.info("📁 Created temporary directory at: \(mlxTempDirectory.path)")
        }
        
        return mlxTempDirectory
    }
    
    /// Deletes a model directory or file
    public func deleteModel(at url: URL) throws {
        logger.info("🗑️ Deleting model at \(url.lastPathComponent)")
        let startTime = CFAbsoluteTimeGetCurrent()
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            logger.warning("⚠️ File does not exist at path: \(url.path)")
            throw FileManagerError.fileNotFound(url.path)
        }
        
        try FileManager.default.removeItem(at: url)
        
        let deleteTime = CFAbsoluteTimeGetCurrent() - startTime
        logger.info("✅ Model deleted in \(String(format: "%.3f", deleteTime))s")
    }
    
    /// Checks if a file exists
    public func fileExists(at url: URL) -> Bool {
        let exists = FileManager.default.fileExists(atPath: url.path)
        logger.debug("🔍 File exists at \(url.lastPathComponent): \(exists)")
        return exists
    }
    
    /// Gets the size of a file in bytes
    public func getFileSize(at url: URL) throws -> Int64 {
        logger.debug("📏 Getting file size for \(url.lastPathComponent)")
        let startTime = CFAbsoluteTimeGetCurrent()
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw FileManagerError.fileNotFound(url.path)
        }
        
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        let fileSize = attributes[.size] as? Int64 ?? 0
        
        let getTime = CFAbsoluteTimeGetCurrent() - startTime
        logger.debug("📏 File size retrieved in \(String(format: "%.3f", getTime))s: \(fileSize) bytes")
        
        return fileSize
    }
    
    /// Gets the total size of a directory in bytes
    public func getDirectorySize(at url: URL) throws -> Int64 {
        logger.info("📏 Getting directory size for \(url.lastPathComponent)")
        let startTime = CFAbsoluteTimeGetCurrent()
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw FileManagerError.directoryNotFound(url.path)
        }
        
        var totalSize: Int64 = 0
        let resourceKeys: [URLResourceKey] = [.isRegularFileKey, .fileSizeKey]
        let directoryEnumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles],
            errorHandler: nil
        )
        
        while let fileURL = directoryEnumerator?.nextObject() as? URL {
            let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
            if resourceValues.isRegularFile == true {
                totalSize += Int64(resourceValues.fileSize ?? 0)
            }
        }
        
        let getTime = CFAbsoluteTimeGetCurrent() - startTime
        logger.info("📏 Directory size calculated in \(String(format: "%.3f", getTime))s: \(totalSize) bytes")
        
        return totalSize
    }
    
    /// Moves a file or directory to a new location
    public func moveItem(from sourceURL: URL, to destinationURL: URL) throws {
        logger.info("📦 Moving item from \(sourceURL.lastPathComponent) to \(destinationURL.lastPathComponent)")
        let startTime = CFAbsoluteTimeGetCurrent()
        
        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            throw FileManagerError.fileNotFound(sourceURL.path)
        }
        
        // Create destination directory if needed
        let destinationDir = destinationURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: destinationDir.path) {
            try FileManager.default.createDirectory(
                at: destinationDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        
        // Remove destination if it exists
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        
        try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
        
        let moveTime = CFAbsoluteTimeGetCurrent() - startTime
        logger.info("✅ Item moved in \(String(format: "%.3f", moveTime))s")
    }
    
    /// Copies a file or directory to a new location
    public func copyItem(from sourceURL: URL, to destinationURL: URL) throws {
        logger.info("📋 Copying item from \(sourceURL.lastPathComponent) to \(destinationURL.lastPathComponent)")
        let startTime = CFAbsoluteTimeGetCurrent()
        
        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            throw FileManagerError.fileNotFound(sourceURL.path)
        }
        
        // Create destination directory if needed
        let destinationDir = destinationURL.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: destinationDir.path) {
            try FileManager.default.createDirectory(
                at: destinationDir,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        
        // Remove destination if it exists
        if FileManager.default.fileExists(atPath: destinationURL.path) {
            try FileManager.default.removeItem(at: destinationURL)
        }
        
        try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
        
        let copyTime = CFAbsoluteTimeGetCurrent() - startTime
        logger.info("✅ Item copied in \(String(format: "%.3f", copyTime))s")
    }
    
    /// Lists all files in a directory
    public func listFiles(in directory: URL) throws -> [URL] {
        logger.debug("📂 Listing files in \(directory.lastPathComponent)")
        
        guard FileManager.default.fileExists(atPath: directory.path) else {
            throw FileManagerError.directoryNotFound(directory.path)
        }
        
        let files = try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ).filter { url in
            (try? url.resourceValues(forKeys: [.isRegularFileKey]))?.isRegularFile == true
        }
        
        logger.debug("📂 Found \(files.count) files")
        return files
    }
    
    /// Cleans up temporary files
    public func cleanupTemporaryFiles() throws {
        logger.info("🧹 Cleaning up temporary files")
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let tempDirectory = try getTemporaryDirectory()
        let files = try listFiles(in: tempDirectory)
        
        var deletedCount = 0
        for file in files {
            do {
                try FileManager.default.removeItem(at: file)
                deletedCount += 1
            } catch {
                logger.warning("⚠️ Failed to delete temporary file: \(file.lastPathComponent)")
            }
        }
        
        let cleanupTime = CFAbsoluteTimeGetCurrent() - startTime
        logger.info("🧹 Cleaned up \(deletedCount) temporary files in \(String(format: "%.3f", cleanupTime))s")
    }
}

// MARK: - Error Types

public enum FileManagerError: Error, LocalizedError {
    case directoryNotFound(String)
    case fileNotFound(String)
    case permissionDenied(String)
    case diskFull
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .directoryNotFound(let path):
            return "Directory not found: \(path)"
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .permissionDenied(let path):
            return "Permission denied: \(path)"
        case .diskFull:
            return "Disk full"
        case .unknown(let error):
            return "Unknown file manager error: \(error.localizedDescription)"
        }
    }
} 
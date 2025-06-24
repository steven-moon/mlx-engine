import Foundation
import os.log

/// Hugging Face Hub API client for searching and downloading models
public class HuggingFaceAPI: @unchecked Sendable {
    public static let shared = HuggingFaceAPI()
    
    private let baseURL = "https://huggingface.co/api"
    private let session: URLSession
    private var hfToken: String?
    private let logger = Logger(subsystem: "com.mlxengine", category: "HuggingFaceAPI")
    
    private init() {
        // Enhanced URLSession configuration for better performance
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 300 // 5 minutes
        configuration.timeoutIntervalForResource = 3600 // 1 hour
        configuration.waitsForConnectivity = true
        configuration.allowsCellularAccess = true
        configuration.allowsExpensiveNetworkAccess = true
        configuration.allowsConstrainedNetworkAccess = true
        
        // Enable HTTP/2 for better performance
        configuration.httpShouldUsePipelining = true
        configuration.httpMaximumConnectionsPerHost = 6 // Allow multiple concurrent connections
        
        // Enable connection pooling and reuse
        configuration.connectionProxyDictionary = [
            kCFNetworkProxiesHTTPEnable: true,
            kCFNetworkProxiesHTTPSEnable: true
        ]
        
        session = URLSession(configuration: configuration)
        
        // Try to load token from various sources
        self.hfToken = Self.loadHuggingFaceToken()
    }
    
    /// Sets the Hugging Face token for authentication
    public func setToken(_ token: String) {
        self.hfToken = token
    }
    
    /// Clears the current token
    public func clearToken() {
        self.hfToken = nil
    }
    
    /// Returns true if a token is available
    public var hasToken: Bool {
        return hfToken != nil
    }
    
    /// Loads Hugging Face token from various sources following established patterns
    private static func loadHuggingFaceToken() -> String? {
        let possibleTokens = [
            // Environment variables
            { ProcessInfo.processInfo.environment["HF_TOKEN"] },
            { ProcessInfo.processInfo.environment["HUGGING_FACE_HUB_TOKEN"] },
            
            // Token file paths from environment
            {
                ProcessInfo.processInfo.environment["HF_TOKEN_PATH"].flatMap {
                    try? String(
                        contentsOf: URL(filePath: NSString(string: $0).expandingTildeInPath),
                        encoding: .utf8
                    ).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            },
            {
                ProcessInfo.processInfo.environment["HF_HOME"].flatMap {
                    try? String(
                        contentsOf: URL(filePath: NSString(string: $0).expandingTildeInPath).appending(path: "token"),
                        encoding: .utf8
                    ).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            },
            
            // Standard token file locations
            { 
                try? String(
                    contentsOf: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".cache/huggingface/token"), 
                    encoding: .utf8
                ).trimmingCharacters(in: .whitespacesAndNewlines)
            },
            { 
                try? String(
                    contentsOf: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".huggingface/token"), 
                    encoding: .utf8
                ).trimmingCharacters(in: .whitespacesAndNewlines)
            },
            
            // MLXEngine-specific token location
            {
                #if os(iOS)
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                #else
                let documentsPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                #endif
                let tokenPath = documentsPath.appendingPathComponent("MLXEngine/hf_token")
                return try? String(contentsOf: tokenPath, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        ]
        
        return possibleTokens
            .lazy
            .compactMap { $0() }
            .filter { !$0.isEmpty }
            .first
    }
    
    /// Saves the Hugging Face token to a secure location
    public func saveToken(_ token: String) throws {
        #if os(iOS)
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        #else
        let documentsPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        #endif
        
        let mlxEnginePath = documentsPath.appendingPathComponent("MLXEngine")
        let tokenPath = mlxEnginePath.appendingPathComponent("hf_token")
        
        // Create directory if it doesn't exist
        try FileManager.default.createDirectory(at: mlxEnginePath, withIntermediateDirectories: true)
        
        // Save token
        try token.write(to: tokenPath, atomically: true, encoding: .utf8)
        
        // Set token for current session
        self.hfToken = token
    }
    
    /// Creates an authenticated URLRequest with proper headers
    private func createAuthenticatedRequest(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        
        // Add authentication header if token is available
        if let token = hfToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add standard headers
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("MLXEngine/1.0", forHTTPHeaderField: "User-Agent")
        
        return request
    }
    
    /// Performs an authenticated HTTP request with proper error handling
    private func performAuthenticatedRequest(for url: URL) async throws -> (Data, HTTPURLResponse) {
        let request = createAuthenticatedRequest(for: url)
        
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw HuggingFaceError.networkError
            }
            
            switch httpResponse.statusCode {
            case 200..<300:
                return (data, httpResponse)
            case 401, 403:
                throw HuggingFaceError.authenticationRequired
            case 404:
                throw HuggingFaceError.modelNotFound(url.lastPathComponent)
            case 429:
                throw HuggingFaceError.rateLimitExceeded
            default:
                throw HuggingFaceError.httpError(httpResponse.statusCode)
            }
        } catch let error as HuggingFaceError {
            throw error
        } catch {
            throw HuggingFaceError.networkError
        }
    }
    
    /// Searches for models on Hugging Face Hub
    public func searchModels(query: String, limit: Int = 20) async throws -> [HuggingFaceModel] {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "\(baseURL)/models?search=\(encodedQuery)&limit=\(limit)"
        
        guard let url = URL(string: urlString) else {
            throw HuggingFaceError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HuggingFaceError.networkError
        }
        
        if httpResponse.statusCode != 200 {
            logger.error("HTTP Error: \(httpResponse.statusCode)")
            if let errorData = String(data: data, encoding: .utf8) {
                logger.error("Error response: \(errorData)")
            }
            throw HuggingFaceError.networkError
        }
        
        let models = try JSONDecoder().decode([HuggingFaceModel].self, from: data)
        return models
    }
    
    /// Gets detailed information about a specific model
    public func getModelInfo(modelId: String) async throws -> HuggingFaceModel {
        let encodedModelId = modelId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        let urlString = "\(baseURL)/models/\(encodedModelId)"
        
        guard let url = URL(string: urlString) else {
            throw HuggingFaceError.invalidURL
        }
        
        let (data, _) = try await performAuthenticatedRequest(for: url)
        let model = try JSONDecoder().decode(HuggingFaceModel.self, from: data)
        return model
    }
    
    /// Downloads a model file from Hugging Face with enhanced performance and progress tracking
    public func downloadModel(modelId: String, fileName: String, to destinationURL: URL, progress: @escaping @Sendable (Double) -> Void) async throws {
        let encodedModelId = modelId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        let encodedFileName = fileName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        let urlString = "https://huggingface.co/\(encodedModelId)/resolve/main/\(encodedFileName)"
        
        guard let url = URL(string: urlString) else {
            throw HuggingFaceError.invalidURL
        }
        
        let (asyncBytes, response) = try await session.bytes(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw HuggingFaceError.networkError
        }
        
        let totalBytes = httpResponse.expectedContentLength
        var downloadedBytes: Int64 = 0
        let bufferSize = 1024 * 1024 // 1MB buffer for better performance
        var buffer = Data()
        buffer.reserveCapacity(bufferSize)
        var lastProgressUpdateTime = Date()
        let progressUpdateInterval: TimeInterval = 0.5 // 500ms for less frequent updates
        
        // Use Data.write(to:) for better performance than FileHandle
        var downloadData = Data()
        downloadData.reserveCapacity(Int(totalBytes > 0 ? totalBytes : 1024 * 1024 * 100)) // Reserve 100MB if size unknown
        
        do {
            for try await byte in asyncBytes {
                if Task.isCancelled {
                    throw CancellationError()
                }
                buffer.append(byte)
                downloadedBytes += 1
                
                if buffer.count >= bufferSize {
                    downloadData.append(buffer)
                    buffer.removeAll(keepingCapacity: true)
                    
                    // Throttle progress updates to reduce overhead
                    if totalBytes > 0 {
                        let now = Date()
                        if now.timeIntervalSince(lastProgressUpdateTime) >= progressUpdateInterval {
                            let progressValue = Double(downloadedBytes) / Double(totalBytes)
                            progress(progressValue)
                            lastProgressUpdateTime = now
                        }
                    }
                }
            }
            
            // Append any remaining bytes
            if !buffer.isEmpty {
                downloadData.append(buffer)
            }
            
            // Write the complete file at once for better performance
            try downloadData.write(to: destinationURL)
            
            // Always send a final progress update at 100%
            if totalBytes > 0 {
                let progressValue = Double(downloadedBytes) / Double(totalBytes)
                progress(progressValue)
            }
        } catch {
            // Remove partial file on error or cancellation
            try? FileManager.default.removeItem(at: destinationURL)
            if error is CancellationError {
                throw CancellationError()
            } else {
                throw error
            }
        }
    }
    
    /// Gets the file size for a model file from Hugging Face (HEAD request)
    public func getFileSize(modelId: String, fileName: String) async throws -> Int64 {
        let encodedModelId = modelId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        let encodedFileName = fileName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        let urlString = "https://huggingface.co/\(encodedModelId)/resolve/main/\(encodedFileName)"
        guard let url = URL(string: urlString) else {
            throw HuggingFaceError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw HuggingFaceError.networkError
        }
        let totalBytes = httpResponse.expectedContentLength
        return totalBytes > 0 ? totalBytes : 0
    }
    
    /// Debug function to dump full model JSON for inspection
    public func dumpModelJSON(modelId: String) async throws -> String {
        let encodedModelId = modelId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        let urlString = "\(baseURL)/models/\(encodedModelId)"
        
        guard let url = URL(string: urlString) else {
            throw HuggingFaceError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw HuggingFaceError.networkError
        }
        
        // Pretty print the JSON
        let jsonObject = try JSONSerialization.jsonObject(with: data)
        if let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            return prettyString
        }
        
        // Fallback to raw data
        return String(data: data, encoding: .utf8) ?? "Unable to decode JSON"
    }
}

// MARK: - Data Models

public struct HuggingFaceModel: Codable, Identifiable, Hashable {
    public let id: String
    public let modelId: String?
    public let author: String?
    public let downloads: Int?
    public let likes: Int?
    public let tags: [String]?
    public let pipeline_tag: String?
    public let createdAt: String?
    public let lastModified: String?
    
    // Additional fields from detailed model info
    public let private_: Bool?
    public let gated: Bool?
    public let disabled: Bool?
    public let sha: String?
    public let library_name: String?
    public let safetensors: Bool?
    public let usedStorage: Int?
    public let trendingScore: Int?
    
    // Complex nested structures
    public let cardData: [String: AnyCodable]?
    public let siblings: [Sibling]?
    public let config: [String: AnyCodable]?
    public let transformersInfo: [String: AnyCodable]?
    public let spaces: [String]?
    public let modelIndex: String?
    public let widgetData: [String: AnyCodable]?
    
    public init(id: String, modelId: String? = nil, author: String? = nil, downloads: Int? = nil, likes: Int? = nil, tags: [String]? = nil, pipeline_tag: String? = nil, createdAt: String? = nil, lastModified: String? = nil, private_: Bool? = nil, gated: Bool? = nil, disabled: Bool? = nil, sha: String? = nil, library_name: String? = nil, safetensors: Bool? = nil, usedStorage: Int? = nil, trendingScore: Int? = nil, cardData: [String: AnyCodable]? = nil, siblings: [Sibling]? = nil, config: [String: AnyCodable]? = nil, transformersInfo: [String: AnyCodable]? = nil, spaces: [String]? = nil, modelIndex: String? = nil, widgetData: [String: AnyCodable]? = nil) {
        self.id = id
        self.modelId = modelId
        self.author = author
        self.downloads = downloads
        self.likes = likes
        self.tags = tags
        self.pipeline_tag = pipeline_tag
        self.createdAt = createdAt
        self.lastModified = lastModified
        self.private_ = private_
        self.gated = gated
        self.disabled = disabled
        self.sha = sha
        self.library_name = library_name
        self.safetensors = safetensors
        self.usedStorage = usedStorage
        self.trendingScore = trendingScore
        self.cardData = cardData
        self.siblings = siblings
        self.config = config
        self.transformersInfo = transformersInfo
        self.spaces = spaces
        self.modelIndex = modelIndex
        self.widgetData = widgetData
    }
    
    // MARK: - Enhanced Metadata Extraction
    
    public func extractParameters() -> String? {
        // Try multiple sources for parameter information
        let name = id.lowercased()
        
        // Check name patterns
        if name.contains("0.5b") { return "0.5B" }
        if name.contains("1b") { return "1B" }
        if name.contains("1.5b") { return "1.5B" }
        if name.contains("2b") { return "2B" }
        if name.contains("3b") { return "3B" }
        if name.contains("3.1") { return "3.1B" }
        if name.contains("7b") { return "7B" }
        if name.contains("8b") { return "8B" }
        if name.contains("9b") { return "9B" }
        if name.contains("13b") { return "13B" }
        if name.contains("30b") { return "30B" }
        
        // Check cardData for parameter info
        if let cardData = cardData {
            if let modelCard = cardData["model-card"]?.value as? [String: Any],
               let modelInfo = modelCard["model-info"] as? [String: Any],
               let params = modelInfo["parameters"] as? String {
                return params
            }
        }
        
        // Check tags for parameter hints
        if let tags = tags {
            for tag in tags {
                if tag.contains("0.5b") { return "0.5B" }
                if tag.contains("1b") { return "1B" }
                if tag.contains("2b") { return "2B" }
                if tag.contains("3b") { return "3B" }
                if tag.contains("7b") { return "7B" }
                if tag.contains("8b") { return "8B" }
                if tag.contains("13b") { return "13B" }
                if tag.contains("30b") { return "30B" }
            }
        }
        
        return nil
    }
    
    public func extractQuantization() -> String? {
        let name = id.lowercased()
        
        // Check name patterns
        if name.contains("4bit") || name.contains("q4") { return "4bit" }
        if name.contains("6bit") || name.contains("q6") { return "6bit" }
        if name.contains("8bit") || name.contains("q8") { return "8bit" }
        if name.contains("fp16") { return "fp16" }
        if name.contains("fp32") { return "fp32" }
        if name.contains("bf16") { return "bf16" }
        
        // Check tags for quantization hints
        if let tags = tags {
            for tag in tags {
                if tag.contains("4-bit") || tag.contains("q4") { return "4bit" }
                if tag.contains("6-bit") || tag.contains("q6") { return "6bit" }
                if tag.contains("8-bit") || tag.contains("q8") { return "8bit" }
                if tag.contains("fp16") { return "fp16" }
                if tag.contains("fp32") { return "fp32" }
                if tag.contains("bf16") { return "bf16" }
            }
        }
        
        return nil
    }
    
    public func extractArchitecture() -> String? {
        let name = id.lowercased()
        
        // Check name patterns
        if name.contains("llama") { return "Llama" }
        if name.contains("qwen") { return "Qwen" }
        if name.contains("mistral") { return "Mistral" }
        if name.contains("phi") { return "Phi" }
        if name.contains("gemma") { return "Gemma" }
        if name.contains("deepseek") { return "DeepSeek" }
        if name.contains("devstral") { return "Devstral" }
        
        // Check tags for architecture hints
        if let tags = tags {
            for tag in tags {
                if tag.contains("llama") { return "Llama" }
                if tag.contains("qwen") { return "Qwen" }
                if tag.contains("mistral") { return "Mistral" }
                if tag.contains("phi") { return "Phi" }
                if tag.contains("gemma") { return "Gemma" }
                if tag.contains("deepseek") { return "DeepSeek" }
                if tag.contains("devstral") { return "Devstral" }
            }
        }
        
        // Check cardData for architecture info
        if let cardData = cardData {
            if let modelCard = cardData["model-card"]?.value as? [String: Any],
               let modelInfo = modelCard["model-info"] as? [String: Any],
               let arch = modelInfo["architecture"] as? String {
                return arch
            }
        }
        
        return nil
    }
    
    /// Check if model has MLX-compatible files
    public func hasMLXFiles() -> Bool {
        // Primary check: library_name is mlx
        if library_name?.lowercased() == "mlx" {
            return true
        }
        
        // Secondary check: tags contain mlx
        if let tags = tags {
            if tags.contains(where: { $0.lowercased() == "mlx" }) {
                return true
            }
        }
        
        // Tertiary check: model name contains mlx
        if id.lowercased().contains("mlx") {
            return true
        }
        
        // Quaternary check: siblings contain .mlx files (most strict)
        if let siblings = siblings {
            for sibling in siblings {
                let filename = sibling.rfilename.lowercased()
                if filename.contains(".mlx") || filename.contains("mlx") {
                    return true
                }
            }
        }
        
        return false
    }
    
    /// Check if model is accessible (not private, gated, or disabled)
    public func isAccessible() -> Bool {
        return !(private_ == true || gated == true || disabled == true)
    }
    
    /// Get estimated file size in MB
    public func getEstimatedSizeMB() -> Int? {
        guard let parameters = extractParameters() else { return nil }
        
        // Rough estimation based on parameters and quantization
        let paramCount: Int
        if parameters.contains("0.5B") { paramCount = 500_000_000 }
        else if parameters.contains("1B") { paramCount = 1_000_000_000 }
        else if parameters.contains("1.5B") { paramCount = 1_500_000_000 }
        else if parameters.contains("2B") { paramCount = 2_000_000_000 }
        else if parameters.contains("3B") { paramCount = 3_000_000_000 }
        else if parameters.contains("7B") { paramCount = 7_000_000_000 }
        else if parameters.contains("8B") { paramCount = 8_000_000_000 }
        else if parameters.contains("13B") { paramCount = 13_000_000_000 }
        else if parameters.contains("30B") { paramCount = 30_000_000_000 }
        else { return nil }
        
        let quantization = extractQuantization() ?? ""
        let bytesPerParam: Double
        
        if quantization.contains("4bit") { bytesPerParam = 0.5 }
        else if quantization.contains("6bit") { bytesPerParam = 0.75 }
        else if quantization.contains("8bit") { bytesPerParam = 1.0 }
        else if quantization.contains("fp16") || quantization.contains("bf16") { bytesPerParam = 2.0 }
        else { bytesPerParam = 4.0 } // fp32 default
        
        let sizeBytes = Double(paramCount) * bytesPerParam
        return Int(sizeBytes / 1_048_576) // Convert to MB
    }
    
    // MARK: - Hashable Implementation
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: HuggingFaceModel, rhs: HuggingFaceModel) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Supporting Structures

public struct Sibling: Codable {
    public let rfilename: String
    public let size: Int?
    
    public init(rfilename: String, size: Int?) {
        self.rfilename = rfilename
        self.size = size
    }
}

// MARK: - AnyCodable for flexible JSON parsing

public struct AnyCodable: Codable {
    public let value: Any
    
    public init(_ value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let uint = try? container.decode(UInt.self) {
            self.value = uint
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self.value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let uint as UInt:
            try container.encode(uint)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            let context = EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded")
            throw EncodingError.invalidValue(self.value, context)
        }
    }
}

// MARK: - Error Types

public enum HuggingFaceError: Error, LocalizedError {
    case invalidURL
    case networkError
    case decodingError
    case fileError
    case authenticationRequired
    case modelNotFound(String)
    case rateLimitExceeded
    case httpError(Int)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError:
            return "Network error occurred"
        case .decodingError:
            return "Failed to decode response"
        case .fileError:
            return "File operation failed"
        case .authenticationRequired:
            return "Authentication required"
        case .modelNotFound(let modelId):
            return "Model not found: \(modelId)"
        case .rateLimitExceeded:
            return "Rate limit exceeded"
        case .httpError(let code):
            return "HTTP error: \(code)"
        }
    }
} 
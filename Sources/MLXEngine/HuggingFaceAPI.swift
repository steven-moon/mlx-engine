import Foundation
import Logging

/// Hugging Face Hub API client for searching and downloading models
public actor HuggingFaceAPI {
  public static let shared = HuggingFaceAPI()

  private let baseURL = "https://huggingface.co/api"
  private let session: URLSession

  public init() {
    let configuration = URLSessionConfiguration.default
    configuration.timeoutIntervalForRequest = 300  // 5 minutes
    configuration.timeoutIntervalForResource = 3600  // 1 hour
    configuration.waitsForConnectivity = true
    configuration.allowsCellularAccess = true
    configuration.allowsExpensiveNetworkAccess = true
    configuration.allowsConstrainedNetworkAccess = true

    // Enable HTTP/2 for better performance
    configuration.httpShouldUsePipelining = true
    configuration.httpMaximumConnectionsPerHost = 6  // Allow multiple concurrent connections

    session = URLSession(configuration: configuration)
  }

  // Helper to get the current token from AppStorage (UserDefaults)
  private func currentToken() -> String? {
    UserDefaults.standard.string(forKey: "huggingFaceToken")
  }

  /// Searches for models on Hugging Face Hub
  public func searchModels(query: String, limit: Int = 20) async throws -> [HuggingFaceModel] {
    AppLogger.shared.info(
      "HuggingFaceAPI", "Searching models with query: \(query), limit: \(limit)")
    let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
    let urlString = "\(baseURL)/models?search=\(encodedQuery)&limit=\(limit)"

    AppLogger.shared.debug("HuggingFaceAPI", "Request URL: \(urlString)")

    guard let url = URL(string: urlString) else {
      throw HuggingFaceError.invalidURL
    }

    var request = URLRequest(url: url)
    if let token = currentToken(), !token.isEmpty {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    let (data, response) = try await session.data(for: request)

    AppLogger.shared.debug("HuggingFaceAPI", "Response size: \(data.count) bytes")

    guard let httpResponse = response as? HTTPURLResponse else {
      throw HuggingFaceError.networkError
    }

    AppLogger.shared.info("HuggingFaceAPI", "HTTP response status: \(httpResponse.statusCode)")
    if httpResponse.statusCode != 200 {
      AppLogger.shared.error("HuggingFaceAPI", "HTTP Error: \(httpResponse.statusCode)")
      if let errorData = String(data: data, encoding: .utf8) {
        AppLogger.shared.error("HuggingFaceAPI", "Error response: \(errorData)")
      }
      throw HuggingFaceError.networkError
    }

    let models = try JSONDecoder().decode([HuggingFaceModel].self, from: data)
    AppLogger.shared.info("HuggingFaceAPI", "Models found: \(models.count)")
    return models
  }

  /// Gets detailed information about a specific model
  public func getModelInfo(modelId: String) async throws -> HuggingFaceModel {
    AppLogger.shared.info("HuggingFaceAPI", "Getting model info for: \(modelId)")
    let encodedModelId = modelId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
    let urlString = "\(baseURL)/models/\(encodedModelId)"

    AppLogger.shared.debug("HuggingFaceAPI", "Request URL: \(urlString)")

    guard let url = URL(string: urlString) else {
      throw HuggingFaceError.invalidURL
    }

    var request = URLRequest(url: url)
    if let token = currentToken(), !token.isEmpty {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    let (data, response) = try await session.data(for: request)

    AppLogger.shared.debug("HuggingFaceAPI", "Response size: \(data.count) bytes")

    guard let httpResponse = response as? HTTPURLResponse,
      httpResponse.statusCode == 200
    else {
      throw HuggingFaceError.networkError
    }

    AppLogger.shared.info("HuggingFaceAPI", "HTTP response status: \(httpResponse.statusCode)")
    let model = try JSONDecoder().decode(HuggingFaceModel.self, from: data)
    AppLogger.shared.info("HuggingFaceAPI", "Model info retrieved")
    return model
  }

  /// Downloads a model file from Hugging Face
  public func downloadModel(
    modelId: String, fileName: String, to destinationURL: URL,
    progress: @escaping (Double, Int64, Int64) -> Void
  ) async throws {
    let encodedModelId = modelId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
    let encodedFileName =
      fileName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
    let urlString = "https://huggingface.co/\(encodedModelId)/resolve/main/\(encodedFileName)"

    AppLogger.shared.debug("HuggingFaceAPI", "Request URL: \(urlString)")

    guard let url = URL(string: urlString) else {
      throw HuggingFaceError.invalidURL
    }

    var request = URLRequest(url: url)
    if let token = currentToken(), !token.isEmpty {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    let (asyncBytes, response) = try await session.bytes(for: request)

    AppLogger.shared.debug(
      "HuggingFaceAPI", "Response size: \(response.expectedContentLength) bytes")

    guard let httpResponse = response as? HTTPURLResponse,
      httpResponse.statusCode == 200
    else {
      throw HuggingFaceError.networkError
    }

    let totalBytes = httpResponse.expectedContentLength
    var downloadedBytes: Int64 = 0
    let bufferSize = 1024 * 1024  // 1MB buffer for better performance
    var buffer = Data()
    buffer.reserveCapacity(bufferSize)
    var lastProgressUpdateTime = Date()
    let progressUpdateInterval: TimeInterval = 0.5  // 500ms for less frequent updates

    // Use Data.write(to:) for better performance than FileHandle
    var downloadData = Data()
    downloadData.reserveCapacity(Int(totalBytes > 0 ? totalBytes : 1024 * 1024 * 100))  // Reserve 100MB if size unknown

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
              progress(progressValue, downloadedBytes, totalBytes)
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
        progress(progressValue, downloadedBytes, totalBytes)
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
    let encodedFileName =
      fileName.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
    let urlString = "https://huggingface.co/\(encodedModelId)/resolve/main/\(encodedFileName)"
    guard let url = URL(string: urlString) else {
      throw HuggingFaceError.invalidURL
    }
    var request = URLRequest(url: url)
    request.httpMethod = "HEAD"
    if let token = currentToken(), !token.isEmpty {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
    let (_, response) = try await session.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse,
      httpResponse.statusCode == 200
    else {
      throw HuggingFaceError.networkError
    }
    let totalBytes = httpResponse.expectedContentLength
    return totalBytes > 0 ? totalBytes : 0
  }

  /// Debug function to dump full model JSON for inspection
  public func dumpModelJSON(modelId: String) async throws -> String {
    let encodedModelId = modelId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
    let urlString = "\(baseURL)/models/\(encodedModelId)"

    AppLogger.shared.debug("HuggingFaceAPI", "Request URL: \(urlString)")

    guard let url = URL(string: urlString) else {
      throw HuggingFaceError.invalidURL
    }

    var request = URLRequest(url: url)
    if let token = currentToken(), !token.isEmpty {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }

    let (data, response) = try await session.data(for: request)

    AppLogger.shared.debug("HuggingFaceAPI", "Response size: \(data.count) bytes")

    guard let httpResponse = response as? HTTPURLResponse,
      httpResponse.statusCode == 200
    else {
      throw HuggingFaceError.networkError
    }

    // Pretty print the JSON
    let jsonObject = try JSONSerialization.jsonObject(with: data)
    if let prettyData = try? JSONSerialization.data(
      withJSONObject: jsonObject, options: .prettyPrinted),
      let prettyString = String(data: prettyData, encoding: .utf8)
    {
      return prettyString
    }

    // Fallback to raw data
    return String(data: data, encoding: .utf8) ?? "Unable to decode JSON"
  }

  /// Lists all files in a Hugging Face model repo (main branch) using the siblings field.
  public func listModelFiles(modelId: String) async throws -> [String] {
    let modelInfo = try await getModelInfo(modelId: modelId)
    guard let siblings = modelInfo.siblings else {
      AppLogger.shared.warning(
        "HuggingFaceAPI", "No siblings (file list) found for model: \(modelId)")
      return []
    }
    let fileNames = siblings.map { $0.rfilename }
    AppLogger.shared.info(
      "HuggingFaceAPI", "Model \(modelId) has \(fileNames.count) files: \(fileNames)")
    return fileNames
  }

  // Platform-safe Hugging Face token loader
  public func loadHuggingFaceToken() -> String? { nil }

  /// Validates a Hugging Face token by calling the whoami endpoint.
  /// Returns the username if valid, or nil if invalid.
  public func validateToken(token: String) async throws -> String? {
    guard !token.isEmpty else { return nil }
    let url = URL(string: "https://huggingface.co/api/whoami-v2")!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    do {
      let (data, response) = try await session.data(for: request)
      guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        return nil
      }
      if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let user = json["user"] as? [String: Any],
        let name = user["name"] as? String
      {
        return name
      }
      return "(valid, no username)"
    } catch {
      AppLogger.shared.error("HuggingFaceAPI", "Token validation failed: \(error)")
      return nil
    }
  }

  private func validateTokenViaSearch(token: String) async throws -> Bool {
    var request = URLRequest(
      url: URL(string: "https://huggingface.co/api/models?search=mlx&limit=1")!)
    request.httpMethod = "GET"
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    let (_, response) = try await session.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse else { return false }
    return httpResponse.statusCode == 200
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
  public let private_: Bool?
  public let gated: Bool?
  public let disabled: Bool?
  public let sha: String?
  public let library_name: String?
  public let safetensors: SafetensorsField?
  public let usedStorage: Int?
  public let trendingScore: Int?
  public let cardData: [String: AnyCodable]?
  public let siblings: [Sibling]?
  public let config: [String: AnyCodable]?
  public let transformersInfo: [String: AnyCodable]?
  public let spaces: [String]?
  public let modelIndex: String?
  public let widgetData: WidgetDataField?

  public init(
    id: String,
    modelId: String? = nil,
    author: String? = nil,
    downloads: Int? = nil,
    likes: Int? = nil,
    tags: [String]? = nil,
    pipeline_tag: String? = nil,
    createdAt: String? = nil,
    lastModified: String? = nil,
    private_: Bool? = nil,
    gated: Bool? = nil,
    disabled: Bool? = nil,
    sha: String? = nil,
    library_name: String? = nil,
    safetensors: SafetensorsField? = nil,
    usedStorage: Int? = nil,
    trendingScore: Int? = nil,
    cardData: [String: AnyCodable]? = nil,
    siblings: [Sibling]? = nil,
    config: [String: AnyCodable]? = nil,
    transformersInfo: [String: AnyCodable]? = nil,
    spaces: [String]? = nil,
    modelIndex: String? = nil,
    widgetData: WidgetDataField? = nil
  ) {
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

  // Custom Equatable/Hashable: only use id
  public static func == (lhs: HuggingFaceModel, rhs: HuggingFaceModel) -> Bool {
    lhs.id == rhs.id
  }
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  // Utility: MLX compatibility check
  public func hasMLXFiles() -> Bool {
    if let library = library_name, library.lowercased() == "mlx" { return true }
    if let tags = tags, tags.contains(where: { $0.lowercased() == "mlx" }) { return true }
    if id.lowercased().contains("mlx") { return true }
    if let siblings = siblings {
      for sib in siblings {
        if sib.rfilename.lowercased().contains("mlx") { return true }
      }
    }
    return false
  }

  // Utility: Convert to ModelConfiguration (now with metadata extraction)
  public func toModelConfiguration() -> ModelConfiguration {
    ModelConfiguration(
      name: id,
      hubId: id,
      description: "Model from Hugging Face Hub",
      parameters: self.extractParameters(),
      quantization: self.extractQuantization(),
      architecture: self.extractArchitecture(),
      maxTokens: 4096,
      estimatedSizeGB: nil,
      defaultSystemPrompt: nil,
      endOfTextTokens: nil,
      modelType: .llm,  // Default to LLM, can be refined
      gpuCacheLimit: 512 * 1024 * 1024,
      features: []
    )
  }

  // Utility: Extract quantization
  public func extractQuantization() -> String? {
    let name = id.lowercased()
    if name.contains("4bit") || name.contains("q4") { return "4bit" }
    if name.contains("6bit") || name.contains("q6") { return "6bit" }
    if name.contains("8bit") || name.contains("q8") { return "8bit" }
    if name.contains("fp16") { return "fp16" }
    if name.contains("fp32") { return "fp32" }
    if name.contains("bf16") { return "bf16" }
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

  // Utility: Extract parameters
  public func extractParameters() -> String? {
    let name = id.lowercased()
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

  // Utility: Extract architecture
  public func extractArchitecture() -> String? {
    let name = id.lowercased()
    if name.contains("llama") { return "Llama" }
    if name.contains("qwen") { return "Qwen" }
    if name.contains("mistral") { return "Mistral" }
    if name.contains("phi") { return "Phi" }
    if name.contains("gemma") { return "Gemma" }
    if name.contains("deepseek") { return "DeepSeek" }
    if name.contains("devstral") { return "Devstral" }
    if let tags = tags {
      for tag in tags {
        if tag.lowercased().contains("llama") { return "Llama" }
        if tag.lowercased().contains("qwen") { return "Qwen" }
        if tag.lowercased().contains("mistral") { return "Mistral" }
        if tag.lowercased().contains("phi") { return "Phi" }
        if tag.lowercased().contains("gemma") { return "Gemma" }
        if tag.lowercased().contains("deepseek") { return "DeepSeek" }
        if tag.lowercased().contains("devstral") { return "Devstral" }
      }
    }
    return nil
  }
}

public struct Sibling: Codable {
  public let rfilename: String
  public let size: Int?
  public init(rfilename: String, size: Int?) {
    self.rfilename = rfilename
    self.size = size
  }
}

public struct AnyCodable: Codable, @unchecked Sendable {
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
      throw DecodingError.dataCorruptedError(
        in: container, debugDescription: "AnyCodable value cannot be decoded")
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
      let context = EncodingError.Context(
        codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded")
      throw EncodingError.invalidValue(self.value, context)
    }
  }
}

public enum HuggingFaceError: Error, LocalizedError {
  case invalidURL
  case networkError
  case decodingError
  case fileError
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
    }
  }
}

public enum SafetensorsField: Codable, Sendable {
  case bool(Bool)
  case object([String: AnyCodable])
  case unknown
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let b = try? container.decode(Bool.self) {
      self = .bool(b)
    } else if let obj = try? container.decode([String: AnyCodable].self) {
      self = .object(obj)
    } else {
      self = .unknown
    }
  }
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .bool(let b): try container.encode(b)
    case .object(let obj): try container.encode(obj)
    case .unknown: try container.encodeNil()
    }
  }
}

public enum WidgetDataField: Codable {
  case dict([String: AnyCodable])
  case array([AnyCodable])
  case unknown
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if let dict = try? container.decode([String: AnyCodable].self) {
      self = .dict(dict)
    } else if let arr = try? container.decode([AnyCodable].self) {
      self = .array(arr)
    } else {
      self = .unknown
    }
  }
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch self {
    case .dict(let dict): try container.encode(dict)
    case .array(let arr): try container.encode(arr)
    case .unknown: try container.encodeNil()
    }
  }
}

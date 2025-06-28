import Foundation

/// Service for discovering MLX-compatible models from Hugging Face.
public struct ModelDiscoveryService {
  public struct ModelSummary: Sendable, Identifiable {
    public let id: String
    public let name: String
    public let author: String?
    public let downloads: Int
    public let likes: Int
    public let quantization: String?
    public let parameters: String?
    public let architecture: String?
    public let description: String
    public let isMLX: Bool
    public let pipelineTag: String?
    public let safetensors: SafetensorsField?
    public let tags: [String]?
    public let createdAt: String?
    public let lastModified: String?
    public let imageURL: URL?
  }

  private static func extractImageURL(from cardData: [String: AnyCodable]?) -> URL? {
    guard let cardData = cardData else { return nil }
    if let urlString = cardData["thumbnail"]?.value as? String, let url = URL(string: urlString) {
      return url
    }
    if let urlString = cardData["image"]?.value as? String, let url = URL(string: urlString) {
      return url
    }
    return nil
  }

  /// Searches Hugging Face for MLX-compatible models, sorted by popularity.
  /// - Parameters:
  ///   - query: Search string (e.g. "Qwen", "Llama", "mlx").
  ///   - limit: Max number of results to return.
  /// - Returns: Array of ModelSummary, sorted by downloads and likes.
  public static func searchMLXModels(query: String, limit: Int = 20) async throws -> [ModelSummary]
  {
    let api = HuggingFaceAPI.shared
    let models = try await api.searchModels(query: query, limit: limit)
    let filtered = models.filter { $0.hasMLXFiles() }
    let sorted = filtered.sorted {
      let d1 = $0.downloads ?? 0
      let d2 = $1.downloads ?? 0
      if d1 != d2 { return d1 > d2 }
      let l1 = $0.likes ?? 0
      let l2 = $1.likes ?? 0
      return l1 > l2
    }
    return sorted.map { m in
      ModelSummary(
        id: m.id,
        name: m.id.components(separatedBy: "/").last ?? m.id,
        author: m.author,
        downloads: m.downloads ?? 0,
        likes: m.likes ?? 0,
        quantization: m.extractQuantization(),
        parameters: m.extractParameters(),
        architecture: m.extractArchitecture(),
        description: m.pipeline_tag ?? "MLX-compatible model",
        isMLX: m.hasMLXFiles(),
        pipelineTag: m.pipeline_tag,
        safetensors: m.safetensors,
        tags: m.tags,
        createdAt: m.createdAt,
        lastModified: m.lastModified,
        imageURL: extractImageURL(from: m.cardData)
      )
    }
  }

  /// Searches Hugging Face for MLX-compatible models that are also compatible with the given device (by RAM and platform).
  public static func searchCompatibleMLXModels(
    query: String, ramGB: Double, platform: String, limit: Int = 20
  ) async throws -> [ModelSummary] {
    let api = HuggingFaceAPI.shared
    let models = try await api.searchModels(query: query, limit: limit)
    let filtered = models.filter { $0.hasMLXFiles() }
    let compatible = filtered.filter { m in
      let config = m.toModelConfiguration()
      return ModelRegistry.isModelSupported(config, ramGB: ramGB, platform: platform)
    }
    let sorted = compatible.sorted {
      let d1 = $0.downloads ?? 0
      let d2 = $1.downloads ?? 0
      if d1 != d2 { return d1 > d2 }
      let l1 = $0.likes ?? 0
      let l2 = $1.likes ?? 0
      return l1 > l2
    }
    return sorted.map { m in
      ModelSummary(
        id: m.id,
        name: m.id.components(separatedBy: "/").last ?? m.id,
        author: m.author,
        downloads: m.downloads ?? 0,
        likes: m.likes ?? 0,
        quantization: m.extractQuantization(),
        parameters: m.extractParameters(),
        architecture: m.extractArchitecture(),
        description: m.pipeline_tag ?? "MLX-compatible model",
        isMLX: m.hasMLXFiles(),
        pipelineTag: m.pipeline_tag,
        safetensors: m.safetensors,
        tags: m.tags,
        createdAt: m.createdAt,
        lastModified: m.lastModified,
        imageURL: extractImageURL(from: m.cardData)
      )
    }
  }

  /// Returns the top recommended MLX-compatible models for the current device from Hugging Face
  public static func recommendedMLXModelsForCurrentDevice(limit: Int = 3) async throws
    -> [ModelSummary]
  {
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
    let all = try await searchCompatibleMLXModels(
      query: "mlx", ramGB: memoryGB, platform: platform, limit: 50)
    return Array(all.prefix(limit))
  }
}

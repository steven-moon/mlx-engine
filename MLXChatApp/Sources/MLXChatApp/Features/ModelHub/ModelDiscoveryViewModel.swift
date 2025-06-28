import SwiftUI
import MLXEngine

/// ViewModel for managing model discovery and downloads
@MainActor
class ModelDiscoveryViewModel: ObservableObject {
    @Published var models: [HuggingFaceModel] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var downloadingModels: Set<String> = []
    @Published var downloadProgress: [String: Double] = [:]
    @Published var hasMoreResults = false
    @Published var hasValidToken = false
    
    private let huggingFaceAPI = HuggingFaceAPI.shared
    private let modelManager = ModelDiscoveryManager.shared
    private var currentPage = 0
    private let pageSize = 20
    private var currentSearchQuery = ""
    private var currentFilter: ModelFilter = .all
    
    init() {
        checkTokenValidity()
    }
    
    /// Search for models with the given query and filter
    func searchModels(query: String, filter: ModelFilter) async {
        currentSearchQuery = query
        currentFilter = filter
        currentPage = 0
        isLoading = true
        
        do {
            let searchQuery = buildSearchQuery(query: query, filter: filter)
            let newModels = try await huggingFaceAPI.searchModels(
                query: searchQuery,
                limit: pageSize
            )
            
            // Filter for MLX-compatible models if needed
            let filteredModels = filter == .mlx ? newModels.filter { $0.hasMLXFiles() } : newModels
            
            models = filteredModels
            hasMoreResults = filteredModels.count >= pageSize
            isLoading = false
            
        } catch {
            print("Error searching models: \(error)")
            models = []
            hasMoreResults = false
            isLoading = false
        }
    }
    
    /// Load more results for pagination
    func loadMoreResults() async {
        guard !isLoadingMore && hasMoreResults else { return }
        
        isLoadingMore = true
        currentPage += 1
        
        do {
            let searchQuery = buildSearchQuery(query: currentSearchQuery, filter: currentFilter)
            let offset = currentPage * pageSize
            let moreModels = try await huggingFaceAPI.searchModels(
                query: searchQuery,
                limit: pageSize
            )
            
            // Filter for MLX-compatible models if needed
            let filteredModels = currentFilter == .mlx ? moreModels.filter { $0.hasMLXFiles() } : moreModels
            
            models.append(contentsOf: filteredModels)
            hasMoreResults = filteredModels.count >= pageSize
            isLoadingMore = false
            
        } catch {
            print("Error loading more models: \(error)")
            isLoadingMore = false
        }
    }
    
    /// Download a model
    func downloadModel(_ model: HuggingFaceModel) async {
        guard !downloadingModels.contains(model.id) else { return }
        
        downloadingModels.insert(model.id)
        downloadProgress[model.id] = 0
        
        do {
            let config = model.toModelConfiguration()
            let modelURL = try await modelManager.downloadModel(config) { progress in
                Task { @MainActor in
                    self.downloadProgress[model.id] = progress
                }
            }
            
            // Download completed successfully
            downloadingModels.remove(model.id)
            downloadProgress.removeValue(forKey: model.id)
            
            print("Model downloaded successfully: \(model.id) to \(modelURL)")
            
        } catch {
            print("Error downloading model \(model.id): \(error)")
            downloadingModels.remove(model.id)
            downloadProgress.removeValue(forKey: model.id)
        }
    }
    
    /// Check if HuggingFace token is valid
    private func checkTokenValidity() {
        Task {
            if let token = UserDefaults.standard.string(forKey: "huggingFaceToken"),
               !token.isEmpty {
                do {
                    let username = try await huggingFaceAPI.validateToken(token: token)
                    hasValidToken = username != nil
                } catch {
                    hasValidToken = false
                }
            } else {
                hasValidToken = false
            }
        }
    }
    
    /// Build search query combining user input and filter
    private func buildSearchQuery(query: String, filter: ModelFilter) -> String {
        var searchTerms: [String] = []
        
        // Add user query
        if !query.isEmpty {
            searchTerms.append(query)
        }
        
        // Add filter query
        if !filter.searchQuery.isEmpty {
            searchTerms.append(filter.searchQuery)
        }
        
        // Always prioritize MLX models
        if filter != .mlx {
            searchTerms.append("mlx")
        }
        
        return searchTerms.joined(separator: " ")
    }
}

/// Model Manager for handling model downloads
class ModelDiscoveryManager: ObservableObject {
    static let shared = ModelDiscoveryManager()
    private let downloader = OptimizedDownloader()
    
    private init() {}
    
    func downloadModel(_ config: ModelConfiguration, progress: @escaping @Sendable (Double) -> Void) async throws -> URL {
        return try await downloader.downloadModel(config, progress: progress)
    }
} 
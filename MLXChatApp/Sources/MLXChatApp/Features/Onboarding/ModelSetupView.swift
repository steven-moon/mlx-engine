import SwiftUI
import MLXEngine

// Placeholder for ModelManager
class ModelManager: ObservableObject {
    static let shared = ModelManager()
    private let downloader = OptimizedDownloader()

    func downloadModel(_ config: ModelConfiguration, progressHandler: @escaping @Sendable (Double) -> Void) async throws -> URL {
        return try await downloader.downloadModel(config, progress: progressHandler)
    }
}

// Model structs from the guide
struct RecommendedModel {
    let hubId: String
    let name: String
    let description: String
    let size: String
    let category: ModelCategory
    let tags: [String]
    
    enum ModelCategory {
        case mobile, balanced, creative
        
        var color: Color {
            switch self {
            case .mobile: return .green
            case .balanced: return .blue
            case .creative: return .purple
            }
        }
        
        var icon: String {
            switch self {
            case .mobile: return "iphone"
            case .balanced: return "scale.3d"
            case .creative: return "paintbrush.fill"
            }
        }
    }
}

struct Model {
    let hubId: String
    let name: String
    let size: String
    
    init(from recommended: RecommendedModel) {
        self.hubId = recommended.hubId
        self.name = recommended.name
        self.size = recommended.size
    }
}


struct ModelSetupView: View {
    @StateObject private var modelManager = ModelManager.shared
    @State private var selectedModel: Model?
    @State private var downloadProgress: Double = 0
    @State private var isDownloading = false
    @State private var downloadCompleted = false
    
    let onContinue: () -> Void
    
    private let recommendedModels = [
        RecommendedModel(
            hubId: "mlx-community/Llama-3.2-3B-Instruct-4bit",
            name: "Llama 3.2 3B",
            description: "Perfect for mobile devices - fast and efficient",
            size: "2.1 GB",
            category: .mobile,
            tags: ["Recommended", "Fast"]
        ),
        RecommendedModel(
            hubId: "mlx-community/Qwen2.5-7B-Instruct-4bit",
            name: "Qwen 2.5 7B",
            description: "Excellent balance of performance and speed",
            size: "4.3 GB",
            category: .balanced,
            tags: ["Popular", "Versatile"]
        ),
        RecommendedModel(
            hubId: "mlx-community/Mistral-7B-Instruct-v0.3-4bit",
            name: "Mistral 7B",
            description: "Great for creative writing and analysis",
            size: "4.1 GB",
            category: .creative,
            tags: ["Creative", "Analysis"]
        )
    ]
    
    var body: some View {
        VStack(spacing: 24) {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(recommendedModels, id: \.hubId) { model in
                        ModelSelectionCard(
                            model: model,
                            isSelected: selectedModel?.hubId == model.hubId,
                            onSelect: { selectedModel = Model(from: model) }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            Spacer()
            
            if let model = selectedModel {
                DownloadSection(
                    model: model,
                    isDownloading: isDownloading,
                    downloadProgress: downloadProgress,
                    downloadCompleted: downloadCompleted,
                    onDownload: { downloadModel(model) },
                    onContinue: onContinue
                )
            }
        }
        .padding()
    }
    
    private func downloadModel(_ model: Model) {
        isDownloading = true
        downloadProgress = 0
        
        Task {
            do {
                // This is a simplified ModelConfiguration. The real one from MLXEngine is more detailed.
                let config = ModelConfiguration(
                    name: model.name,
                    hubId: model.hubId,
                    description: "",
                    parameters: model.size,
                    quantization: "4bit",
                    maxTokens: 2048
                )
                
                _ = try await modelManager.downloadModel(config) { progress in
                    Task { @MainActor in
                        downloadProgress = progress
                    }
                }
                
                await MainActor.run {
                    downloadCompleted = true
                    isDownloading = false
                }
                
                // Wait a moment then continue
                try await Task.sleep(nanoseconds: 1_000_000_000)
                onContinue()
                
            } catch {
                await MainActor.run {
                    isDownloading = false
                    // Handle error
                }
            }
        }
    }
}

struct ModelSelectionCard: View {
    let model: RecommendedModel
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(model.name).font(.headline)
                    Text(model.description).font(.subheadline).foregroundColor(.secondary)
                    HStack {
                        ForEach(model.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(model.category.color.opacity(0.2))
                                .foregroundColor(model.category.color)
                                .clipShape(Capsule())
                        }
                    }
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

struct DownloadSection: View {
    let model: Model
    let isDownloading: Bool
    let downloadProgress: Double
    let downloadCompleted: Bool
    let onDownload: () -> Void
    let onContinue: () -> Void
    
    var body: some View {
        VStack {
            if isDownloading {
                ProgressView(value: downloadProgress) {
                    Text("Downloading \(model.name)... \(Int(downloadProgress * 100))%")
                }
            } else if downloadCompleted {
                HStack {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                    Text("\(model.name) Downloaded")
                }
                Button("Continue", action: onContinue)
                    .buttonStyle(.borderedProminent)

            } else {
                Button("Download \(model.name) (\(model.size))", action: onDownload)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
} 
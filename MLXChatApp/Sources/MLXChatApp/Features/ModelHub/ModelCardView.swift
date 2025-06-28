import SwiftUI
import MLXEngine

/// Card view for displaying a HuggingFace model with download functionality
struct ModelCardView: View {
    let model: HuggingFaceModel
    let isDownloading: Bool
    let downloadProgress: Double
    let onDownload: () -> Void
    
    @State private var showingDetails = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with model name and author
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(model.id.components(separatedBy: "/").last ?? model.id)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    // MLX indicator
                    if model.hasMLXFiles() {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
                
                if let author = model.author {
                    Text("by \(author)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Model metadata
            HStack(spacing: 16) {
                // Parameters
                if let parameters = model.extractParameters() {
                    ModelMetadataItem(
                        icon: "cpu",
                        text: parameters,
                        color: .blue
                    )
                }
                
                // Quantization
                if let quantization = model.extractQuantization() {
                    ModelMetadataItem(
                        icon: "memorychip",
                        text: quantization,
                        color: .purple
                    )
                }
                
                // Downloads
                if let downloads = model.downloads {
                    ModelMetadataItem(
                        icon: "arrow.down.circle",
                        text: formatDownloads(downloads),
                        color: .green
                    )
                }
                
                Spacer()
            }
            
            // Tags
            if let tags = model.tags, !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(tags.prefix(5), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.1))
                                .foregroundColor(.accentColor)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            
            // Action buttons
            HStack {
                Button("Details") {
                    showingDetails = true
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                if isDownloading {
                    VStack(spacing: 4) {
                        ProgressView(value: downloadProgress)
                            .progressViewStyle(.linear)
                            .frame(width: 100)
                        Text("\(Int(downloadProgress * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Button("Download") {
                        onDownload()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!model.hasMLXFiles())
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .sheet(isPresented: $showingDetails) {
            ModelDetailView(model: model)
        }
    }
    
    private func formatDownloads(_ downloads: Int) -> String {
        if downloads >= 1_000_000 {
            return String(format: "%.1fM", Double(downloads) / 1_000_000)
        } else if downloads >= 1_000 {
            return String(format: "%.1fK", Double(downloads) / 1_000)
        } else {
            return "\(downloads)"
        }
    }
}

/// Individual metadata item component
struct ModelMetadataItem: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

/// Detailed model information view
struct ModelDetailView: View {
    let model: HuggingFaceModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(model.id)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let author = model.author {
                            Text("Author: \(author)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if model.hasMLXFiles() {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(.green)
                                Text("MLX Compatible")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                        }
                    }
                    
                    // Model specifications
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Specifications")
                            .font(.headline)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            DetailItem(title: "Parameters", value: model.extractParameters() ?? "Unknown")
                            DetailItem(title: "Quantization", value: model.extractQuantization() ?? "Unknown")
                            DetailItem(title: "Architecture", value: model.extractArchitecture() ?? "Unknown")
                            DetailItem(title: "Downloads", value: formatDownloads(model.downloads))
                            DetailItem(title: "Likes", value: formatNumber(model.likes))
                            DetailItem(title: "Created", value: formatDate(model.createdAt))
                        }
                    }
                    
                    // Tags
                    if let tags = model.tags, !tags.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tags")
                                .font(.headline)
                            
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 80))
                            ], spacing: 8) {
                                ForEach(tags, id: \.self) { tag in
                                    Text(tag)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.accentColor.opacity(0.1))
                                        .foregroundColor(.accentColor)
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }
                    
                    // Files (if available)
                    if let siblings = model.siblings, !siblings.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Files")
                                .font(.headline)
                            
                            ForEach(siblings.prefix(10), id: \.rfilename) { sibling in
                                HStack {
                                    Text(sibling.rfilename)
                                        .font(.caption)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    if let size = sibling.size {
                                        Text(formatFileSize(size))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                            
                            if siblings.count > 10 {
                                Text("... and \(siblings.count - 10) more files")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Model Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatDownloads(_ downloads: Int?) -> String {
        guard let downloads = downloads else { return "Unknown" }
        if downloads >= 1_000_000 {
            return String(format: "%.1fM", Double(downloads) / 1_000_000)
        } else if downloads >= 1_000 {
            return String(format: "%.1fK", Double(downloads) / 1_000)
        } else {
            return "\(downloads)"
        }
    }
    
    private func formatNumber(_ number: Int?) -> String {
        guard let number = number else { return "Unknown" }
        if number >= 1_000_000 {
            return String(format: "%.1fM", Double(number) / 1_000_000)
        } else if number >= 1_000 {
            return String(format: "%.1fK", Double(number) / 1_000)
        } else {
            return "\(number)"
        }
    }
    
    private func formatDate(_ dateString: String?) -> String {
        guard let dateString = dateString else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS'Z'"
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            return displayFormatter.string(from: date)
        }
        
        return dateString
    }
    
    private func formatFileSize(_ size: Int) -> String {
        if size >= 1_000_000_000 {
            return String(format: "%.1f GB", Double(size) / 1_000_000_000)
        } else if size >= 1_000_000 {
            return String(format: "%.1f MB", Double(size) / 1_000_000)
        } else if size >= 1_000 {
            return String(format: "%.1f KB", Double(size) / 1_000)
        } else {
            return "\(size) B"
        }
    }
}

/// Detail item component for the detail view
struct DetailItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

#Preview {
    let sampleModel = HuggingFaceModel(
        id: "mlx-community/Llama-3.2-3B-Instruct-4bit",
        author: "mlx-community",
        downloads: 15000,
        likes: 500,
        tags: ["mlx", "llama", "instruct", "4bit"],
        siblings: [
            Sibling(rfilename: "model.safetensors", size: 2_100_000_000),
            Sibling(rfilename: "tokenizer.json", size: 500_000)
        ]
    )
    
    ModelCardView(
        model: sampleModel,
        isDownloading: false,
        downloadProgress: 0,
        onDownload: {}
    )
    .padding()
} 
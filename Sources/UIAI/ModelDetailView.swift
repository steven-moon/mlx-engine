//
//  ModelDetailView.swift
//  UIAI
//
//  Created for MLXEngine Shared SwiftUI Library
//
//  A cross-platform SwiftUI view for displaying and managing model metadata and actions.
//  This is a stub for future expansion and integration with MLXEngine APIs.
//

import SwiftUI
import MLXEngine

/// A SwiftUI view for displaying and managing model metadata and actions.
///
/// - Designed for iOS, macOS, visionOS, tvOS, and watchOS.
/// - Integrates with MLXEngine model metadata and management APIs.
public struct ModelDetailView: View {
    public let model: ModelDiscoveryService.ModelSummary
    public let isDownloaded: Bool
    public let isDownloading: Bool
    public let downloadProgress: Double?
    public let onDownload: (() -> Void)?
    public let onDelete: (() -> Void)?
    public let onOpenInBrowser: (() -> Void)?
    
    @State private var errorMessage: String? = nil
    @State private var showError: Bool = false
    @State private var isCopied: Bool = false
    @State private var fileList: [String] = []
    @State private var isLoadingFiles: Bool = false
    @State private var fileListError: String? = nil
    @State private var isCompatible: Bool = false
    
    public init(
        model: ModelDiscoveryService.ModelSummary,
        isDownloaded: Bool = false,
        isDownloading: Bool = false,
        downloadProgress: Double? = nil,
        onDownload: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil,
        onOpenInBrowser: (() -> Void)? = nil
    ) {
        self.model = model
        self.isDownloaded = isDownloaded
        self.isDownloading = isDownloading
        self.downloadProgress = downloadProgress
        self.onDownload = onDownload
        self.onDelete = onDelete
        self.onOpenInBrowser = onOpenInBrowser
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let errorMessage = errorMessage, showError {
                    ErrorBanner(message: errorMessage, style: .error, isPresented: $showError)
                }
                // Compatibility badge
                HStack(spacing: 8) {
                    Image(systemName: isCompatible ? "checkmark.shield.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(isCompatible ? .green : .yellow)
                    Text(isCompatible ? "Compatible with your device" : "May not fit in RAM")
                        .font(.caption)
                        .foregroundColor(isCompatible ? .green : .yellow)
                    Spacer()
                }
                .padding(8)
                .background((isCompatible ? Color.green : Color.yellow).opacity(0.08))
                .cornerRadius(8)
                let health = modelHealthStatus()
                HStack(spacing: 8) {
                    Image(systemName: health.icon)
                        .foregroundColor(health.color)
                    Text(health.message)
                        .font(.caption)
                        .foregroundColor(health.color)
                    Spacer()
                    Button(action: copyMetadata) {
                        Label(isCopied ? "Copied!" : "Copy Metadata", systemImage: isCopied ? "checkmark.circle" : "doc.on.doc")
                    }
                    .font(.caption2)
                    .foregroundColor(.accentColor)
                }
                .padding(8)
                .background(health.color.opacity(0.08))
                .cornerRadius(8)
                HStack(alignment: .top, spacing: 16) {
                    AsyncImageView(url: model.imageURL)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    VStack(alignment: .leading, spacing: 6) {
                        Text(model.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        if let author = model.author {
                            Text("by \(author)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        HStack(spacing: 12) {
                            if model.downloads > 0 {
                                Label("\(model.downloads)", systemImage: "arrow.down.circle")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            if model.likes > 0 {
                                Label("\(model.likes)", systemImage: "heart.fill")
                                    .font(.caption)
                                    .foregroundColor(.pink)
                            }
                        }
                    }
                }
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    if let params = model.parameters {
                        HStack {
                            Text("Parameters:")
                                .fontWeight(.semibold)
                            Text(params)
                        }
                    }
                    if let quant = model.quantization {
                        HStack {
                            Text("Quantization:")
                                .fontWeight(.semibold)
                            Text(quant)
                        }
                    }
                    if let arch = model.architecture {
                        HStack {
                            Text("Architecture:")
                                .fontWeight(.semibold)
                            Text(arch)
                        }
                    }
                    if let tags = model.tags, !tags.isEmpty {
                        HStack(alignment: .top) {
                            Text("Tags:")
                                .fontWeight(.semibold)
                            Text(tags.joined(separator: ", "))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    if let created = model.createdAt {
                        HStack {
                            Text("Created:")
                                .fontWeight(.semibold)
                            Text(created)
                        }
                    }
                    if let modified = model.lastModified {
                        HStack {
                            Text("Last Modified:")
                                .fontWeight(.semibold)
                            Text(modified)
                        }
                    }
                }
                Divider()
                // File list section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Model Files")
                        .font(.headline)
                    if isLoadingFiles {
                        ProgressView("Loading files...")
                    } else if let fileListError = fileListError {
                        Text("Error: \(fileListError)").foregroundColor(.red)
                    } else if fileList.isEmpty {
                        Text("No files found.").foregroundColor(.secondary)
                    } else {
                        ForEach(fileList, id: \.self) { file in
                            Text(file).font(.caption).foregroundColor(.primary)
                        }
                    }
                }
                Divider()
                Text(model.description)
                    .font(.body)
                Divider()
                if isDownloading, let progress = downloadProgress {
                    TokenProgressBar(progress: progress, label: "Downloading")
                        .frame(height: 16)
                }
                HStack(spacing: 16) {
                    if !isDownloaded {
                        Button(action: { onDownload?() }) {
                            Label("Download", systemImage: "arrow.down.circle")
                        }
                    }
                    if isDownloaded {
                        Button(action: { onDelete?() }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    Button(action: { onOpenInBrowser?() }) {
                        Label("Open in Browser", systemImage: "safari")
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .onAppear {
                loadFileList()
                checkCompatibility()
            }
        }
    }
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
    
    private func modelHealthStatus() -> (icon: String, color: Color, message: String) {
        if isDownloaded {
            return ("checkmark.seal.fill", .green, "Model downloaded and ready.")
        } else if !model.isMLX {
            return ("xmark.octagon.fill", .red, "Not MLX-compatible.")
        } else {
            return ("exclamationmark.triangle.fill", .yellow, "Model not downloaded.")
        }
    }
    
    private func copyMetadata() {
        let meta = """
        Name: \(model.name)
        ID: \(model.id)
        Description: \(model.description)
        Parameters: \(model.parameters ?? "-")
        Quantization: \(model.quantization ?? "-")
        Architecture: \(model.architecture ?? "-")
        Tags: \(model.tags?.joined(separator: ", ") ?? "-")
        Created: \(model.createdAt ?? "-")
        Last Modified: \(model.lastModified ?? "-")
        """
        #if os(iOS)
        UIPasteboard.general.string = meta
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(meta, forType: .string)
        #endif
        isCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { isCopied = false }
    }
    
    private func loadFileList() {
        isLoadingFiles = true
        fileListError = nil
        fileList = []
        Task {
            do {
                let files = try await HuggingFaceAPI.shared.listModelFiles(modelId: model.id)
                await MainActor.run {
                    fileList = files
                    isLoadingFiles = false
                }
            } catch {
                await MainActor.run {
                    fileListError = error.localizedDescription
                    isLoadingFiles = false
                }
            }
        }
    }
    
    private func checkCompatibility() {
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
        let config = ModelConfiguration(
            name: model.name,
            hubId: model.id,
            description: model.description,
            parameters: model.parameters,
            quantization: model.quantization,
            architecture: model.architecture
        )
        isCompatible = ModelRegistry.isModelSupported(config, ramGB: memoryGB, platform: platform)
    }
} 
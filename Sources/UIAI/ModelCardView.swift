//
//  ModelCardView.swift
//  UIAI
//
//  Created for MLXEngine Shared SwiftUI Library
//
//  A SwiftUI view for displaying a model card with metadata, download status, and actions.
//

import SwiftUI

/// A SwiftUI view for displaying a model card with metadata, image, and actions.
///
/// - Used in ModelDiscoveryView for Hugging Face and local models.
/// - Shows model name, description, parameters, quantization, and status.
/// - Includes actions for download, update, and delete.
public struct ModelCardView: View {
    public struct ModelInfo: Identifiable {
        public let id: String
        public let name: String
        public let description: String
        public let parameters: String?
        public let quantization: String?
        public let imageURL: URL?
        public let isDownloaded: Bool
        public let isDownloading: Bool
        public let downloadProgress: Double?
        public let statusMessage: String?
        public let statusColor: Color?
        public let architecture: String?
        public init(id: String, name: String, description: String, parameters: String? = nil, quantization: String? = nil, imageURL: URL? = nil, isDownloaded: Bool = false, isDownloading: Bool = false, downloadProgress: Double? = nil, statusMessage: String? = nil, statusColor: Color? = nil, architecture: String? = nil) {
            self.id = id
            self.name = name
            self.description = description
            self.parameters = parameters
            self.quantization = quantization
            self.imageURL = imageURL
            self.isDownloaded = isDownloaded
            self.isDownloading = isDownloading
            self.downloadProgress = downloadProgress
            self.statusMessage = statusMessage
            self.statusColor = statusColor
            self.architecture = architecture
        }
    }
    public let model: ModelInfo
    public let onDownload: (() -> Void)?
    public let onDelete: (() -> Void)?
    public let onShowDetails: (() -> Void)?
    
    @State private var errorMessage: String? = nil
    @State private var showError: Bool = false
    @Environment(\.uiaiStyle) private var uiaiStyle: any UIAIStyle
    
    public init(model: ModelInfo, onDownload: (() -> Void)? = nil, onDelete: (() -> Void)? = nil, onShowDetails: (() -> Void)? = nil) {
        self.model = model
        self.onDownload = onDownload
        self.onDelete = onDelete
        self.onShowDetails = onShowDetails
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Branding Logo
            HStack {
                Spacer()
                if let logo = uiaiStyle.logo {
                    logo
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                        .padding(.top, 8)
                } else {
                    Image(systemName: "cube.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundColor(uiaiStyle.accentColor)
                        .padding(.top, 8)
                }
                Spacer()
            }
            if let errorMessage = errorMessage, showError {
                ErrorBanner(message: errorMessage, style: .error, isPresented: $showError)
            }
            if let statusMessage = model.statusMessage, let statusColor = model.statusColor {
                HStack(spacing: 8) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 10, height: 10)
                    Text(statusMessage)
                        .font(.caption2)
                        .foregroundColor(statusColor)
                    Spacer()
                }
                .padding(.bottom, 2)
            }
            HStack(alignment: .top, spacing: 16) {
                AsyncImageView(url: model.imageURL)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(model.name)
                            .font(uiaiStyle.font.weight(.bold))
                            .foregroundColor(uiaiStyle.foregroundColor)
                        if model.isDownloaded {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(uiaiStyle.successColor)
                        }
                    }
                    HStack(spacing: 6) {
                        if let type = modelType(for: model.architecture) {
                            badge(for: type)
                        }
                        if let quant = model.quantization {
                            quantBadge(for: quant)
                        }
                    }
                    Text(model.description)
                        .font(.subheadline)
                        .foregroundColor(uiaiStyle.secondaryForegroundColor)
                        .lineLimit(2)
                    HStack(spacing: 8) {
                        if let params = model.parameters {
                            Text(params)
                                .font(.caption)
                                .foregroundColor(uiaiStyle.infoColor)
                        }
                        if let quant = model.quantization {
                            Text(quant)
                                .font(.caption)
                                .foregroundColor(uiaiStyle.quantizationColor(for: quant))
                        }
                    }
                    if model.isDownloading, let progress = model.downloadProgress {
                        TokenProgressBar(progress: progress, label: "Downloading")
                            .frame(height: 12)
                    }
                    if !model.isDownloaded {
                        Button(action: { handleAction(onDownload) }) {
                            Label("Download", systemImage: "arrow.down.circle")
                        }
                    }
                    if model.isDownloaded {
                        Button(action: { handleAction(onDelete) }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    Button(action: { handleAction(onShowDetails) }) {
                        Label("Details", systemImage: "info.circle")
                    }
                }
                .buttonStyle(.bordered)
                .font(.caption)
            }
            Spacer()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: uiaiStyle.cornerRadius).fill(uiaiStyle.backgroundColor))
        .overlay(
            RoundedRectangle(cornerRadius: uiaiStyle.cornerRadius)
                .stroke(uiaiStyle.accentColor.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func handleAction(_ action: (() -> Void)?) {
        do {
            action?()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func modelType(for architecture: String?) -> String? {
        guard let arch = architecture?.lowercased() else { return nil }
        if arch.contains("llava") { return "VLM" }
        if arch.contains("bge") { return "Embedding" }
        if arch.contains("diffusion") || arch.contains("stablediffusion") { return "Diffusion" }
        if arch.contains("llama") || arch.contains("qwen") || arch.contains("mistral") || arch.contains("phi") || arch.contains("gemma") { return "LLM" }
        return nil
    }
    
    private func badge(for type: String) -> some View {
        Capsule()
            .fill(uiaiStyle.badgeColor(for: type))
            .frame(height: 22)
            .overlay(
                Text(type)
                    .font(.caption2)
                    .foregroundColor(uiaiStyle.backgroundColor)
                    .padding(.horizontal, 8)
            )
            .help(badgeHelpText(for: type))
    }
    
    private func quantBadge(for quant: String) -> some View {
        Capsule()
            .fill(uiaiStyle.quantizationColor(for: quant))
            .frame(height: 22)
            .overlay(
                Text(quant)
                    .font(.caption2)
                    .foregroundColor(uiaiStyle.backgroundColor)
                    .padding(.horizontal, 8)
            )
            .help(badgeHelpText(for: quant))
    }
    
    private func badgeHelpText(for badge: String) -> String {
        switch badge.lowercased() {
        case "llm": return "Large Language Model"
        case "vlm": return "Vision Language Model"
        case "embedding": return "Embedding Model (for text similarity/search)"
        case "diffusion": return "Diffusion Model (for image generation)"
        case "4bit": return "4-bit quantization: smaller, faster, less memory"
        case "8bit": return "8-bit quantization: balance of speed and quality"
        case "fp16": return "16-bit floating point: high quality, moderate size"
        case "fp32": return "32-bit floating point: highest quality, largest size"
        default: return badge.capitalized
        }
    }
}

#if DEBUG
#Preview {
    ModelCardView(
        model: .init(
            id: "qwen-0.5b",
            name: "Qwen 0.5B Chat",
            description: "Small, fast chat model for testing and quick responses.",
            parameters: "0.5B",
            quantization: "4bit",
            imageURL: nil,
            isDownloaded: false,
            isDownloading: true,
            downloadProgress: 0.42
        ),
        onDownload: {},
        onDelete: {},
        onShowDetails: {}
    )
    .padding()
    .previewLayout(.sizeThatFits)
}
#endif 
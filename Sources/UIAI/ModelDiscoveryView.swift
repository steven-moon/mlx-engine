//
//  ModelDiscoveryView.swift
//  UIAI
//
//  Created for MLXEngine Shared SwiftUI Library
//
//  A cross-platform SwiftUI view for discovering, searching, and managing AI models (Hugging Face, local, etc.).
//  This is a stub for future expansion and integration with MLXEngine APIs.
//

import SwiftUI
import MLXEngine
import Foundation

/// A SwiftUI view for discovering and managing AI models.
///
/// - Supports search, filtering, and model actions.
/// - Designed for iOS, macOS, visionOS, tvOS, and watchOS.
/// - Integrates with MLXEngine model discovery APIs.
public struct ModelDiscoveryView: View {
    @AppStorage("huggingFaceToken") private var huggingFaceToken: String = ""
    @State private var tokenInput: String = ""
    @State private var isTokenValid: Bool? = nil
    @State private var isValidatingToken = false
    @State private var tokenError: String? = nil
    @State private var models: [ModelDiscoveryService.ModelSummary] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var query: String = "mlx"
    @State private var downloadingModelId: String?
    @State private var downloadProgress: [String: Double] = [:]
    @State private var downloadedModelIds: Set<String> = []
    @State private var showingDetailsId: String?
    @State private var showDetailSheet: Bool = false
    @State private var detailModel: ModelDiscoveryService.ModelSummary?
    @State private var recommendedModels: [ModelDiscoveryService.ModelSummary] = []
    @State private var errorMessage: String? = nil
    @State private var showError: Bool = false
    @State private var selectedType: String = "All"
    @State private var selectedQuant: String = "All"
    @State private var selectedSort: String = "Most Downloads"
    @State private var huggingFaceUsername: String? = nil
    @State private var showOnlyCompatible: Bool = false
    @Environment(\.uiaiStyle) private var uiaiStyle: any UIAIStyle
    private let typeOptions = ["All", "LLM", "VLM", "Embedding", "Diffusion"]
    private let quantOptions = ["All", "4bit", "8bit", "fp16", "fp32"]
    private let sortOptions = ["Most Downloads", "Most Likes", "Model Size", "Name (A-Z)"]
    public var onModelSelected: ((ModelDiscoveryService.ModelSummary) -> Void)? = nil

    public init() {
        AppLogger.shared.debug("ModelDiscoveryView", "Initialized ModelDiscoveryView")
    }
    
    public var body: some View {
        #if os(iOS) || os(macOS) || os(visionOS)
        NavigationStack {
            ZStack {
                uiaiStyle.backgroundColor.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 6) {
                        if isLoading {
                            ProgressView("Loading models...")
                                .frame(maxWidth: .infinity, minHeight: 120)
                        } else {
                            // --- Hugging Face Login Section ---
                            if huggingFaceToken.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "person.crop.circle.badge.key")
                                        Text("Hugging Face Account")
                                            .font(.headline)
                                        Spacer()
                                        HStack(spacing: 8) {
                                            if isValidatingToken {
                                                ProgressView()
                                                if isTokenValid == true {
                                                    Image(systemName: "checkmark.seal.fill")
                                                        .foregroundColor(uiaiStyle.successColor)
                                                    Text("Logged in")
                                                        .foregroundColor(uiaiStyle.successColor)
                                                    if let username = huggingFaceUsername, !username.isEmpty {
                                                        Text("as \(username)")
                                                            .foregroundColor(uiaiStyle.successColor)
                                                    }
                                                } else {
                                                    Image(systemName: "xmark.seal.fill")
                                                        .foregroundColor(uiaiStyle.errorColor)
                                                    Text("Invalid token")
                                                        .foregroundColor(uiaiStyle.errorColor)
                                                }
                                            } else {
                                                Image(systemName: "person.crop.circle.badge.exclam")
                                                    .foregroundColor(uiaiStyle.secondaryForegroundColor)
                                                Text("Not logged in")
                                                    .foregroundColor(uiaiStyle.secondaryForegroundColor)
                                            }
                                        }
                                    }
                                    HStack {
                                        SecureField("Enter Hugging Face token", text: $tokenInput)
                                            .textFieldStyle(.roundedBorder)
                                        Button("Save") {
                                            huggingFaceToken = tokenInput
                                            Task {
                                                await validateToken(token: tokenInput)
                                            }
                                        }.disabled(tokenInput.isEmpty || isValidatingToken)
                                    }
                                    if let tokenError = tokenError {
                                        Text(tokenError).foregroundColor(.red).font(.caption)
                                    }
                                }
                                .padding([.top, .horizontal])
                                .onAppear {
                                    tokenInput = huggingFaceToken
                                    if !huggingFaceToken.isEmpty { Task { await validateToken(token: huggingFaceToken) } }
                                }
                                Divider()
                            }
                            // --- End Hugging Face Login Section ---
                            if !UserDefaults.standard.bool(forKey: "UIAI.hasSeenOnboarding") {
                                OnboardingBanner()
                                    .padding(.top, 4)
                            }
                            if !recommendedModels.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Recommended for You")
                                        .font(uiaiStyle.font.weight(.bold))
                                        .foregroundColor(uiaiStyle.foregroundColor)
                                        .padding(.horizontal)
                                    HStack(spacing: 12) {
                                        ForEach(recommendedModels) { model in
                                            let (statusIcon, statusColor, statusMessage) = modelHealthStatus(model)
                                            ModelCardView(
                                                model: .init(
                                                    id: model.id,
                                                    name: model.name,
                                                    description: model.description,
                                                    parameters: model.parameters,
                                                    quantization: model.quantization,
                                                    imageURL: model.imageURL,
                                                    isDownloaded: downloadedModelIds.contains(model.id),
                                                    isDownloading: downloadingModelId == model.id,
                                                    downloadProgress: downloadProgress[model.id],
                                                    statusMessage: "Recommended",
                                                    statusColor: uiaiStyle.accentColor,
                                                    architecture: model.architecture
                                                ),
                                                onDownload: { downloadModel(model) },
                                                onDelete: { deleteModel(model) },
                                                onShowDetails: {
                                                    detailModel = model
                                                    showDetailSheet = true
                                                    selectModel(model)
                                                }
                                            )
                                            .frame(width: 320)
                                            .padding(.vertical, 4)
                                            .uiaiStyle(uiaiStyle)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                .padding(.top, 8)
                            }
                            if let errorMessage = errorMessage, showError {
                                ErrorBanner(message: errorMessage, style: .error, isPresented: $showError)
                            }
                            // Search bar
                            HStack {
                                TextField("Search models...", text: $query)
                                    .textFieldStyle(.roundedBorder)
                                    .padding(.horizontal)
                                    .onSubmit { loadModels() }
                                Button("Search") { loadModels() }
                                    .disabled(isLoading)
                                    .padding(.trailing)
                            }
                            Divider()
                            // Model filtering controls
                            HStack {
                                Picker("Type", selection: $selectedType) {
                                    ForEach(typeOptions, id: \.self) { type in
                                        Text(type)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(maxWidth: 300)
                                Picker("Quantization", selection: $selectedQuant) {
                                    ForEach(quantOptions, id: \.self) { quant in
                                        Text(quant)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(maxWidth: 300)
                            }
                            .padding(.horizontal)
                            // Compatible models toggle
                            Toggle(isOn: $showOnlyCompatible) {
                                Text("Show only compatible models")
                                    .font(.subheadline)
                            }
                            .padding(.horizontal)
                            // Sorting controls
                            HStack {
                                Picker("Sort by", selection: $selectedSort) {
                                    ForEach(sortOptions, id: \.self) { sort in
                                        Text(sort)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(maxWidth: 500)
                            }
                            .padding(.horizontal)
                            // Model list
                            if !models.isEmpty {
                                ScrollView {
                                    LazyVStack(spacing: 12) {
                                        ForEach(filteredModels) { model in
                                            let (statusIcon, statusColor, statusMessage) = modelHealthStatus(model)
                                            ModelCardView(
                                                model: .init(
                                                    id: model.id,
                                                    name: model.name,
                                                    description: model.description,
                                                    parameters: model.parameters,
                                                    quantization: model.quantization,
                                                    imageURL: model.imageURL,
                                                    isDownloaded: downloadedModelIds.contains(model.id),
                                                    isDownloading: downloadingModelId == model.id,
                                                    downloadProgress: downloadProgress[model.id],
                                                    statusMessage: statusMessage,
                                                    statusColor: statusColor,
                                                    architecture: model.architecture
                                                ),
                                                onDownload: { downloadModel(model) },
                                                onDelete: { deleteModel(model) },
                                                onShowDetails: {
                                                    detailModel = model
                                                    showDetailSheet = true
                                                    selectModel(model)
                                                }
                                            )
                                            .uiaiStyle(uiaiStyle)
                                        }
                                    }
                                    .padding(.vertical)
                                }
                            } else if !isLoading {
                                Text("No models found.")
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, minHeight: 200)
                            }
                        }
                    }
                }
                .padding(.bottom, 12)
            }
            .navigationTitle("Model Discovery")
            .navigationBarTitleDisplayMode(.inline)
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .task {
                AppLogger.shared.debug("ModelDiscoveryView", ".task triggered, loading models and recommended models")
                loadModels()
                loadRecommendedModel()
            }
            .sheet(isPresented: $showDetailSheet) {
                if let detailModel = detailModel {
                    ModelDetailView(
                        model: detailModel,
                        isDownloaded: downloadedModelIds.contains(detailModel.id),
                        isDownloading: downloadingModelId == detailModel.id,
                        downloadProgress: downloadProgress[detailModel.id],
                        onDownload: { downloadModel(detailModel) },
                        onDelete: { deleteModel(detailModel) },
                        onOpenInBrowser: {
                            if let url = URL(string: "https://huggingface.co/\(detailModel.id)") {
                                #if os(iOS)
                                UIApplication.shared.open(url)
                                #elseif os(macOS)
                                NSWorkspace.shared.open(url)
                                #endif
                            }
                        }
                    )
                }
            }
            .onAppear {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor(uiaiStyle.backgroundColor)
                appearance.titleTextAttributes = [.foregroundColor: UIColor(uiaiStyle.foregroundColor)]
                UINavigationBar.appearance().standardAppearance = appearance
                if #available(iOS 15.0, *) {
                    UINavigationBar.appearance().scrollEdgeAppearance = appearance
                }
            }
        }
        #else
        Text("Model Discovery is not yet available on this platform.")
            .foregroundColor(.secondary)
        #endif
    }

    private func loadModels() {
        AppLogger.shared.debug("ModelDiscoveryView", "loadModels called. Query: \(query)")
        isLoading = true
        error = nil
        models = []
        Task {
            do {
                let results = try await ModelDiscoveryService.searchMLXModels(query: query, limit: 20)
                let downloader = ModelDownloader()
                var downloaded: Set<String> = []
                for model in results {
                    if await FileManagerService.shared.isModelDownloaded(modelId: model.id) {
                        downloaded.insert(model.id)
                    }
                }
                await MainActor.run {
                    AppLogger.shared.debug("ModelDiscoveryView", "Models loaded successfully. Count: \(results.count)")
                    self.models = results
                    self.downloadedModelIds = downloaded
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    AppLogger.shared.error("ModelDiscoveryView", "Error loading models: \(error.localizedDescription)")
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }

    private func downloadModel(_ model: ModelDiscoveryService.ModelSummary) {
        guard downloadingModelId == nil else { return }
        downloadingModelId = model.id
        downloadProgress[model.id] = 0.0
        Task {
            do {
                let downloader = ModelDownloader()
                _ = try await downloader.downloadModel(
                    ModelConfiguration(
                        name: model.name,
                        hubId: model.id,
                        description: model.description,
                        parameters: model.parameters,
                        quantization: model.quantization,
                        architecture: model.architecture
                    ),
                    progress: { progress in
                        Task { @MainActor in
                            downloadProgress[model.id] = progress
                        }
                    }
                )
                await MainActor.run {
                    downloadedModelIds.insert(model.id)
                    downloadingModelId = nil
                    downloadProgress[model.id] = 1.0
                    onModelSelected?(model)
                }
            } catch {
                await MainActor.run {
                    handleError(error)
                    downloadingModelId = nil
                    downloadProgress[model.id] = nil
                }
            }
        }
    }

    private func deleteModel(_ model: ModelDiscoveryService.ModelSummary) {
        Task {
            do {
                let fileManager = FileManagerService.shared
                let modelPath = try await fileManager.getModelPath(modelId: model.id)
                try FileManager.default.removeItem(at: modelPath)
                await MainActor.run {
                    downloadedModelIds.remove(model.id)
                }
            } catch {
                await MainActor.run {
                    handleError(error)
                }
            }
        }
    }

    private func updateModel(_ model: ModelDiscoveryService.ModelSummary) {
        guard downloadedModelIds.contains(model.id) else {
            error = "Model must be downloaded before it can be updated."
            return
        }
        downloadingModelId = model.id
        downloadProgress[model.id] = 0.0
        Task {
            do {
                let downloader = ModelDownloader()
                _ = try await downloader.downloadModel(
                    ModelConfiguration(
                        name: model.name,
                        hubId: model.id,
                        description: model.description,
                        parameters: model.parameters,
                        quantization: model.quantization,
                        architecture: model.architecture
                    ),
                    progress: { progress in
                        Task { @MainActor in
                            downloadProgress[model.id] = progress
                        }
                    }
                )
                await MainActor.run {
                    downloadProgress[model.id] = 1.0
                    downloadingModelId = nil
                    error = nil
                }
            } catch {
                await MainActor.run {
                    handleError(error)
                    downloadingModelId = nil
                    downloadProgress[model.id] = nil
                }
            }
        }
    }

    private func loadRecommendedModel() {
        AppLogger.shared.debug("ModelDiscoveryView", "loadRecommendedModel called.")
        Task {
            do {
                let models = try await ModelDiscoveryService.recommendedMLXModelsForCurrentDevice(limit: 3)
                await MainActor.run {
                    AppLogger.shared.debug("ModelDiscoveryView", "Recommended models loaded. Count: \(models.count)")
                    recommendedModels = models
                }
            } catch {
                AppLogger.shared.error("ModelDiscoveryView", "Error loading recommended models: \(error.localizedDescription)")
                // Ignore errors for now
            }
        }
    }

    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }

    private func modelHealthStatus(_ model: ModelDiscoveryService.ModelSummary) -> (icon: String, color: Color, message: String) {
        if downloadedModelIds.contains(model.id) {
            return ("checkmark.seal.fill", .green, "Downloaded and ready.")
        } else if !model.isMLX {
            return ("xmark.octagon.fill", .red, "Not MLX-compatible.")
        } else {
            return ("exclamationmark.triangle.fill", .yellow, "Not downloaded.")
        }
    }

    private func selectModel(_ model: ModelDiscoveryService.ModelSummary) {
        onModelSelected?(model)
    }

    private func validateToken(token: String) async {
        isValidatingToken = true
        tokenError = nil
        do {
            let username = try await HuggingFaceAPI.shared.validateToken(token: token)
            await MainActor.run {
                isTokenValid = (username != nil)
                huggingFaceUsername = username
                isValidatingToken = false
                tokenError = nil
            }
        } catch {
            await MainActor.run {
                isTokenValid = false
                huggingFaceUsername = nil
                isValidatingToken = false
                tokenError = error.localizedDescription
            }
        }
    }

    // Filtering and sorting logic
    private var filteredModels: [ModelDiscoveryService.ModelSummary] {
        let filtered = models.filter { model in
            let typeMatch = selectedType == "All" || modelType(for: model.architecture) == selectedType
            let quantMatch = selectedQuant == "All" || (model.quantization?.lowercased() == selectedQuant.lowercased())
            let compatibleMatch: Bool = {
                if !showOnlyCompatible { return true }
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
                return ModelRegistry.isModelSupported(config, ramGB: memoryGB, platform: platform)
            }()
            return typeMatch && quantMatch && compatibleMatch
        }
        switch selectedSort {
        case "Most Downloads":
            return filtered.sorted { $0.downloads > $1.downloads }
        case "Most Likes":
            return filtered.sorted { $0.likes > $1.likes }
        case "Model Size":
            return filtered.sorted { (Double($0.parameters?.replacingOccurrences(of: "B", with: "") ?? "0") ?? 0) > (Double($1.parameters?.replacingOccurrences(of: "B", with: "") ?? "0") ?? 0) }
        case "Name (A-Z)":
            return filtered.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        default:
            return filtered
        }
    }

    // Helper for type
    private func modelType(for architecture: String?) -> String? {
        guard let arch = architecture?.lowercased() else { return nil }
        if arch.contains("llava") { return "VLM" }
        if arch.contains("bge") { return "Embedding" }
        if arch.contains("diffusion") || arch.contains("stablediffusion") { return "Diffusion" }
        if arch.contains("llama") || arch.contains("qwen") || arch.contains("mistral") || arch.contains("phi") || arch.contains("gemma") { return "LLM" }
        return nil
    }
}

#if DEBUG
#Preview {
    ModelDiscoveryView()
}
#endif 
import SwiftUI
import MLXEngine

struct ModelDiscoveryView: View {
    @State private var models: [ModelDiscoveryService.ModelSummary] = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var query: String = "mlx"

    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    TextField("Search models...", text: $query)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                    Button("Search") { loadModels() }
                        .disabled(isLoading)
                }
                if isLoading {
                    ProgressView("Loading models...")
                        .padding()
                } else if let error = error {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding()
                } else if models.isEmpty {
                    Text("No models found.")
                        .foregroundStyle(.secondary)
                        .padding()
                } else {
                    List(models) { model in
                        VStack(alignment: .leading) {
                            Text(model.name)
                                .font(.headline)
                            HStack {
                                if let arch = model.architecture {
                                    Text(arch)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                if let quant = model.quantization {
                                    Text(quant)
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                }
                                Text("Downloads: \(model.downloads)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Models")
            .onAppear(perform: loadModels)
        }
    }

    private func loadModels() {
        isLoading = true
        error = nil
        models = []
        Task {
            do {
                let results = try await ModelDiscoveryService.searchMLXModels(query: query, limit: 20)
                await MainActor.run {
                    self.models = results
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
} 
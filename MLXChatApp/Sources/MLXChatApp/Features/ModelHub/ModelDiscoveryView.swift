import SwiftUI
import MLXEngine
import SwiftUIKit

/// Main model discovery view for browsing and downloading HuggingFace models
struct ModelDiscoveryView: View {
    @StateObject private var viewModel = ModelDiscoveryViewModel()
    @State private var searchText = ""
    @State private var selectedFilter: ModelFilter = .all
    @State private var showingFilters = false
    @State private var showingTokenSettings = false
    @Environment(\.uiaiStyle) private var style
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                searchAndFilterBar
                
                // Content area
                if viewModel.isLoading && viewModel.models.isEmpty {
                    loadingView
                } else if viewModel.models.isEmpty && !searchText.isEmpty {
                    emptySearchView
                } else if viewModel.models.isEmpty {
                    emptyStateView
                } else {
                    modelListView
                }
            }
            .background(style.backgroundColor.ignoresSafeArea())
            .navigationTitle("Model Hub")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingTokenSettings = true }) {
                        Image(systemName: "key.fill")
                            .foregroundColor(viewModel.hasValidToken ? style.successColor : style.warningColor)
                    }
                }
            }
            .sheet(isPresented: $showingTokenSettings) {
                HuggingFaceTokenView()
            }
            .refreshable {
                await viewModel.searchModels(query: searchText, filter: selectedFilter)
            }
        }
        .onAppear {
            Task {
                await viewModel.searchModels(query: searchText, filter: selectedFilter)
            }
        }
        .uiaiStyle(style)
    }
    
    private var searchAndFilterBar: some View {
        VStack(spacing: 12) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(style.secondaryForegroundColor)
                TextField("Search models...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(style.font)
                    .foregroundColor(style.foregroundColor)
                    .onSubmit {
                        Task {
                            await viewModel.searchModels(query: searchText, filter: selectedFilter)
                        }
                    }
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        Task {
                            await viewModel.searchModels(query: "", filter: selectedFilter)
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(style.secondaryForegroundColor)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(style.backgroundColor)
            .cornerRadius(style.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: style.cornerRadius)
                    .stroke(style.accentColor.opacity(0.15), lineWidth: 1)
            )
            
            // Filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ModelFilter.allCases, id: \.self) { filter in
                        FilterChip(
                            title: filter.displayName,
                            isSelected: selectedFilter == filter,
                            action: {
                                selectedFilter = filter
                                Task {
                                    await viewModel.searchModels(query: searchText, filter: filter)
                                }
                            }
                        )
                        .uiaiStyle(style)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(style.backgroundColor)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Searching for models...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptySearchView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("No models found")
                .font(.title2)
                .fontWeight(.medium)
            Text("Try adjusting your search terms or filters")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            Text("Discover AI Models")
                .font(.title2)
                .fontWeight(.medium)
            Text("Search for MLX-compatible models from HuggingFace Hub")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Search for models") {
                searchText = "mlx"
                Task {
                    await viewModel.searchModels(query: "mlx", filter: selectedFilter)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var modelListView: some View {
        List {
            ForEach(viewModel.models) { model in
                ModelCardView(
                    model: model,
                    isDownloading: viewModel.downloadingModels.contains(model.id),
                    downloadProgress: viewModel.downloadProgress[model.id] ?? 0,
                    onDownload: {
                        Task {
                            await viewModel.downloadModel(model)
                        }
                    }
                )
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            }
            
            if viewModel.hasMoreResults {
                HStack {
                    Spacer()
                    if viewModel.isLoadingMore {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Button("Load More") {
                            Task {
                                await viewModel.loadMoreResults()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    Spacer()
                }
                .listRowSeparator(.hidden)
                .padding(.vertical, 8)
            }
        }
        .listStyle(.plain)
    }
}

/// Filter options for model discovery
enum ModelFilter: CaseIterable {
    case all, mlx, popular, recent, small, medium, large
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .mlx: return "MLX"
        case .popular: return "Popular"
        case .recent: return "Recent"
        case .small: return "Small (<3B)"
        case .medium: return "Medium (3-7B)"
        case .large: return "Large (>7B)"
        }
    }
    
    var searchQuery: String {
        switch self {
        case .all: return ""
        case .mlx: return "mlx"
        case .popular: return "downloads:>1000"
        case .recent: return "created:>2024"
        case .small: return "parameters:<3B"
        case .medium: return "parameters:3B-7B"
        case .large: return "parameters:>7B"
        }
    }
}

/// Filter chip component
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.uiaiStyle) private var style
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? style.accentColor : style.backgroundColor)
                .foregroundColor(isSelected ? style.backgroundColor : style.foregroundColor)
                .cornerRadius(style.cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: style.cornerRadius)
                        .stroke(isSelected ? style.accentColor : style.secondaryForegroundColor.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ModelDiscoveryView()
} 
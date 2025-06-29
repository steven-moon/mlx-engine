import SwiftUI
import MLXEngine

@main
struct ChatApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @StateObject private var chatViewModel = ChatViewModel()
    
    var body: some View {
        NavigationView {
            ChatView()
                .environmentObject(chatViewModel)
        }
        .navigationTitle("MLXEngine Chat")
    }
}

struct ChatView: View {
    @EnvironmentObject var chatViewModel: ChatViewModel
    @State private var messageText = ""
    @State private var showingModelSelector = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(chatViewModel.messages) { message in
                            MessageView(message: message)
                        }
                        
                        if chatViewModel.isGenerating {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Generating response...")
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                }
                .onChange(of: chatViewModel.messages.count) { oldValue, newValue in
                    if let lastMessage = chatViewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input area
            VStack(spacing: 0) {
                Divider()
                HStack {
                    TextField("Type a message...", text: $messageText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .disabled(chatViewModel.isGenerating)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(chatViewModel.isGenerating ? .gray : .blue)
                    }
                    .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || chatViewModel.isGenerating)
                }
                .padding()
            }
        }
        .navigationTitle("MLXEngine Chat")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Model") {
                    showingModelSelector = true
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Clear") {
                    chatViewModel.clearChat()
                }
            }
        }
        .sheet(isPresented: $showingModelSelector) {
            ModelSelectorView()
                .environmentObject(chatViewModel)
        }
        .alert("Error", isPresented: $chatViewModel.showingError) {
            Button("OK") { }
        } message: {
            Text(chatViewModel.errorMessage)
        }
    }
    
    private func sendMessage() {
        let trimmedMessage = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        messageText = ""
        chatViewModel.sendMessage(trimmedMessage)
    }
}

struct MessageView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray5))
                        .foregroundColor(.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    
                    Text(message.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
        }
    }
}

struct ModelSelectorView: View {
    @EnvironmentObject var chatViewModel: ChatViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Available Models") {
                    ForEach(ModelRegistry.allModels, id: \.hubId) { model in
                        ModelRowView(model: model, isSelected: chatViewModel.currentModel?.hubId == model.hubId)
                            .onTapGesture {
                                chatViewModel.selectModel(model)
                                dismiss()
                            }
                    }
                }
                
                if let currentModel = chatViewModel.currentModel {
                    Section("Current Model") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(currentModel.name)
                                .font(.headline)
                            Text(currentModel.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if let size = currentModel.estimatedSizeGB {
                                Text("Size: \(String(format: "%.1f", size))GB")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Select Model")
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
}

struct ModelRowView: View {
    let model: ModelConfiguration
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.name)
                    .font(.headline)
                Text(model.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                if let size = model.estimatedSizeGB {
                    Text("\(String(format: "%.1f", size))GB")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - View Models

class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isGenerating = false
    @Published var showingError = false
    @Published var errorMessage = ""
    @Published var currentModel: ModelConfiguration?
    
    private var engine: InferenceEngine?
    
    init() {
        // Start with a default model
        selectModel(ModelRegistry.qwen_0_5B)
    }
    
    func selectModel(_ model: ModelConfiguration) {
        currentModel = model
        clearChat()
        
        // Add welcome message
        let welcomeMessage = ChatMessage(
            content: "Hello! I'm \(model.name). How can I help you today?",
            isUser: false,
            timestamp: Date()
        )
        messages.append(welcomeMessage)
    }
    
    func sendMessage(_ content: String) {
        let userMessage = ChatMessage(
            content: content,
            isUser: true,
            timestamp: Date()
        )
        messages.append(userMessage)
        
        Task {
            await generateResponse()
        }
    }
    
    @MainActor
    private func generateResponse() async {
        guard let model = currentModel else { return }
        
        isGenerating = true
        
        do {
            // Load model if needed
            if engine == nil {
                engine = try await InferenceEngine.loadModel(model) { progress in
                    print("Loading progress: \(progress)")
                }
            }
            
            // Generate response
            let response = try await engine!.generate(messages.last!.content)
            
            let aiMessage = ChatMessage(
                content: response,
                isUser: false,
                timestamp: Date()
            )
            messages.append(aiMessage)
            
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
        
        isGenerating = false
    }
    
    func clearChat() {
        messages.removeAll()
        engine?.unload()
        engine = nil
    }
}

// MARK: - Data Models

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp: Date
}

// MARK: - Model Registry Extension

extension ModelRegistry {
    static var allModels: [ModelConfiguration] {
        [
            qwen_0_5B,
            qwen_1B,
            qwen_3B,
            qwen_7B,
            gemma_2B,
            gemma_7B,
            phi_2,
            phi_3
        ]
    }
} 
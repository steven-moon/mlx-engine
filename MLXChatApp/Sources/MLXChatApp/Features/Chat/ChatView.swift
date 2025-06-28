import SwiftUI
import SwiftUIKit

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @Environment(\.uiaiStyle) private var style
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            Divider()
            
            messagesView
            
            ChatInputView(
                text: $viewModel.inputText,
                isGenerating: $viewModel.isGenerating,
                onSend: {
                    await viewModel.sendMessage()
                },
                onStop: {
                    viewModel.stopGeneration()
                }
            )
        }
        .background(style.backgroundColor.ignoresSafeArea())
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
        .task {
            await viewModel.loadAvailableModels()
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("MLX Chat")
                    .font(.headline)
                    .foregroundColor(style.foregroundColor)
                
                if let model = viewModel.selectedModel {
                    Text(model.name)
                        .font(.caption)
                        .foregroundColor(style.secondaryForegroundColor)
                } else {
                    Text("No model selected")
                        .font(.caption)
                        .foregroundColor(style.warningColor ?? .red)
                }
            }
            
            Spacer()
            
            Menu {
                ForEach(viewModel.availableModels, id: \.hubId) { model in
                    Button {
                        Task {
                            await viewModel.selectModel(model)
                        }
                    } label: {
                        HStack {
                            Text(model.name)
                            if model.hubId == viewModel.selectedModel?.hubId {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                
                Divider()
                
                Button(role: .destructive) {
                    viewModel.clearMessages()
                } label: {
                    Label("Clear Chat", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title2)
                    .foregroundColor(style.accentColor)
            }
        }
        .padding()
        .background(style.backgroundColor)
    }
    
    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 8) {
                    if viewModel.messages.isEmpty {
                        emptyStateView
                    } else {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        if viewModel.isGenerating && !viewModel.streamingText.isEmpty {
                            MessageBubble(
                                message: ChatMessage(
                                    content: viewModel.streamingText,
                                    isUser: false,
                                    modelName: viewModel.selectedModel?.name
                                ),
                                isStreaming: true
                            )
                            .id("streaming")
                        }
                    }
                }
                .padding(.top)
            }
            .onChange(of: viewModel.messages.count) {
                withAnimation(.easeOut(duration: 0.3)) {
                    proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                }
            }
            .onChange(of: viewModel.streamingText) {
                withAnimation(.easeOut(duration: 0.1)) {
                    proxy.scrollTo("streaming", anchor: .bottom)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "message.circle")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text("Start a conversation")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("Send a message to begin chatting with your local AI model")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: 300)
    }
} 
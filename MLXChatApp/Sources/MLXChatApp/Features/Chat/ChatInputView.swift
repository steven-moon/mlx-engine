import SwiftUI

struct ChatInputView: View {
    @Binding var text: String
    @Binding var isGenerating: Bool
    let onSend: () async -> Void
    let onStop: () -> Void
    
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .bottom, spacing: 12) {
                TextField("Type a message...", text: $text, axis: .vertical)
                    .textFieldStyle(.plain)
                    .focused($isTextFieldFocused)
                    .lineLimit(1...5)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.secondarySystemBackground))
                    )
                
                if isGenerating {
                    Button(action: onStop) {
                        Image(systemName: "stop.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        Task { await onSend() }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                    }
                    .buttonStyle(.plain)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .padding()
        .background(.thinMaterial)
        .onSubmit {
            if !isGenerating && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Task { await onSend() }
            }
        }
    }
} 
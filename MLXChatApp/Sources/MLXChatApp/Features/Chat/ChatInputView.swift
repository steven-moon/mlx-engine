import SwiftUI
import SwiftUIKit

struct ChatInputView: View {
    @Binding var text: String
    @Binding var isGenerating: Bool
    let onSend: () async -> Void
    let onStop: () -> Void
    
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.uiaiStyle) private var style
    
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
                            .fill(style.backgroundColor)
                    )
                    .foregroundColor(style.foregroundColor)
                
                if isGenerating {
                    Button(action: onStop) {
                        Image(systemName: "stop.circle.fill")
                            .font(.title2)
                            .foregroundColor(style.warningColor ?? .red)
                    }
                    .buttonStyle(.plain)
                } else {
                    Button {
                        Task { await onSend() }
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? style.secondaryForegroundColor : style.accentColor)
                    }
                    .buttonStyle(.plain)
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .padding()
        .background(style.backgroundColor)
        .onSubmit {
            if !isGenerating && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Task { await onSend() }
            }
        }
    }
} 
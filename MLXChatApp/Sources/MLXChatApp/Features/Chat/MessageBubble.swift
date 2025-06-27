import SwiftUI

struct MessageBubble: View {
    let message: ChatMessage
    let isStreaming: Bool
    
    init(message: ChatMessage, isStreaming: Bool = false) {
        self.message = message
        self.isStreaming = isStreaming
    }
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer(minLength: 60)
                messageContent
            } else {
                messageContent
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    private var messageContent: some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
            HStack {
                if !message.isUser {
                    Image(systemName: "cpu")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                
                Text(message.isUser ? "You" : (message.modelName ?? "Assistant"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if message.isUser {
                    Image(systemName: "person.circle.fill")
                        .foregroundStyle(.blue)
                        .font(.caption)
                }
            }
            
            HStack {
                Text(message.content)
                    .textSelection(.enabled)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(message.isUser ? Color.blue : Color(.secondarySystemBackground))
                    )
                    .foregroundStyle(message.isUser ? .white : .primary)
                
                if isStreaming {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            HStack {
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                
                if !message.isUser && !isStreaming {
                    Button {
                        #if os(macOS)
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(message.content, forType: .string)
                        #else
                        UIPasteboard.general.string = message.content
                        #endif
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.caption2)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }
} 
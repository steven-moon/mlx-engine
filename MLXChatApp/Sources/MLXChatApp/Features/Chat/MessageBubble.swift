import SwiftUI
import SwiftUIKit

struct MessageBubble: View {
    let message: ChatMessage
    let isStreaming: Bool
    @Environment(\.uiaiStyle) private var style
    
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
                        .foregroundColor(style.secondaryForegroundColor)
                        .font(.caption)
                }
                
                Text(message.isUser ? "You" : (message.modelName ?? "Assistant"))
                    .font(.caption)
                    .foregroundColor(style.secondaryForegroundColor)
                
                if message.isUser {
                    Image(systemName: "person.circle.fill")
                        .foregroundColor(style.accentColor)
                        .font(.caption)
                }
            }
            
            HStack {
                Text(message.content)
                    .textSelection(.enabled)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(message.isUser ? style.accentColor : style.backgroundColor)
                    )
                    .foregroundColor(message.isUser ? style.backgroundColor : style.foregroundColor)
                
                if isStreaming {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            HStack {
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundColor(style.secondaryForegroundColor)
                
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
                    .foregroundColor(style.secondaryForegroundColor)
                }
            }
        }
    }
} 
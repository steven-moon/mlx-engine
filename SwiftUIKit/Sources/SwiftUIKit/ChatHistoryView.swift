//
//  ChatHistoryView.swift
//  UIAI
//
//  Created for MLXEngine Shared SwiftUI Library
//
//  A reusable SwiftUI view for displaying a scrollable chat history.
//

import SwiftUI

/// A SwiftUI view for displaying a scrollable chat history.
///
/// - Accepts an array of messages and scrolls to the latest message.
/// - Designed for use in ChatView and other chat UIs.
/// - Public, documented, and cross-platform.
public struct ChatHistoryView<Message: Identifiable & Hashable>: View {
    public let messages: [Message]
    public let messageView: (Message) -> AnyView
    
    public init(messages: [Message], messageView: @escaping (Message) -> AnyView) {
        self.messages = messages
        self.messageView = messageView
    }
    
    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(messages) { message in
                        messageView(message)
                            .id(message.id)
                    }
                }
                .padding()
            }
            .onChange(of: messages.count) { _ in
                if let last = messages.last {
                    proxy.scrollTo(last.id, anchor: .bottom)
                }
            }
        }
    }
}

#if DEBUG
private struct DemoMessage: Identifiable, Hashable {
    let id = UUID()
    let sender: String
    let text: String
}

struct ChatHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        ChatHistoryView(messages: [
            DemoMessage(sender: "assistant", text: "Hello!"),
            DemoMessage(sender: "user", text: "Hi there!")
        ]) { message in
            AnyView(
                HStack {
                    Text("\(message.sender):")
                        .fontWeight(.bold)
                    Text(message.text)
                }
            )
        }
        .uiaiStyle(MinimalStyle(colorScheme: .light))
    }
}
#endif 
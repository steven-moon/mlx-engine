//
//  ChatInputView.swift
//  UIAI
//
//  Created for MLXEngine Shared SwiftUI Library
//
//  A reusable SwiftUI view for chat input (text field + send button).
//

import SwiftUI

/// A SwiftUI view for chat input (text field + send button).
///
/// - Exposes the input text as a binding and provides a send action closure.
/// - Supports multi-line input and keyboard submit.
/// - Public, documented, and cross-platform.
public struct ChatInputView: View {
    @Binding public var text: String
    public var onSend: () -> Void
    @FocusState private var isInputFocused: Bool
    
    public init(text: Binding<String>, onSend: @escaping () -> Void) {
        self._text = text
        self.onSend = onSend
    }
    
    public var body: some View {
        HStack {
            TextField("Type a message...", text: $text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .focused($isInputFocused)
                .onSubmit(onSend)
            Button(action: onSend) {
                Image(systemName: "paperplane.fill")
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
    }
}

#if DEBUG
#Preview {
    @State var text = ""
    return ChatInputView(text: $text, onSend: { print("Send: \(text)") })
        .previewLayout(.sizeThatFits)
}
#endif 
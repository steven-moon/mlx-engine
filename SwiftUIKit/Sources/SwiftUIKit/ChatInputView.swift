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
            #if os(macOS)
            if #available(macOS 13, *) {
                TextField("Type a message...", text: $text, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .focused($isInputFocused)
                    .onSubmit(onSend)
            } else {
                TextField("Type a message...", text: $text)
                    .textFieldStyle(.roundedBorder)
                    .focused($isInputFocused)
                    .onSubmit(onSend)
            }
            #elseif os(iOS) || os(tvOS) || os(visionOS)
            if #available(iOS 16.0, tvOS 16.0, visionOS 1.0, *) {
                TextField("Type a message...", text: $text, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .focused($isInputFocused)
                    .onSubmit(onSend)
            } else {
                TextField("Type a message...", text: $text)
                    .textFieldStyle(.roundedBorder)
                    .focused($isInputFocused)
                    .onSubmit(onSend)
            }
            #else
            TextField("Type a message...", text: $text)
                .textFieldStyle(.roundedBorder)
                .focused($isInputFocused)
                .onSubmit(onSend)
            #endif
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
struct ChatInputView_Previews: PreviewProvider {
    static var previews: some View {
        @State var text = ""
        return ChatInputView(text: $text, onSend: { print("Send: \(text)") })
            .uiaiStyle(MinimalStyle(colorScheme: .light))
    }
}
#endif 
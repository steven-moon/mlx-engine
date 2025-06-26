//
//  ErrorBanner.swift
//  UIAI
//
//  Created for MLXEngine Shared SwiftUI Library
//
//  A SwiftUI banner for displaying error, warning, or info messages.
//

import SwiftUI

/// A SwiftUI banner for displaying error, warning, or info messages.
///
/// - Dismissible, supports different styles, and is cross-platform.
/// - Public and ready for integration with any UIAI or app view.
public struct ErrorBanner: View {
    public enum Style { case error, warning, info }
    public let message: String
    public let style: Style
    @Binding public var isPresented: Bool
    
    public init(message: String, style: Style = .error, isPresented: Binding<Bool>) {
        self.message = message
        self.style = style
        self._isPresented = isPresented
    }
    
    public var body: some View {
        if isPresented {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .foregroundColor(iconColor)
                Text(message)
                    .font(.caption)
                    .foregroundColor(.primary)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(10)
            .background(backgroundColor)
            .cornerRadius(10)
            .shadow(radius: 2)
            .padding(.horizontal)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.easeInOut, value: isPresented)
        }
    }
    
    private var iconName: String {
        switch style {
        case .error: return "exclamationmark.triangle.fill"
        case .warning: return "exclamationmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
    private var iconColor: Color {
        switch style {
        case .error: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }
    private var backgroundColor: Color {
        switch style {
        case .error: return Color.red.opacity(0.12)
        case .warning: return Color.orange.opacity(0.12)
        case .info: return Color.blue.opacity(0.10)
        }
    }
}

#if DEBUG
#Preview {
    @State var show = true
    return VStack {
        ErrorBanner(message: "Something went wrong!", style: .error, isPresented: $show)
        ErrorBanner(message: "This is a warning.", style: .warning, isPresented: .constant(true))
        ErrorBanner(message: "FYI: All systems go.", style: .info, isPresented: .constant(true))
    }
    .padding()
    .previewLayout(.sizeThatFits)
}
#endif 
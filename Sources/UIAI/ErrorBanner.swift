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
    @Environment(\.uiaiStyle) private var uiaiStyle: any UIAIStyle
    
    public init(message: String, style: Style = .error, isPresented: Binding<Bool>) {
        self.message = message
        self.style = style
        self._isPresented = isPresented
    }
    
    public var body: some View {
        if isPresented {
            HStack(spacing: 12) {
                if let logo = uiaiStyle.logo {
                    logo
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                } else {
                    Image(systemName: iconName)
                        .foregroundColor(iconColor)
                }
                Text(message)
                    .font(uiaiStyle.font)
                    .foregroundColor(uiaiStyle.foregroundColor)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(10)
            .background(backgroundColor)
            .cornerRadius(uiaiStyle.cornerRadius)
            .shadow(color: uiaiStyle.shadow?.color ?? .clear, radius: uiaiStyle.shadow?.radius ?? 0)
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
        case .error: return uiaiStyle.accentColor
        case .warning: return uiaiStyle.accentColor.opacity(0.8)
        case .info: return uiaiStyle.accentColor.opacity(0.6)
        }
    }
    private var backgroundColor: Color {
        switch style {
        case .error: return uiaiStyle.backgroundColor.opacity(0.9)
        case .warning: return uiaiStyle.backgroundColor.opacity(0.85)
        case .info: return uiaiStyle.backgroundColor.opacity(0.8)
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
import SwiftUI
import Foundation

public struct ToastView: View {
    public let message: String
    public let icon: String?
    public let actionTitle: String?
    public let action: (() -> Void)?
    public let style: any UIAIStyle
    public let duration: TimeInterval
    @Binding public var isPresented: Bool
    
    public init(message: String, icon: String? = nil, actionTitle: String? = nil, action: (() -> Void)? = nil, style: any UIAIStyle, duration: TimeInterval = 2.5, isPresented: Binding<Bool>) {
        self.message = message
        self.icon = icon
        self.actionTitle = actionTitle
        self.action = action
        self.style = style
        self.duration = duration
        self._isPresented = isPresented
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            if let icon {
                Image(systemName: icon)
                    .foregroundColor(style.accentColor)
            }
            Text(message)
                .foregroundColor(style.foregroundColor)
                .font(.body)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.body.bold())
                    .foregroundColor(style.accentColor)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(style.backgroundColor.opacity(0.95))
        .cornerRadius(style.cornerRadius)
        .shadow(color: style.shadow?.color.opacity(0.2) ?? .clear, radius: style.shadow?.radius ?? 8)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                withAnimation { isPresented = false }
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .padding(.horizontal, 24)
    }
}

public extension View {
    func toast(isPresented: Binding<Bool>, message: String, icon: String? = nil, actionTitle: String? = nil, action: (() -> Void)? = nil, style: any UIAIStyle, duration: TimeInterval = 2.5) -> some View {
        ZStack {
            self
            if isPresented.wrappedValue {
                VStack {
                    Spacer()
                    ToastView(message: message, icon: icon, actionTitle: actionTitle, action: action, style: style, duration: duration, isPresented: isPresented)
                        .padding(.bottom, 32)
                }
                .animation(.easeInOut, value: isPresented.wrappedValue)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
} 
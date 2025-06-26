//
//  OnboardingBanner.swift
//  UIAI
//
//  Created for MLXEngine Shared SwiftUI Library
//
//  A SwiftUI banner for onboarding and first-time user guidance.
//

import SwiftUI

/// A SwiftUI banner for onboarding and first-time user guidance.
///
/// - Shows a welcome message, description, and dismiss button.
/// - Only appears on first launch (persisted with @AppStorage).
/// - Public, documented, and cross-platform.
public struct OnboardingBanner: View {
    @AppStorage("UIAI.hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    public let title: String
    public let message: String
    @Environment(\.uiaiStyle) private var uiaiStyle
    
    public init(title: String = "Welcome to MLXEngine!", message: String = "Discover, chat, and build with AI models. Start by selecting a model or opening the chat panel.") {
        self.title = title
        self.message = message
    }
    
    public var body: some View {
        if !hasSeenOnboarding {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Image(systemName: "sparkles")
                        .foregroundColor(uiaiStyle.accentColor)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(uiaiStyle.font.weight(.bold))
                            .foregroundColor(uiaiStyle.foregroundColor)
                        Text(message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: { hasSeenOnboarding = true }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: uiaiStyle.cornerRadius).fill(uiaiStyle.backgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: uiaiStyle.cornerRadius)
                    .stroke(uiaiStyle.accentColor.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal)
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.easeInOut, value: hasSeenOnboarding)
        }
    }
}

#if DEBUG
#Preview {
    OnboardingBanner()
        .previewLayout(.sizeThatFits)
}
#endif 
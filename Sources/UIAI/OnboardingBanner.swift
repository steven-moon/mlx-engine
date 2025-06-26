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
    
    public init(title: String = "Welcome to MLXEngine!", message: String = "Discover, chat, and build with AI models. Start by selecting a model or opening the chat panel.") {
        self.title = title
        self.message = message
    }
    
    public var body: some View {
        if !hasSeenOnboarding {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.accentColor)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.headline)
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
            .background(
                RoundedRectangle(cornerRadius: 14).fill(
                    {
                        #if os(iOS) || os(tvOS) || os(visionOS)
                        return Color(UIColor.systemGray6)
                        #elseif os(macOS)
                        return Color(NSColor.windowBackgroundColor)
                        #else
                        return Color.gray.opacity(0.15)
                        #endif
                    }()
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        {
                            #if os(iOS) || os(tvOS) || os(visionOS)
                            return Color(UIColor.separator)
                            #elseif os(macOS)
                            return Color(NSColor.separatorColor)
                            #else
                            return Color.gray.opacity(0.3)
                            #endif
                        }(),
                        lineWidth: 1
                    )
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
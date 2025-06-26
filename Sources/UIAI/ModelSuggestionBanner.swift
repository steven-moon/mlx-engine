//
//  ModelSuggestionBanner.swift
//  UIAI
//
//  Created for MLXEngine Shared SwiftUI Library
//
//  A SwiftUI banner for suggesting a recommended model based on device or context.
//

import SwiftUI

/// A SwiftUI banner for suggesting a recommended model based on device or context.
///
/// - Shows model name, description, and a button to select or download.
/// - Public, documented, and cross-platform.
public struct ModelSuggestionBanner: View {
    public let modelName: String
    public let modelDescription: String
    public let onSelect: () -> Void
    @Environment(\.uiaiStyle) private var uiaiStyle: any UIAIStyle
    
    public init(modelName: String, modelDescription: String, onSelect: @escaping () -> Void) {
        self.modelName = modelName
        self.modelDescription = modelDescription
        self.onSelect = onSelect
    }
    
    public var body: some View {
        HStack(alignment: .center, spacing: 16) {
            if let logo = uiaiStyle.logo {
                logo
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
            } else {
                Image(systemName: "star.fill")
                    .foregroundColor(uiaiStyle.accentColor)
                    .font(.title2)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(modelName)
                    .font(uiaiStyle.font.weight(.bold))
                    .foregroundColor(uiaiStyle.foregroundColor)
                Text(modelDescription)
                    .font(.caption)
                    .foregroundColor(uiaiStyle.secondaryForegroundColor)
            }
            Spacer()
            Button(action: onSelect) {
                Text("Use Model")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(uiaiStyle.accentColor.opacity(0.15))
                    .cornerRadius(uiaiStyle.cornerRadius)
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: uiaiStyle.cornerRadius).fill(uiaiStyle.backgroundColor))
        .overlay(
            RoundedRectangle(cornerRadius: uiaiStyle.cornerRadius)
                .stroke(uiaiStyle.accentColor.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

#if DEBUG
#Preview {
    ModelSuggestionBanner(
        modelName: "Qwen 0.5B Chat",
        modelDescription: "Recommended for your device: fast, efficient, and accurate.",
        onSelect: {}
    )
    .previewLayout(.sizeThatFits)
}
#endif 
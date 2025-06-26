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
    
    public init(modelName: String, modelDescription: String, onSelect: @escaping () -> Void) {
        self.modelName = modelName
        self.modelDescription = modelDescription
        self.onSelect = onSelect
    }
    
    public var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: "star.fill")
                .foregroundColor(.yellow)
                .font(.title2)
            VStack(alignment: .leading, spacing: 4) {
                Text(modelName)
                    .font(.headline)
                Text(modelDescription)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Button(action: onSelect) {
                Text("Use Model")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.15))
                    .cornerRadius(8)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12).fill(
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
            RoundedRectangle(cornerRadius: 12)
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
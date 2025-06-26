//
//  TokenProgressBar.swift
//  UIAI
//
//  Created for MLXEngine Shared SwiftUI Library
//
//  A cross-platform SwiftUI view for visualizing token generation or download progress.
//  This is a stub for future expansion and integration with MLXEngine APIs.
//

import SwiftUI

/// A SwiftUI view for visualizing token generation or download progress.
///
/// - Designed for iOS, macOS, visionOS, tvOS, and watchOS.
/// - Use for LLM streaming, downloads, or other progress indicators.
public struct TokenProgressBar: View {
    public enum Style { case normal, error, warning }
    public let progress: Double // 0.0 ... 1.0
    public let label: String?
    public let style: Style
    
    public init(progress: Double, label: String? = nil, style: Style = .normal) {
        self.progress = progress
        self.label = label
        self.style = style
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let label = label {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(backgroundColor)
                        .frame(height: 8)
                    Capsule()
                        .fill(foregroundColor)
                        .frame(width: max(0, min(CGFloat(progress), 1.0)) * geo.size.width, height: 8)
                }
            }
            .frame(height: 8)
        }
    }
    
    private var foregroundColor: Color {
        switch style {
        case .normal: return .accentColor
        case .error: return .red
        case .warning: return .orange
        }
    }
    private var backgroundColor: Color {
        switch style {
        case .normal:
            #if os(iOS) || os(tvOS) || os(visionOS)
            return Color(UIColor.systemGray5)
            #elseif os(macOS)
            return Color(NSColor.systemGray)
            #else
            return Color.gray.opacity(0.15)
            #endif
        case .error: return Color.red.opacity(0.15)
        case .warning: return Color.orange.opacity(0.15)
        }
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 16) {
        TokenProgressBar(progress: 0.7, label: "Downloading", style: .normal)
        TokenProgressBar(progress: 0.3, label: "Stalled", style: .warning)
        TokenProgressBar(progress: 1.0, label: "Failed", style: .error)
    }
    .padding()
    .previewLayout(.sizeThatFits)
}
#endif 
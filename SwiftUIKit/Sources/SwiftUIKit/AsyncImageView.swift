//
//  AsyncImageView.swift
//  UIAI
//
//  Created for MLXEngine Shared SwiftUI Library
//
//  A cross-platform SwiftUI view for async image loading (remote/local).
//  This is a stub for future expansion and integration with model cards, avatars, etc.
//

import SwiftUI

/// A SwiftUI view for async image loading (remote/local).
///
/// - Designed for iOS, macOS, visionOS, tvOS, and watchOS.
/// - Use for model cards, avatars, and image-based models.
public struct AsyncImageView: View {
    public let url: URL?
    public let placeholder: Image
    @Environment(\.uiaiStyle) private var uiaiStyle: any UIAIStyle
    
    public init(url: URL?, placeholder: Image = Image(systemName: "photo")) {
        self.url = url
        self.placeholder = placeholder
    }
    
    public var body: some View {
        #if os(iOS) || os(macOS) || os(visionOS)
        if let url = url {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    placeholder
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(uiaiStyle.secondaryForegroundColor)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                case .failure:
                    placeholder
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(uiaiStyle.errorColor)
                @unknown default:
                    placeholder
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(uiaiStyle.secondaryForegroundColor)
                }
            }
        } else {
            placeholder
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(uiaiStyle.secondaryForegroundColor)
        }
        #else
        placeholder
            .resizable()
            .scaledToFit()
            .frame(width: 80, height: 80)
            .foregroundColor(uiaiStyle.secondaryForegroundColor)
        #endif
    }
}

#if DEBUG
struct AsyncImageView_Previews: PreviewProvider {
    static var previews: some View {
        AsyncImageView(url: nil)
            .uiaiStyle(MinimalStyle(colorScheme: .light))
    }
}
#endif 
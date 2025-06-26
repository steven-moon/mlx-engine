# SwiftUIKit

A universal, modern SwiftUI component library for all Apple platforms.

SwiftUIKit provides a suite of flexible, composable, and beautiful UI elements for model discovery, chat, diagnostics, and more—enabling developers to build robust, stylish apps for iOS, macOS, visionOS, tvOS, and watchOS with minimal effort.

## Features

- **Plug-and-play**: Drop-in SwiftUI components for any app
- **Cross-platform**: Native support for iOS, macOS, tvOS, watchOS, and visionOS
- **Modern Style System**: Runtime-themable via a powerful style protocol
- **Chat & Conversation**: Streaming chat UI, input, and history
- **Model Discovery**: Model cards, detail views, and suggestion banners
- **Diagnostics**: Debug panels, error banners, and progress bars
- **Utilities**: Async image loading, adaptive layouts, and more

## Example Usage

```swift
import SwiftUIKit

struct MyAppView: View {
    var body: some View {
        NavigationView {
            ModelDiscoveryView()
        }
        .uiaiStyle(MinimalStyle()) // Apply a built-in style
    }
}
```

## Installation

Add SwiftUIKit to your project using [Swift Package Manager](https://developer.apple.com/documentation/swift_packages/adding_package_dependencies_to_your_app):

1. In Xcode, go to **File > Add Packages...**
2. Enter your repository URL (after you push this package to GitHub)
3. Select **SwiftUIKit** and add it to your target

## Documentation

See [`_docs/SwiftUIKit_Package_Specification.md`](./_docs/SwiftUIKit_Package_Specification.md) for the full architecture and component catalog.

---

*Last updated: 2024-06-26* 
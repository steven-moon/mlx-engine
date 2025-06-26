# SwiftUIKit: Universal SwiftUI Component Library Specification

---

## 1. Vision & Goals

- **Universal**: Usable in any SwiftUI-based app, not tied to MLXEngine or any backend.
- **Cross-platform**: Native support for iOS, macOS, visionOS, tvOS, and watchOS.
- **Composable**: Components are modular, reusable, and can be combined or used standalone.
- **Customizable**: Theming, extensibility, and runtime style switching are first-class.
- **AI-native**: Optimized for LLM/VLM/embedding workflows, but not limited to them.
- **Open & Extensible**: Designed for community contributions and custom extensions.

---

## 2. Package Structure

```
SwiftUIKit/
├── Package.swift
├── Sources/
│   └── SwiftUIKit/
│       ├── Components/
│       │   ├── Chat/
│       │   │   ├── ChatView.swift
│       │   │   ├── ChatInputView.swift
│       │   │   ├── ChatHistoryView.swift
│       │   │   └── MessageBubble.swift
│       │   ├── Model/
│       │   │   ├── ModelDiscoveryView.swift
│       │   │   ├── ModelDetailView.swift
│       │   │   ├── ModelCardView.swift
│       │   │   └── ModelSuggestionBanner.swift
│       │   ├── Diagnostics/
│       │   │   ├── DebugPanel.swift
│       │   │   └── ErrorBanner.swift
│       │   ├── Utilities/
│       │   │   ├── AsyncImageView.swift
│       │   │   ├── TokenProgressBar.swift
│       │   │   └── PlatformAdaptiveView.swift
│       │   └── Settings/
│       │       └── SettingsPanel.swift
│       ├── Style/
│       │   ├── SwiftUIKitStyle.swift
│       │   ├── SwiftUIKitStyleRegistry.swift
│       │   ├── BuiltInStyles.swift
│       │   └── StyleGallery.swift
│       ├── Extensions/
│       │   └── SwiftUI+Extensions.swift
│       └── Support/
│           └── Platform.swift
├── Tests/
│   └── SwiftUIKitTests/
│       └── (Component and style tests)
└── README.md
```

---

## 3. Core Architecture

### 3.1. Style System

- **Protocol-driven**: All theming via a `SwiftUIKitStyle` protocol.
- **Built-in Styles**: Neumorphic, Glassmorphic, Minimal, Dark, Vibrant, etc.
- **Style Registry**: Central registry for built-in and custom styles.
- **Environment Integration**: Use `.swiftUIKitStyle(...)` at the app root; access via `@Environment(\\.swiftUIKitStyle)`.
- **Runtime Switching**: Support for dynamic style switching (e.g., via `@AppStorage`).
- **Accessibility**: All styles support dark mode, high contrast, and dynamic type.

### 3.2. Component Design

- **SwiftUI-first**: All components are pure SwiftUI, using idiomatic patterns (`Observable`, `@StateObject`, etc.).
- **Platform Adaptive**: Use `PlatformAdaptiveView` and conditional compilation for platform-specific tweaks.
- **Composable**: Each component is self-contained, with clear public APIs and minimal dependencies.
- **Extensible**: Allow injection of custom views, actions, and data sources.
- **Error Handling**: Inline error banners and diagnostics for robust UX.

### 3.3. API Surface

- **Public API**: Only expose types, protocols, and views intended for external use.
- **Doc-comments**: Every public symbol must have a `///` doc-comment explaining what and why.
- **No Backend Coupling**: No direct dependency on MLXEngine or any backend; data is injected via view models or bindings.

---

## 4. Key Components

### 4.1. Model Discovery & Management

- `ModelDiscoveryView`: Search, filter, and select models.
- `ModelDetailView`: Show model metadata and actions.
- `ModelCardView`: Compact model summary.
- `ModelSuggestionBanner`: Inline suggestions.

### 4.2. Chat & Conversation

- `ChatView`: Streaming chat interface.
- `ChatInputView`: Multi-line, expandable input.
- `ChatHistoryView`: List/search past sessions.
- `MessageBubble`: Rich message rendering.

### 4.3. Diagnostics & Utilities

- `DebugPanel`: In-app diagnostics/logs.
- `ErrorBanner`: Inline error display.
- `AsyncImageView`: Remote image loading.
- `TokenProgressBar`: Streaming/progress visualization.
- `PlatformAdaptiveView`: Layout adaptation.

### 4.4. Settings

- `SettingsPanel`: Unified settings for style, preferences, etc.

---

## 5. Style System: Detailed Specification

- **Protocol**:
  ```swift
  public protocol SwiftUIKitStyle: Hashable, Sendable {
      var backgroundColor: Color { get }
      var foregroundColor: Color { get }
      var accentColor: Color { get }
      var cornerRadius: CGFloat { get }
      var shadow: ShadowStyle? { get }
      var font: Font { get }
      // Extend as needed
  }
  ```
- **Registry**:
  ```swift
  public struct SwiftUIKitStyleRegistry {
      public static func style(for kind: SwiftUIKitStyleKind) -> SwiftUIKitStyle
      public static func register(_ style: SwiftUIKitStyle, for key: String)
  }
  ```
- **Environment**:
  ```swift
  extension View {
      public func swiftUIKitStyle(_ style: SwiftUIKitStyle) -> some View
  }
  ```
- **Usage**:
  ```swift
  struct MyView: View {
      @Environment(\.swiftUIKitStyle) var style
      // ...
  }
  ```

---

## 6. Extensibility & Customization

- **Custom Styles**: Developers can define and register their own `SwiftUIKitStyle` conforming types.
- **Custom Components**: All major components accept injected subviews or actions.
- **Settings Integration**: Expose APIs for runtime style switching and user preferences.

---

## 7. Testing & Quality

- **Unit Tests**: All public APIs and components must have tests.
- **SwiftUI Previews**: Each component includes a preview with multiple styles.
- **CI Integration**: Linting, formatting, and test coverage required.

---

## 8. Documentation

- **README.md**: Overview, installation, and usage examples.
- **Component Docs**: Each component has usage, customization, and integration notes.
- **Style Guide**: Document how to add new styles and register them.
- **Integration Recipes**: Example code for common app types (chatbot, model browser, etc.).

---

## 9. Implementation Plan

1. **Extract** all SwiftUIKit components and style system into a new Swift package.
2. **Refactor** to remove any MLXEngine or backend-specific code; use protocols or dependency injection for data.
3. **Implement** the style system as described, with built-in and custom style support.
4. **Add** SwiftUI previews and unit tests for all components.
5. **Document** all public APIs and provide integration guides.
6. **Publish** as an open-source Swift package (optionally to GitHub/SwiftPM registry).

---

## 10. References & Best Practices

- [Apple Human Interface Guidelines: Color and Themes](https://developer.apple.com/design/human-interface-guidelines/color)
- [SwiftUI Environment Documentation](https://developer.apple.com/documentation/swiftui/environment)
- [Neumorphism in User Interfaces](https://uxdesign.cc/neumorphism-in-user-interfaces-b47cef3bf3a6)
- [Glassmorphism in User Interfaces](https://uxdesign.cc/glassmorphism-in-user-interfaces-1f39bb1308c9)
- [Minimal Portfolio Websites](https://www.awwwards.com/20-best-minimal-portfolio-websites.html)
- [Gradient UI Kit](https://www.behance.net/gallery/116677209/Gradient-UI-Kit)

---

*Last updated: 2024-06-26* 
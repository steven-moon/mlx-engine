# UIAI Style System Design

---

## Overview

This document outlines a flexible, extensible, and modern style system for the UIAI SwiftUI library. The goal is to enable creative, beautiful, and consistent user interfaces that can easily adopt trending styles, support runtime switching, and allow for custom extensions. The system is designed to be stable, type-safe, and easy to integrate across all UIAI components.

---

## 1. Design Goals

- **Flexibility**: Support multiple, swappable styles (themes) at runtime.
- **Extensibility**: Allow developers to define and register custom styles.
- **Stability**: Type-safe, avoids runtime errors, and integrates with SwiftUI best practices.
- **Composability**: Styles can be applied globally, per-view, or per-section.
- **Modern Aesthetics**: Built-in support for trending UI styles.
- **Accessibility**: Support for dark mode, high contrast, and dynamic type.

---

## 2. Trending UI Styles (2024)

Based on current research and design trends, the following styles are recommended as built-in options:

1. **Neumorphism (Soft UI)**
2. **Glassmorphism**
3. **Minimalism with Bold Typography**
4. **Dark Mode / High Contrast**
5. **Vibrant Gradients & Retro-Futuristic**

Each style can be implemented as a struct conforming to a shared protocol.

---

## 3. Core Architecture

### 3.1. Style Protocol

Define a protocol encapsulating all style properties:

```swift
public protocol UIAIStyle: Hashable, Sendable {
    var backgroundColor: Color { get }
    var foregroundColor: Color { get }
    var accentColor: Color { get }
    var cornerRadius: CGFloat { get }
    var shadow: ShadowStyle? { get }
    var font: Font { get }
    // Extend as needed (borders, gradients, etc.)
}

public struct ShadowStyle: Hashable, Sendable {
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat
}
```

### 3.2. Built-in Styles

Implement built-in styles as structs:

```swift
public struct NeumorphicStyle: UIAIStyle { /* ... */ }
public struct GlassmorphicStyle: UIAIStyle { /* ... */ }
public struct MinimalStyle: UIAIStyle { /* ... */ }
public struct DarkStyle: UIAIStyle { /* ... */ }
public struct VibrantStyle: UIAIStyle { /* ... */ }
```

### 3.3. Style Registry & Kind

Provide a registry for built-in and custom styles:

```swift
public enum UIAIStyleKind: String, CaseIterable, Codable {
    case neumorphic, glassmorphic, minimal, dark, vibrant
}

public struct UIAIStyleRegistry {
    public static func style(for kind: UIAIStyleKind) -> UIAIStyle { /* ... */ }
    public static func register(_ style: UIAIStyle, for key: String) { /* ... */ }
}
```

### 3.4. Environment Integration

Inject the current style using SwiftUI's environment:

```swift
public struct UIAIStyleEnvironmentKey: EnvironmentKey {
    public static let defaultValue: UIAIStyle = MinimalStyle()
}

extension EnvironmentValues {
    public var uiaiStyle: UIAIStyle {
        get { self[UIAIStyleEnvironmentKey.self] }
        set { self[UIAIStyleEnvironmentKey.self] = newValue }
    }
}

extension View {
    public func uiaiStyle(_ style: UIAIStyle) -> some View {
        environment(\.uiaiStyle, style)
    }
}
```

### 3.5. Usage Example

```swift
struct MyStyledButton: View {
    @Environment(\.uiaiStyle) var style

    var body: some View {
        Button("Click Me") { /* ... */ }
            .padding()
            .background(style.backgroundColor)
            .foregroundColor(style.foregroundColor)
            .cornerRadius(style.cornerRadius)
            .shadow(color: style.shadow?.color ?? .clear,
                    radius: style.shadow?.radius ?? 0)
            .font(style.font)
    }
}
```

---

## 4. Extensibility & Custom Styles

- Developers can define their own `UIAIStyle` conforming types.
- Register custom styles in the registry for runtime selection.
- Support for dynamic switching (e.g., via a settings panel).

---

## 5. Accessibility & Dynamic Features

- Support for dark mode and high contrast by providing variants or dynamic properties.
- Use dynamic type and system colors where possible.
- Allow runtime switching via user settings or system preferences.

---

## 6. Integration Plan

1. Implement the `UIAIStyle` protocol and built-in styles.
2. Refactor UIAI components to use the style environment.
3. Add a settings panel for style selection.
4. Document how to add and register custom styles.
5. Add unit tests for style application and switching.

---

## 7. References

- [Apple Human Interface Guidelines: Color and Themes](https://developer.apple.com/design/human-interface-guidelines/color)
- [SwiftUI Environment Documentation](https://developer.apple.com/documentation/swiftui/environment)
- [Neumorphism in User Interfaces](https://uxdesign.cc/neumorphism-in-user-interfaces-b47cef3bf3a6)
- [Glassmorphism in User Interfaces](https://uxdesign.cc/glassmorphism-in-user-interfaces-1f39bb1308c9)
- [Minimal Portfolio Websites](https://www.awwwards.com/20-best-minimal-portfolio-websites.html)
- [Gradient UI Kit](https://www.behance.net/gallery/116677209/Gradient-UI-Kit)

---

## Cursor Rules & Hints for UIAI Style System

- All public types and properties must have `///` doc-comments explaining what and why.
- Use `any UIAIStyle` for protocol-typed values (Swift 6+ compatibility).
- Inject the current style at the app root with `.uiaiStyle(...)` and use `@Environment(\.uiaiStyle)` in all UIAI components.
- Support runtime switching of style and color scheme via `@AppStorage` and the settings panel.
- Register custom styles with `UIAIStyleRegistry.register(...)` for runtime selection.
- Never hard-code style IDs outside the registry; keep style logic modular and extensible.
- Use Swift Concurrency for async work; avoid legacy callbacks.
- Reference the [UIAI/MLXEngine SwiftUI Development & Troubleshooting Guide](UIAI_Development_Troubleshooting.md) for workspace/process issues.

---

*Last updated: 2024-06-26* 
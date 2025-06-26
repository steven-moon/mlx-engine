#if canImport(SwiftUI)
import SwiftUI

/// Supported color schemes for UIAI styles.
public enum UIAIColorScheme: String, CaseIterable, Codable, Sendable {
    case light, dark, vibrant, highContrast
}

/// Protocol for defining a UIAI style (theme).
///
/// Conform to this protocol to provide a consistent set of colors, fonts, and effects for UIAI components.
public protocol UIAIStyle: Hashable, Sendable {
    /// The color scheme this style represents.
    var colorScheme: UIAIColorScheme { get }
    /// The primary background color.
    var backgroundColor: Color { get }
    /// The primary foreground (text) color.
    var foregroundColor: Color { get }
    /// The accent color for highlights and controls.
    var accentColor: Color { get }
    /// The default corner radius for UI elements.
    var cornerRadius: CGFloat { get }
    /// The shadow style, if any.
    var shadow: ShadowStyle? { get }
    /// The default font for UI elements.
    var font: Font { get }
    // Extend as needed (borders, gradients, etc.)
}

/// A shadow style for UI elements.
public struct ShadowStyle: Hashable, Sendable {
    /// The shadow color.
    public let color: Color
    /// The blur radius.
    public let radius: CGFloat
    /// The horizontal offset.
    public let x: CGFloat
    /// The vertical offset.
    public let y: CGFloat
    /// Create a new shadow style.
    public init(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
}

/// Built-in style kinds for UIAI.
public enum UIAIStyleKind: String, CaseIterable, Codable {
    case liquidGlass, skeuomorphic, minimal
    // legacy: neumorphic, glassmorphic, dark, vibrant
}

/// Registry for built-in and custom UIAI styles.
public struct UIAIStyleRegistry {
    private static var customStyles: [String: any UIAIStyle] = [:]
    /// Returns a built-in style for the given kind and color scheme.
    public static func style(for kind: UIAIStyleKind, colorScheme: UIAIColorScheme) -> any UIAIStyle {
        switch kind {
        case .liquidGlass:
            return LiquidGlassStyle(colorScheme: colorScheme)
        case .skeuomorphic:
            return SkeuomorphicStyle(colorScheme: colorScheme)
        case .minimal:
            return MinimalStyle(colorScheme: colorScheme)
        }
    }
    /// Register a custom style for runtime selection.
    public static func register(_ style: any UIAIStyle, for key: String) {
        customStyles[key] = style
    }
    /// Retrieve a custom style by key.
    public static func customStyle(for key: String) -> (any UIAIStyle)? {
        customStyles[key]
    }
}

/// Neumorphic (Soft UI) style.
public struct NeumorphicStyle: UIAIStyle {
    public var colorScheme: UIAIColorScheme { .light }
    public var backgroundColor: Color { Color(.systemGray6) }
    public var foregroundColor: Color { Color.primary }
    public var accentColor: Color { Color.blue }
    public var cornerRadius: CGFloat { 16 }
    public var shadow: ShadowStyle? { ShadowStyle(color: .gray.opacity(0.2), radius: 8, x: 4, y: 4) }
    public var font: Font { .system(size: 17, weight: .regular) }
    public init() {}
}

/// Glassmorphic style.
public struct GlassmorphicStyle: UIAIStyle {
    public var colorScheme: UIAIColorScheme { .light }
    public var backgroundColor: Color { Color.white.opacity(0.2) }
    public var foregroundColor: Color { Color.primary }
    public var accentColor: Color { Color.purple }
    public var cornerRadius: CGFloat { 20 }
    public var shadow: ShadowStyle? { ShadowStyle(color: .black.opacity(0.1), radius: 12, x: 0, y: 2) }
    public var font: Font { .system(size: 17, weight: .medium) }
    public init() {}
}

/// Liquid Glass (Apple's new design system) style.
public struct LiquidGlassStyle: UIAIStyle {
    public let colorScheme: UIAIColorScheme
    public var backgroundColor: Color {
        switch colorScheme {
        case .light: return Color.white.opacity(0.7)
        case .dark: return Color.black.opacity(0.5)
        case .vibrant: return Color.blue.opacity(0.6)
        case .highContrast: return Color.white
        }
    }
    public var foregroundColor: Color {
        switch colorScheme {
        case .light, .vibrant: return Color.primary
        case .dark: return Color.white
        case .highContrast: return Color.black
        }
    }
    public var accentColor: Color {
        switch colorScheme {
        case .light: return Color.blue
        case .dark: return Color.cyan
        case .vibrant: return Color.purple
        case .highContrast: return Color.yellow
        }
    }
    public var cornerRadius: CGFloat { 20 }
    public var shadow: ShadowStyle? {
        ShadowStyle(color: .black.opacity(0.15), radius: 18, x: 0, y: 8)
    }
    public var font: Font { .system(size: 18, weight: .medium) }
    public init(colorScheme: UIAIColorScheme) { self.colorScheme = colorScheme }
}

/// Modern Skeuomorphic style.
public struct SkeuomorphicStyle: UIAIStyle {
    public let colorScheme: UIAIColorScheme
    public var backgroundColor: Color {
        switch colorScheme {
        case .light: return Color(.systemGray6)
        case .dark: return Color(.systemGray4)
        case .vibrant: return Color.orange.opacity(0.2)
        case .highContrast: return Color.white
        }
    }
    public var foregroundColor: Color {
        switch colorScheme {
        case .light, .vibrant: return Color.primary
        case .dark: return Color.white
        case .highContrast: return Color.black
        }
    }
    public var accentColor: Color {
        switch colorScheme {
        case .light: return Color.blue
        case .dark: return Color.green
        case .vibrant: return Color.pink
        case .highContrast: return Color.red
        }
    }
    public var cornerRadius: CGFloat { 14 }
    public var shadow: ShadowStyle? {
        ShadowStyle(color: .gray.opacity(0.3), radius: 10, x: 2, y: 4)
    }
    public var font: Font { .system(size: 17, weight: .regular) }
    public init(colorScheme: UIAIColorScheme) { self.colorScheme = colorScheme }
}

/// Minimalism with Bold Typography style.
public struct MinimalStyle: UIAIStyle {
    public let colorScheme: UIAIColorScheme
    public var backgroundColor: Color {
        switch colorScheme {
        case .light: return Color.white
        case .dark: return Color.black
        case .vibrant: return Color.purple.opacity(0.1)
        case .highContrast: return Color.white
        }
    }
    public var foregroundColor: Color {
        switch colorScheme {
        case .light, .vibrant: return Color.primary
        case .dark: return Color.white
        case .highContrast: return Color.black
        }
    }
    public var accentColor: Color {
        switch colorScheme {
        case .light: return Color.blue
        case .dark: return Color.cyan
        case .vibrant: return Color.pink
        case .highContrast: return Color.yellow
        }
    }
    public var cornerRadius: CGFloat { 12 }
    public var shadow: ShadowStyle? { nil }
    public var font: Font { .system(size: 17, weight: .bold) }
    public init(colorScheme: UIAIColorScheme) { self.colorScheme = colorScheme }
}

/// Dark mode style (legacy, for reference).
public struct DarkStyle: UIAIStyle {
    public var colorScheme: UIAIColorScheme { .dark }
    public var backgroundColor: Color { Color(.black) }
    public var foregroundColor: Color { Color(.white) }
    public var accentColor: Color { Color.green }
    public var cornerRadius: CGFloat { 12 }
    public var shadow: ShadowStyle? { ShadowStyle(color: .black.opacity(0.5), radius: 10, x: 0, y: 4) }
    public var font: Font { .system(size: 17, weight: .semibold) }
    public init() {}
}

/// Vibrant gradients & retro-futuristic style (legacy, for reference).
public struct VibrantStyle: UIAIStyle {
    public var colorScheme: UIAIColorScheme { .vibrant }
    public var backgroundColor: Color { Color.pink } // fallback for now
    public var foregroundColor: Color { Color.white }
    public var accentColor: Color { Color.yellow }
    public var cornerRadius: CGFloat { 18 }
    public var shadow: ShadowStyle? { ShadowStyle(color: .orange.opacity(0.3), radius: 14, x: 0, y: 6) }
    public var font: Font { .system(size: 17, weight: .bold) }
    public init() {}
}

// MARK: - SwiftUI Environment Integration

/// SwiftUI environment key for the current UIAI style.
public struct UIAIStyleEnvironmentKey: EnvironmentKey {
    public static let defaultValue: any UIAIStyle = MinimalStyle(colorScheme: .light)
}

public extension EnvironmentValues {
    /// The current UIAI style from the environment.
    var uiaiStyle: any UIAIStyle {
        get { self[UIAIStyleEnvironmentKey.self] }
        set { self[UIAIStyleEnvironmentKey.self] = newValue }
    }
}

public extension View {
    /// Inject a UIAI style into the environment for this view and its children.
    func uiaiStyle(_ style: any UIAIStyle) -> some View {
        environment(\.uiaiStyle, style)
    }
}
#endif 
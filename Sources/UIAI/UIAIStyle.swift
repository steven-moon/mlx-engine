import SwiftUI

/// Supported color schemes for UIAI styles.
public enum UIAIColorScheme: String, CaseIterable, Codable, Sendable {
    case light, dark, vibrant, highContrast
    /// Stormy Morning (Light)
    case stormyMorningLight
    /// Stormy Morning (Dark)
    case stormyMorningDark
    /// Peach Skyline (Light)
    case peachSkylineLight
    /// Peach Skyline (Dark)
    case peachSkylineDark
    /// Emerald Odyssey (Light)
    case emeraldOdysseyLight
    /// Emerald Odyssey (Dark)
    case emeraldOdysseyDark
    /// Purple Galaxy (Light)
    case purpleGalaxyLight
    /// Purple Galaxy (Dark)
    case purpleGalaxyDark
    /// Neon Jungle (Light)
    case neonJungleLight
    /// Neon Jungle (Dark)
    case neonJungleDark
    /// Cappuccino (Light)
    case cappuccinoLight
    /// Cappuccino (Dark)
    case cappuccinoDark

    /// All available color schemes, in user-friendly order.
    public static var allCases: [UIAIColorScheme] {
        return [
            .light, .dark, .vibrant, .highContrast,
            .stormyMorningLight, .stormyMorningDark,
            .peachSkylineLight, .peachSkylineDark,
            .emeraldOdysseyLight, .emeraldOdysseyDark,
            .purpleGalaxyLight, .purpleGalaxyDark,
            .neonJungleLight, .neonJungleDark,
            .cappuccinoLight, .cappuccinoDark
        ]
    }

    /// A user-friendly display name for the color scheme.
    public var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .vibrant: return "Vibrant"
        case .highContrast: return "High Contrast"
        case .stormyMorningLight: return "Stormy Morning (Light)"
        case .stormyMorningDark: return "Stormy Morning (Dark)"
        case .peachSkylineLight: return "Peach Skyline (Light)"
        case .peachSkylineDark: return "Peach Skyline (Dark)"
        case .emeraldOdysseyLight: return "Emerald Odyssey (Light)"
        case .emeraldOdysseyDark: return "Emerald Odyssey (Dark)"
        case .purpleGalaxyLight: return "Purple Galaxy (Light)"
        case .purpleGalaxyDark: return "Purple Galaxy (Dark)"
        case .neonJungleLight: return "Neon Jungle (Light)"
        case .neonJungleDark: return "Neon Jungle (Dark)"
        case .cappuccinoLight: return "Cappuccino (Light)"
        case .cappuccinoDark: return "Cappuccino (Dark)"
        }
    }
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
    /// The color for error states (e.g. failed progress, error banners).
    var errorColor: Color { get }
    /// The color for warning states (e.g. warning banners, progress bars).
    var warningColor: Color { get }
    /// The secondary foreground color (e.g. for less prominent text).
    var secondaryForegroundColor: Color { get }
    /// The logo or branding image for this style, if any.
    ///
    /// Use this to display a brand logo in onboarding, settings, or other UIAI components.
    var logo: Image? { get }
    /// The color for model type badges (e.g., LLM, VLM, Embedding, Diffusion).
    func badgeColor(for type: String) -> Color
    /// The color for quantization badges (e.g., 4bit, 8bit, fp16).
    func quantizationColor(for quant: String) -> Color
    /// The color for success states (e.g., completed, valid, positive feedback).
    var successColor: Color { get }
    /// The color for informational states (e.g., info banners, neutral status).
    var infoColor: Color { get }
    /// Returns a color for a given log level (debug, info, warning, error, critical).
    func logLevelColor(for level: String) -> Color
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
    public var errorColor: Color { Color.red }
    public var warningColor: Color { Color.orange }
    public var secondaryForegroundColor: Color { Color.secondary }
    public var logo: Image? { nil }
    public init() {}
    public func badgeColor(for type: String) -> Color {
        switch type.lowercased() {
        case "llm": return .blue
        case "vlm": return .orange
        case "embedding": return .green
        case "diffusion": return .pink
        default: return .gray
        }
    }
    public func quantizationColor(for quant: String) -> Color {
        switch quant.lowercased() {
        case "4bit", "8bit", "fp16", "fp32": return .purple
        default: return .gray
        }
    }
    public var successColor: Color { .green }
    public var infoColor: Color { .blue }
    public func logLevelColor(for level: String) -> Color {
        switch level.lowercased() {
        case "debug": return .gray
        case "info": return .blue
        case "warning": return .orange
        case "error": return .red
        case "critical": return .purple
        default: return .gray
        }
    }
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
    public var errorColor: Color { Color.red }
    public var warningColor: Color { Color.orange }
    public var secondaryForegroundColor: Color { Color.secondary }
    public var logo: Image? { nil }
    public init() {}
    public func badgeColor(for type: String) -> Color {
        switch type.lowercased() {
        case "llm": return .blue
        case "vlm": return .orange
        case "embedding": return .green
        case "diffusion": return .pink
        default: return .gray
        }
    }
    public func quantizationColor(for quant: String) -> Color {
        switch quant.lowercased() {
        case "4bit", "8bit", "fp16", "fp32": return .purple
        default: return .gray
        }
    }
    public var successColor: Color { .green }
    public var infoColor: Color { .blue }
    public func logLevelColor(for level: String) -> Color {
        switch level.lowercased() {
        case "debug": return .gray
        case "info": return .blue
        case "warning": return .orange
        case "error": return .red
        case "critical": return .purple
        default: return .gray
        }
    }
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
        case .stormyMorningLight, .stormyMorningDark, .peachSkylineLight, .peachSkylineDark, .emeraldOdysseyLight, .emeraldOdysseyDark, .purpleGalaxyLight, .purpleGalaxyDark, .neonJungleLight, .neonJungleDark, .cappuccinoLight, .cappuccinoDark:
            return Color.white.opacity(0.7)
        }
    }
    public var foregroundColor: Color {
        switch colorScheme {
        case .light, .vibrant: return Color.primary
        case .dark: return Color.white
        case .highContrast: return Color.black
        case .stormyMorningLight, .stormyMorningDark, .peachSkylineLight, .peachSkylineDark, .emeraldOdysseyLight, .emeraldOdysseyDark, .purpleGalaxyLight, .purpleGalaxyDark, .neonJungleLight, .neonJungleDark, .cappuccinoLight, .cappuccinoDark:
            return Color.primary
        }
    }
    public var accentColor: Color {
        switch colorScheme {
        case .light: return Color.blue
        case .dark: return Color.cyan
        case .vibrant: return Color.purple
        case .highContrast: return Color.yellow
        case .stormyMorningLight, .stormyMorningDark, .peachSkylineLight, .peachSkylineDark, .emeraldOdysseyLight, .emeraldOdysseyDark, .purpleGalaxyLight, .purpleGalaxyDark, .neonJungleLight, .neonJungleDark, .cappuccinoLight, .cappuccinoDark:
            return Color.blue
        }
    }
    public var cornerRadius: CGFloat { 20 }
    public var shadow: ShadowStyle? {
        ShadowStyle(color: .black.opacity(0.15), radius: 18, x: 0, y: 8)
    }
    public var font: Font { .system(size: 18, weight: .medium) }
    public var errorColor: Color { Color.red }
    public var warningColor: Color { Color.orange }
    public var secondaryForegroundColor: Color { Color.secondary }
    public var logo: Image? { nil }
    public init(colorScheme: UIAIColorScheme) { self.colorScheme = colorScheme }
    public func badgeColor(for type: String) -> Color {
        switch type.lowercased() {
        case "llm": return .blue
        case "vlm": return .orange
        case "embedding": return .green
        case "diffusion": return .pink
        default: return .gray
        }
    }
    public func quantizationColor(for quant: String) -> Color {
        switch quant.lowercased() {
        case "4bit", "8bit", "fp16", "fp32": return .purple
        default: return .gray
        }
    }
    public var successColor: Color { .green }
    public var infoColor: Color { .blue }
    public func logLevelColor(for level: String) -> Color {
        switch level.lowercased() {
        case "debug": return .gray
        case "info": return .blue
        case "warning": return .orange
        case "error": return .red
        case "critical": return .purple
        default: return .gray
        }
    }
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
        case .stormyMorningLight, .stormyMorningDark, .peachSkylineLight, .peachSkylineDark, .emeraldOdysseyLight, .emeraldOdysseyDark, .purpleGalaxyLight, .purpleGalaxyDark, .neonJungleLight, .neonJungleDark, .cappuccinoLight, .cappuccinoDark:
            return Color(.systemGray6)
        }
    }
    public var foregroundColor: Color {
        switch colorScheme {
        case .light, .vibrant: return Color.primary
        case .dark: return Color.white
        case .highContrast: return Color.black
        case .stormyMorningLight, .stormyMorningDark, .peachSkylineLight, .peachSkylineDark, .emeraldOdysseyLight, .emeraldOdysseyDark, .purpleGalaxyLight, .purpleGalaxyDark, .neonJungleLight, .neonJungleDark, .cappuccinoLight, .cappuccinoDark:
            return Color.primary
        }
    }
    public var accentColor: Color {
        switch colorScheme {
        case .light: return Color.blue
        case .dark: return Color.green
        case .vibrant: return Color.pink
        case .highContrast: return Color.red
        case .stormyMorningLight, .stormyMorningDark, .peachSkylineLight, .peachSkylineDark, .emeraldOdysseyLight, .emeraldOdysseyDark, .purpleGalaxyLight, .purpleGalaxyDark, .neonJungleLight, .neonJungleDark, .cappuccinoLight, .cappuccinoDark:
            return Color.blue
        }
    }
    public var cornerRadius: CGFloat { 14 }
    public var shadow: ShadowStyle? {
        ShadowStyle(color: .gray.opacity(0.3), radius: 10, x: 2, y: 4)
    }
    public var font: Font { .system(size: 17, weight: .regular) }
    public var errorColor: Color { Color.red }
    public var warningColor: Color { Color.orange }
    public var secondaryForegroundColor: Color { Color.secondary }
    public var logo: Image? { nil }
    public init(colorScheme: UIAIColorScheme) { self.colorScheme = colorScheme }
    public func badgeColor(for type: String) -> Color {
        switch type.lowercased() {
        case "llm": return .blue
        case "vlm": return .orange
        case "embedding": return .green
        case "diffusion": return .pink
        default: return .gray
        }
    }
    public func quantizationColor(for quant: String) -> Color {
        switch quant.lowercased() {
        case "4bit", "8bit", "fp16", "fp32": return .purple
        default: return .gray
        }
    }
    public var successColor: Color { .green }
    public var infoColor: Color { .blue }
    public func logLevelColor(for level: String) -> Color {
        switch level.lowercased() {
        case "debug": return .gray
        case "info": return .blue
        case "warning": return .orange
        case "error": return .red
        case "critical": return .purple
        default: return .gray
        }
    }
}

/// Minimalism with Bold Typography style.
public struct MinimalStyle: UIAIStyle {
    public let colorScheme: UIAIColorScheme
    public var backgroundColor: Color {
        switch colorScheme {
        case .stormyMorningLight: return Color(hex: "#F5F7FA")
        case .stormyMorningDark: return Color(hex: "#1A2636")
        case .peachSkylineLight: return Color(hex: "#FFF6F0")
        case .peachSkylineDark: return Color(hex: "#2D1E2F")
        case .emeraldOdysseyLight: return Color(hex: "#F3F9F4")
        case .emeraldOdysseyDark: return Color(hex: "#1B3B2F")
        case .purpleGalaxyLight: return Color(hex: "#F6F5FF")
        case .purpleGalaxyDark: return Color(hex: "#1F1B79")
        case .neonJungleLight: return Color(hex: "#F8FFF8")
        case .neonJungleDark: return Color(hex: "#181818")
        case .cappuccinoLight: return Color(hex: "#F7F3EF")
        case .cappuccinoDark: return Color(hex: "#3E2723")
        case .light: return Color.white
        case .dark: return Color.black
        case .vibrant: return Color.purple.opacity(0.1)
        case .highContrast: return Color.white
        }
    }
    public var foregroundColor: Color {
        switch colorScheme {
        case .stormyMorningLight: return Color(hex: "#1A2636")
        case .stormyMorningDark: return Color(hex: "#F5F7FA")
        case .peachSkylineLight: return Color(hex: "#2D1E2F")
        case .peachSkylineDark: return Color(hex: "#FFF6F0")
        case .emeraldOdysseyLight: return Color(hex: "#1B3B2F")
        case .emeraldOdysseyDark: return Color(hex: "#F3F9F4")
        case .purpleGalaxyLight: return Color(hex: "#2D1B79")
        case .purpleGalaxyDark: return Color(hex: "#F6F5FF")
        case .neonJungleLight: return Color(hex: "#1A1A1A")
        case .neonJungleDark: return Color(hex: "#F8FFF8")
        case .cappuccinoLight: return Color(hex: "#3E2723")
        case .cappuccinoDark: return Color(hex: "#F7F3EF")
        case .light, .vibrant: return Color.primary
        case .dark: return Color.white
        case .highContrast: return Color.black
        }
    }
    public var accentColor: Color {
        switch colorScheme {
        case .stormyMorningLight: return Color(hex: "#3B82F6")
        case .stormyMorningDark: return Color(hex: "#60A5FA")
        case .peachSkylineLight: return Color(hex: "#FF8C42")
        case .peachSkylineDark: return Color(hex: "#FFB385")
        case .emeraldOdysseyLight: return Color(hex: "#2DD4BF")
        case .emeraldOdysseyDark: return Color(hex: "#5EEAD4")
        case .purpleGalaxyLight: return Color(hex: "#8E69BF")
        case .purpleGalaxyDark: return Color(hex: "#8E69BF")
        case .neonJungleLight: return Color(hex: "#00FF85")
        case .neonJungleDark: return Color(hex: "#00FF85")
        case .cappuccinoLight: return Color(hex: "#BCAAA4")
        case .cappuccinoDark: return Color(hex: "#A1887F")
        case .light: return Color.blue
        case .dark: return Color.cyan
        case .vibrant: return Color.pink
        case .highContrast: return Color.yellow
        }
    }
    public var cornerRadius: CGFloat { 12 }
    public var shadow: ShadowStyle? { nil }
    public var font: Font {
        switch colorScheme {
        case .stormyMorningLight, .stormyMorningDark,
             .peachSkylineLight, .peachSkylineDark,
             .emeraldOdysseyLight, .emeraldOdysseyDark,
             .purpleGalaxyLight, .purpleGalaxyDark,
             .neonJungleLight, .neonJungleDark,
             .cappuccinoLight, .cappuccinoDark:
            return .system(size: 17, weight: .bold, design: .default)
        default:
            return .system(size: 17, weight: .bold)
        }
    }
    public var errorColor: Color {
        switch colorScheme {
        case .stormyMorningLight: return Color(hex: "#EF4444")
        case .stormyMorningDark: return Color(hex: "#F87171")
        case .peachSkylineLight: return Color(hex: "#E4572E")
        case .peachSkylineDark: return Color(hex: "#FF6F61")
        case .emeraldOdysseyLight: return Color(hex: "#F87171")
        case .emeraldOdysseyDark: return Color(hex: "#FCA5A5")
        case .purpleGalaxyLight: return Color(hex: "#E4576E")
        case .purpleGalaxyDark: return Color(hex: "#FF6F91")
        case .neonJungleLight, .neonJungleDark: return Color(hex: "#FF0099")
        case .cappuccinoLight: return Color(hex: "#D84315")
        case .cappuccinoDark: return Color(hex: "#FF7043")
        default: return Color.red
        }
    }
    public var warningColor: Color {
        switch colorScheme {
        case .stormyMorningLight: return Color(hex: "#F59E42")
        case .stormyMorningDark: return Color(hex: "#FBBF24")
        case .peachSkylineLight: return Color(hex: "#FFC857")
        case .peachSkylineDark: return Color(hex: "#FFD580")
        case .emeraldOdysseyLight: return Color(hex: "#FBBF24")
        case .emeraldOdysseyDark: return Color(hex: "#FDE68A")
        case .purpleGalaxyLight: return Color(hex: "#FFC857")
        case .purpleGalaxyDark: return Color(hex: "#FFD580")
        case .neonJungleLight, .neonJungleDark: return Color(hex: "#FFD600")
        case .cappuccinoLight: return Color(hex: "#FFB300")
        case .cappuccinoDark: return Color(hex: "#FFD54F")
        default: return Color.orange
        }
    }
    public var secondaryForegroundColor: Color {
        switch colorScheme {
        case .stormyMorningLight: return Color(hex: "#64748B")
        case .stormyMorningDark: return Color(hex: "#94A3B8")
        case .peachSkylineLight, .peachSkylineDark: return Color(hex: "#A78682")
        case .emeraldOdysseyLight: return Color(hex: "#6EE7B7")
        case .emeraldOdysseyDark: return Color(hex: "#34D399")
        case .purpleGalaxyLight: return Color(hex: "#B1A3E0")
        case .purpleGalaxyDark: return Color(hex: "#604FAB")
        case .neonJungleLight, .neonJungleDark: return Color(hex: "#1E90FF")
        case .cappuccinoLight: return Color(hex: "#A1887F")
        case .cappuccinoDark: return Color(hex: "#BCAAA4")
        default: return Color.secondary
        }
    }
    public var logo: Image? { nil }
    public init(colorScheme: UIAIColorScheme) { self.colorScheme = colorScheme }
    public func badgeColor(for type: String) -> Color {
        switch type.lowercased() {
        case "llm": return accentColor
        case "vlm":
            switch colorScheme {
            case .stormyMorningLight: return Color(hex: "#64748B")
            case .stormyMorningDark: return Color(hex: "#94A3B8")
            case .peachSkylineLight, .peachSkylineDark: return Color(hex: "#A78682")
            case .emeraldOdysseyLight: return Color(hex: "#6EE7B7")
            case .emeraldOdysseyDark: return Color(hex: "#34D399")
            case .purpleGalaxyLight: return Color(hex: "#B1A3E0")
            case .purpleGalaxyDark: return Color(hex: "#604FAB")
            case .neonJungleLight, .neonJungleDark: return Color(hex: "#1E90FF")
            case .cappuccinoLight: return Color(hex: "#A1887F")
            case .cappuccinoDark: return Color(hex: "#BCAAA4")
            default: return secondaryForegroundColor
            }
        case "embedding":
            switch colorScheme {
            case .stormyMorningLight: return Color(hex: "#22C55E")
            case .stormyMorningDark: return Color(hex: "#4ADE80")
            case .peachSkylineLight: return Color(hex: "#76B041")
            case .peachSkylineDark: return Color(hex: "#B7E778")
            case .emeraldOdysseyLight: return Color(hex: "#22C55E")
            case .emeraldOdysseyDark: return Color(hex: "#6EE7B7")
            case .purpleGalaxyLight: return Color(hex: "#76B041")
            case .purpleGalaxyDark: return Color(hex: "#B7E778")
            case .neonJungleLight, .neonJungleDark: return Color(hex: "#00FF85")
            case .cappuccinoLight: return Color(hex: "#43A047")
            case .cappuccinoDark: return Color(hex: "#81C784")
            default: return secondaryForegroundColor
            }
        case "diffusion":
            switch colorScheme {
            case .stormyMorningLight: return Color(hex: "#F59E42")
            case .stormyMorningDark: return Color(hex: "#FBBF24")
            case .peachSkylineLight: return Color(hex: "#FFC857")
            case .peachSkylineDark: return Color(hex: "#FFD580")
            case .emeraldOdysseyLight: return Color(hex: "#FBBF24")
            case .emeraldOdysseyDark: return Color(hex: "#FDE68A")
            case .purpleGalaxyLight: return Color(hex: "#FFC857")
            case .purpleGalaxyDark: return Color(hex: "#FFD580")
            case .neonJungleLight, .neonJungleDark: return Color(hex: "#FFD600")
            case .cappuccinoLight: return Color(hex: "#FFB300")
            case .cappuccinoDark: return Color(hex: "#FFD54F")
            default: return secondaryForegroundColor
            }
        default: return secondaryForegroundColor
        }
    }
    public func quantizationColor(for quant: String) -> Color {
        switch quant.lowercased() {
        case "4bit", "8bit", "fp16", "fp32": return accentColor
        default: return secondaryForegroundColor
        }
    }
    public var successColor: Color {
        switch colorScheme {
        case .stormyMorningLight: return Color(hex: "#22C55E")
        case .stormyMorningDark: return Color(hex: "#4ADE80")
        case .peachSkylineLight: return Color(hex: "#76B041")
        case .peachSkylineDark: return Color(hex: "#B7E778")
        case .emeraldOdysseyLight: return Color(hex: "#22C55E")
        case .emeraldOdysseyDark: return Color(hex: "#6EE7B7")
        case .purpleGalaxyLight: return Color(hex: "#76B041")
        case .purpleGalaxyDark: return Color(hex: "#B7E778")
        case .neonJungleLight, .neonJungleDark: return Color(hex: "#00FF85")
        case .cappuccinoLight: return Color(hex: "#43A047")
        case .cappuccinoDark: return Color(hex: "#81C784")
        default: return Color.green
        }
    }
    public var infoColor: Color {
        switch colorScheme {
        case .stormyMorningLight, .stormyMorningDark: return accentColor
        case .peachSkylineLight, .peachSkylineDark: return accentColor
        case .emeraldOdysseyLight, .emeraldOdysseyDark: return accentColor
        case .purpleGalaxyLight, .purpleGalaxyDark: return accentColor
        case .neonJungleLight, .neonJungleDark: return accentColor
        case .cappuccinoLight, .cappuccinoDark: return accentColor
        default: return Color.blue
        }
    }
    public func logLevelColor(for level: String) -> Color {
        switch level.lowercased() {
        case "debug": return secondaryForegroundColor
        case "info": return accentColor
        case "warning": return warningColor
        case "error": return errorColor
        case "critical": return Color.purple
        default: return secondaryForegroundColor
        }
    }
}

// Helper to create Color from hex
fileprivate extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
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
    public var errorColor: Color { Color.red }
    public var warningColor: Color { Color.orange }
    public var secondaryForegroundColor: Color { Color.secondary }
    public var logo: Image? { nil }
    public init() {}
    public func badgeColor(for type: String) -> Color {
        switch type.lowercased() {
        case "llm": return .blue
        case "vlm": return .orange
        case "embedding": return .green
        case "diffusion": return .pink
        default: return .gray
        }
    }
    public func quantizationColor(for quant: String) -> Color {
        switch quant.lowercased() {
        case "4bit", "8bit", "fp16", "fp32": return .purple
        default: return .gray
        }
    }
    public var successColor: Color { .green }
    public var infoColor: Color { .blue }
    public func logLevelColor(for level: String) -> Color {
        switch level.lowercased() {
        case "debug": return .gray
        case "info": return .blue
        case "warning": return .orange
        case "error": return .red
        case "critical": return .purple
        default: return .gray
        }
    }
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
    public var errorColor: Color { Color.red }
    public var warningColor: Color { Color.orange }
    public var secondaryForegroundColor: Color { Color.secondary }
    public var logo: Image? { nil }
    public init() {}
    public func badgeColor(for type: String) -> Color {
        switch type.lowercased() {
        case "llm": return .blue
        case "vlm": return .orange
        case "embedding": return .green
        case "diffusion": return .pink
        default: return .gray
        }
    }
    public func quantizationColor(for quant: String) -> Color {
        switch quant.lowercased() {
        case "4bit", "8bit", "fp16", "fp32": return .purple
        default: return .gray
        }
    }
    public var successColor: Color { .green }
    public var infoColor: Color { .blue }
    public func logLevelColor(for level: String) -> Color {
        switch level.lowercased() {
        case "debug": return .gray
        case "info": return .blue
        case "warning": return .orange
        case "error": return .red
        case "critical": return .purple
        default: return .gray
        }
    }
}

/// Example custom style demonstrating branding asset support.
///
/// - Uses a placeholder system image as the logo.
public struct BrandXStyle: UIAIStyle {
    public var colorScheme: UIAIColorScheme { .light }
    public var backgroundColor: Color { Color(.systemIndigo).opacity(0.1) }
    public var foregroundColor: Color { Color(.systemIndigo) }
    public var accentColor: Color { Color.orange }
    public var cornerRadius: CGFloat { 18 }
    public var shadow: ShadowStyle? { ShadowStyle(color: .orange.opacity(0.2), radius: 10, x: 2, y: 4) }
    public var font: Font { .system(size: 18, weight: .semibold) }
    public var errorColor: Color { Color.red }
    public var warningColor: Color { Color.orange }
    public var secondaryForegroundColor: Color { Color.secondary }
    public var logo: Image? { Image(systemName: "bolt.fill") }
    public init() {}
    public func badgeColor(for type: String) -> Color {
        switch type.lowercased() {
        case "llm": return .blue
        case "vlm": return .orange
        case "embedding": return .green
        case "diffusion": return .pink
        default: return .gray
        }
    }
    public func quantizationColor(for quant: String) -> Color {
        switch quant.lowercased() {
        case "4bit", "8bit", "fp16", "fp32": return .purple
        default: return .gray
        }
    }
    public var successColor: Color { .green }
    public var infoColor: Color { .blue }
    public func logLevelColor(for level: String) -> Color {
        switch level.lowercased() {
        case "debug": return .gray
        case "info": return .blue
        case "warning": return .orange
        case "error": return .red
        case "critical": return .purple
        default: return .gray
        }
    }
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

public extension UIAIStyle {
    func badgeColor(for type: String) -> Color {
        switch type.lowercased() {
        case "llm": return .blue
        case "vlm": return .orange
        case "embedding": return .green
        case "diffusion": return .pink
        default: return .gray
        }
    }
    func quantizationColor(for quant: String) -> Color {
        switch quant.lowercased() {
        case "4bit", "8bit", "fp16", "fp32": return .purple
        default: return .gray
        }
    }
} 
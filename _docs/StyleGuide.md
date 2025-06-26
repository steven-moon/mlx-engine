# UIAI Style & Branding Guide

This guide documents the style system, color palettes, and branding options for the MLXEngine UIAI Swift library.

## Overview

UIAI supports a flexible, extensible style system for theming and branding. Styles are defined by the `UIAIStyle` protocol and can be previewed interactively in the app's **Style Gallery** (see Settings > Open Style Gallery).

---

## Built-in Styles & Color Schemes

| Style Kind      | Color Scheme           | Background      | Foreground      | Accent         |
|-----------------|-----------------------|-----------------|-----------------|---------------|
| Minimal         | Stormy Morning Light  | #F5F7FA         | #1A2636         | #3B82F6        |
| Minimal         | Stormy Morning Dark   | #1A2636         | #F5F7FA         | #60A5FA        |
| Minimal         | Peach Skyline Light   | #FFF6F0         | #2D1E2F         | #FF8C42        |
| Minimal         | Peach Skyline Dark    | #2D1E2F         | #FFF6F0         | #FFB385        |
| Minimal         | Emerald Odyssey Light | #F3F9F4         | #1B3B2F         | #2DD4BF        |
| Minimal         | Emerald Odyssey Dark  | #1B3B2F         | #F3F9F4         | #5EEAD4        |
| Minimal         | Purple Galaxy Light   | #F6F5FF         | #2D1B79         | #8E69BF        |
| Minimal         | Purple Galaxy Dark    | #1F1B79         | #F6F5FF         | #8E69BF        |
| Minimal         | Neon Jungle Light     | #F8FFF8         | #1A1A1A         | #00FF85        |
| Minimal         | Neon Jungle Dark      | #181818         | #F8FFF8         | #00FF85        |
| Minimal         | Cappuccino Light      | #F7F3EF         | #3E2723         | #BCAAA4        |
| Minimal         | Cappuccino Dark       | #3E2723         | #F7F3EF         | #A1887F        |
| Minimal         | Light                 | #FFFFFF         | #000000         | #3B82F6        |
| Minimal         | Dark                  | #000000         | #FFFFFF         | #60A5FA        |
| ...             | ...                   | ...             | ...             | ...           |

*See the source code for the full palette and all style kinds (Minimal, LiquidGlass, Skeuomorphic, etc.).*

---

## Adding Screenshots

To add screenshots of each style:
1. Open the app and go to Settings > Open Style Gallery.
2. Take screenshots of the desired style and color scheme combinations.
3. Add the images to this document using standard markdown image syntax:
   ```
   ![Minimal Stormy Morning Light](images/minimal-stormy-morning-light.png)
   ```

---

## Custom Styles & Branding

You can add your own styles and branding by conforming to `UIAIStyle`:

```swift
struct MyBrandStyle: UIAIStyle {
    // Implement all required properties (colors, font, logo, etc.)
    var logo: Image? { Image("my-logo") }
    // ...
}
```

Register your style at runtime:
```swift
UIAIStyleRegistry.register(MyBrandStyle(), for: "myBrand")
```

Retrieve and use your style:
```swift
if let style = UIAIStyleRegistry.customStyle(for: "myBrand") {
    // Apply with .uiaiStyle(style)
}
```

---

## Interactive Preview

For a live, interactive preview of all styles and palettes, use the **Style Gallery** in the app (Settings > Open Style Gallery).

---

*Last updated: 2025-06-27* 
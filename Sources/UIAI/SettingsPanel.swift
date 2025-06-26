//
//  SettingsPanel.swift
//  UIAI
//
//  Created for MLXEngine Shared SwiftUI Library
//
//  A cross-platform SwiftUI settings panel for model, generation, and app preferences.
//  This is a stub for future expansion and integration with MLXEngine and app settings APIs.
//

import SwiftUI
import MLXEngine

/// A SwiftUI settings panel for model, generation, and app preferences.
///
/// - Designed for iOS, macOS, visionOS, tvOS, and watchOS.
/// - Use this panel to present unified settings for MLXEngine-powered apps.
/// - Customize with additional controls as needed.
public struct SettingsPanel: View {
    /// Whether logging is enabled.
    @AppStorage("UIAI.enableLogging") private var enableLogging: Bool = true
    /// The maximum number of tokens for generation.
    @AppStorage("UIAI.maxTokens") private var maxTokens: Double = 2048
    /// The selected model name.
    @AppStorage("UIAI.selectedModel") private var selectedModel: String = "Qwen 0.5B Chat"
    /// The selected style kind (raw value).
    @AppStorage("selectedUIAIStyleKind") private var selectedStyleKindRaw: String = UIAIStyleKind.minimal.rawValue
    /// The selected color scheme (raw value).
    @AppStorage("selectedUIAIColorScheme") private var selectedColorSchemeRaw: String = UIAIColorScheme.light.rawValue
    private let availableModels: [String] = ["Qwen 0.5B Chat", "Llama 3B", "Phi-2", "Custom..."]
    @State private var showResetConfirmation: Bool = false
    
    private var selectedStyleKind: UIAIStyleKind {
        UIAIStyleKind(rawValue: selectedStyleKindRaw) ?? .minimal
    }
    private var selectedColorScheme: UIAIColorScheme {
        UIAIColorScheme(rawValue: selectedColorSchemeRaw) ?? .light
    }
    private var currentStyle: any UIAIStyle {
        UIAIStyleRegistry.style(for: selectedStyleKind, colorScheme: selectedColorScheme)
    }
    
    public init() {}
    
    public var body: some View {
        #if os(iOS) || os(macOS) || os(visionOS)
        VStack(spacing: 0) {
            OnboardingBanner(title: "Welcome to Settings!", message: "Configure your model, generation, and app preferences here.")
            Form {
                Section("Model") {
                    Picker("Model", selection: $selectedModel) {
                        ForEach(availableModels, id: \ .self) { model in
                            Text(model)
                        }
                    }
                }
                Section("Generation") {
                    HStack {
                        Text("Max Tokens")
                        Slider(value: $maxTokens, in: 256...8192, step: 256)
                        Text("\(Int(maxTokens))")
                            .frame(width: 50, alignment: .trailing)
                    }
                }
                Section(header: Text("Style")) {
                    Picker("UI Style", selection: $selectedStyleKindRaw) {
                        ForEach(UIAIStyleKind.allCases, id: \.rawValue) { kind in
                            Text(kind.rawValue.capitalized).tag(kind.rawValue)
                        }
                    }
                    Picker("Color Scheme", selection: $selectedColorSchemeRaw) {
                        ForEach(UIAIColorScheme.allCases, id: \.rawValue) { scheme in
                            Text(scheme.rawValue.capitalized).tag(scheme.rawValue)
                        }
                    }
                }
                Section("App Preferences") {
                    Toggle("Enable Logging", isOn: $enableLogging)
                }
                Section {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Reset Settings?", isPresented: $showResetConfirmation) {
                Button("Reset", role: .destructive) { resetSettings() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will restore all settings to their default values.")
            }
        }
        #else
        Text("Settings panel is not yet available on this platform.")
            .foregroundColor(.secondary)
        #endif
    }
    
    private func resetSettings() {
        enableLogging = true
        maxTokens = 2048
        selectedModel = "Qwen 0.5B Chat"
        selectedStyleKindRaw = UIAIStyleKind.minimal.rawValue
        selectedColorSchemeRaw = UIAIColorScheme.light.rawValue
    }
}

#if DEBUG
#Preview {
    SettingsPanel()
        .frame(width: 400, height: 400)
        .previewLayout(.sizeThatFits)
}
#endif

/*
# How to Add a Custom UIAI Style

1. Define your style by conforming to `UIAIStyle`:

```swift
struct MyCustomStyle: UIAIStyle {
    // Implement all required properties
}
```

2. Register your style at runtime:

```swift
UIAIStyleRegistry.register(MyCustomStyle(), for: "myCustomStyle")
```

3. Retrieve and use your style:

```swift
if let style = UIAIStyleRegistry.customStyle(for: "myCustomStyle") {
    // Apply with .uiaiStyle(style)
}
```
*/ 
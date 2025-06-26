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
import Foundation
import os

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
    /// Bindings for style kind and color scheme.
    @Binding var selectedStyleKindRaw: String
    @Binding var selectedColorSchemeRaw: String
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
    
    private let settingsLogger = Logger(subsystem: "com.clevercoding.MLXChatApp", category: "UIAISettings")
    
    public init(selectedStyleKindRaw: Binding<String>, selectedColorSchemeRaw: Binding<String>) {
        self._selectedStyleKindRaw = selectedStyleKindRaw
        self._selectedColorSchemeRaw = selectedColorSchemeRaw
    }
    
    public var body: some View {
        #if os(iOS) || os(macOS) || os(visionOS)
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Onboarding Banner
                OnboardingBanner(title: "Welcome to Settings!", message: "Configure your model, generation, and app preferences here.")
                    .padding(.bottom, 8)

                // Model Section
                Text("MODEL")
                    .font(.caption)
                    .foregroundColor(currentStyle.secondaryForegroundColor)
                    .padding(.horizontal)
                HStack {
                    Text("Model")
                        .foregroundColor(currentStyle.foregroundColor)
                    Spacer()
                    Picker("Model", selection: $selectedModel) {
                        ForEach(availableModels, id: \.self) { model in
                            Text(model)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                .padding()
                .background(currentStyle.backgroundColor.opacity(0.7))
                .cornerRadius(12)
                .padding(.horizontal)

                // Generation Section
                Text("GENERATION")
                    .font(.caption)
                    .foregroundColor(currentStyle.secondaryForegroundColor)
                    .padding(.horizontal)
                HStack {
                    Text("Max Tokens")
                        .foregroundColor(currentStyle.foregroundColor)
                    Slider(value: $maxTokens, in: 256...8192, step: 256)
                    Text("\(Int(maxTokens))")
                        .foregroundColor(currentStyle.secondaryForegroundColor)
                }
                .padding()
                .background(currentStyle.backgroundColor.opacity(0.7))
                .cornerRadius(12)
                .padding(.horizontal)

                // Style Section
                Text("STYLE")
                    .font(.caption)
                    .foregroundColor(currentStyle.secondaryForegroundColor)
                    .padding(.horizontal)
                HStack {
                    Text("UI Style")
                        .foregroundColor(currentStyle.foregroundColor)
                    Spacer()
                    Picker("UI Style", selection: $selectedStyleKindRaw) {
                        ForEach(UIAIStyleKind.allCases, id: \.self) { kind in
                            Text(kind.rawValue.capitalized)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: selectedStyleKindRaw) { newValue in
                        print("[SettingsPanel] Style kind changed to \(newValue)")
                    }
                }
                .padding()
                .background(currentStyle.backgroundColor.opacity(0.7))
                .cornerRadius(12)
                .padding(.horizontal)

                // Color Scheme Section
                Text("COLOR SCHEME")
                    .font(.caption)
                    .foregroundColor(currentStyle.secondaryForegroundColor)
                    .padding(.horizontal)
                HStack {
                    Text("Color Scheme")
                        .foregroundColor(currentStyle.foregroundColor)
                    Spacer()
                    Picker("Color Scheme", selection: $selectedColorSchemeRaw) {
                        ForEach(UIAIColorScheme.allCases, id: \.self) { scheme in
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(MinimalStyle(colorScheme: scheme).backgroundColor)
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        Circle()
                                            .stroke(MinimalStyle(colorScheme: scheme).accentColor, lineWidth: 2)
                                    )
                                Text(scheme.displayName)
                            }
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onTapGesture {
                        settingsLogger.info("Picker tapped")
                    }
                    .onChange(of: selectedColorSchemeRaw) { newValue in
                        settingsLogger.info("Color scheme changed to: \(newValue)")
                    }
                }
                .padding()
                .background(currentStyle.backgroundColor.opacity(0.7))
                .cornerRadius(12)
                .padding(.horizontal)

                // App Preferences Section
                Text("APP PREFERENCES")
                    .font(.caption)
                    .foregroundColor(currentStyle.secondaryForegroundColor)
                    .padding(.horizontal)
                Toggle("Enable Logging", isOn: $enableLogging)

                // Reset Section
                Section {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                    }
                }
            }
            .padding(.vertical, 24)
        }
        .background(currentStyle.backgroundColor.ignoresSafeArea())
        .alert("Reset Settings?", isPresented: $showResetConfirmation) {
            Button("Reset", role: .destructive) { resetSettings() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will restore all settings to their default values.")
        }
        #else
        Text("Settings panel is not yet available on this platform.")
            .foregroundColor(currentStyle.secondaryForegroundColor)
        #endif
    }
    
    private func resetSettings() {
        enableLogging = true
        maxTokens = 2048
        selectedModel = "Qwen 0.5B Chat"
        selectedStyleKindRaw = UIAIStyleKind.minimal.rawValue
        selectedColorSchemeRaw = UIAIColorScheme.light.rawValue
        print("[SettingsPanel] Settings reset to defaults")
    }
}

#if DEBUG
#Preview {
    ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 24)], spacing: 24) {
            ForEach(UIAIColorScheme.allCases, id: \.self) { scheme in
                VStack(spacing: 8) {
                    Text(scheme.displayName)
                        .font(.headline)
                    SettingsPanel(selectedStyleKindRaw: .constant(UIAIStyleKind.minimal.rawValue), selectedColorSchemeRaw: .constant(UIAIColorScheme.light.rawValue))
                        .environment(\ .uiaiStyle, MinimalStyle(colorScheme: scheme))
                        .frame(width: 340, height: 420)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(radius: 4)
                }
                .padding()
            }
        }
        .padding()
    }
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
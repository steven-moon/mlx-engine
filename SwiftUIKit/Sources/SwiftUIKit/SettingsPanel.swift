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
    @State private var showErrorPreview: Bool = true
    @State private var showStyleGallery: Bool = false
    private let logger = Logger(subsystem: "SwiftUIKitDemo", category: "SettingsPanel")
    
    private var selectedStyleKind: UIAIStyleKind {
        UIAIStyleKind(rawValue: selectedStyleKindRaw) ?? .minimal
    }
    private var selectedColorScheme: UIAIColorScheme {
        UIAIColorScheme(rawValue: selectedColorSchemeRaw) ?? .light
    }
    private var currentStyle: any UIAIStyle {
        UIAIStyleRegistry.style(for: selectedStyleKind, colorScheme: selectedColorScheme)
    }
    
    public init(selectedStyleKindRaw: Binding<String>, selectedColorSchemeRaw: Binding<String>) {
        self._selectedStyleKindRaw = selectedStyleKindRaw
        self._selectedColorSchemeRaw = selectedColorSchemeRaw
        print("[SettingsPanel] init: styleKindRaw=\(selectedStyleKindRaw.wrappedValue), colorSchemeRaw=\(selectedColorSchemeRaw.wrappedValue)")
        logger.info("[SettingsPanel] init: styleKindRaw=\(selectedStyleKindRaw.wrappedValue), colorSchemeRaw=\(selectedColorSchemeRaw.wrappedValue)")
    }
    
    public var body: some View {
        #if os(iOS) || os(macOS) || os(visionOS)
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Logo Branding
                HStack {
                    Spacer()
                    if let logo = currentStyle.logo {
                        logo
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                            .padding(.bottom, 4)
                    } else {
                        Image(systemName: "sparkles")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundColor(currentStyle.accentColor)
                            .padding(.bottom, 4)
                    }
                    Spacer()
                }
                // Live Style Preview
                Text("Live Style Preview")
                    .font(.caption)
                    .foregroundColor(currentStyle.secondaryForegroundColor)
                    .padding(.bottom, 2)
                VStack(spacing: 12) {
                    ModelCardView(model: .init(id: "preview", name: "Preview Model", description: "A preview model.", statusMessage: "Ready", statusColor: currentStyle.successColor))
                        .frame(width: 220, height: 120)
                        .uiaiStyle(currentStyle)
                    ErrorBanner(message: "This is a preview error banner.", style: .error, isPresented: $showErrorPreview)
                        .uiaiStyle(currentStyle)
                }
                .padding(.vertical, 8)
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
                // Style Gallery Button
                Button {
                    showStyleGallery = true
                } label: {
                    Label("Open Style Gallery", systemImage: "paintpalette")
                        .font(.headline)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 12)
                .padding(.horizontal)
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
        .sheet(isPresented: $showStyleGallery) {
            StyleGallery()
        }
        .onAppear {
            print("[SettingsPanel] body: styleKindRaw=\(selectedStyleKindRaw), colorSchemeRaw=\(selectedColorSchemeRaw)")
            logger.info("[SettingsPanel] body: styleKindRaw=\(selectedStyleKindRaw), colorSchemeRaw=\(selectedColorSchemeRaw)")
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
struct SettingsPanel_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 24)], spacing: 24) {
                SettingsPanel(selectedStyleKindRaw: .constant(UIAIStyleKind.minimal.rawValue), selectedColorSchemeRaw: .constant(UIAIColorScheme.light.rawValue))
                    .uiaiStyle(MinimalStyle(colorScheme: .light))
            }
            .padding()
        }
    }
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
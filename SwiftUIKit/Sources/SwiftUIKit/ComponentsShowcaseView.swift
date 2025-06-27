import SwiftUI
import Foundation

public struct ComponentsShowcaseView: View {
    @Environment(\.uiaiStyle) private var uiaiStyle: any UIAIStyle
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 32) {
                    headerSection
                    cardsSection
                    buttonsSection
                    inputsSection
                    progressSection
                    bannersSection
                    utilitiesSection
                    feedbackSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
            }
            .background(uiaiStyle.backgroundColor.ignoresSafeArea())
            .navigationTitle("Components")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Text("SwiftUIKit Components")
                .font(.title.bold())
                .foregroundColor(uiaiStyle.foregroundColor)
            
            Text("Universal UI components that adapt to your app's style")
                .font(.subheadline)
                .foregroundColor(uiaiStyle.foregroundColor.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 16)
    }
    
    private var cardsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Cards & Containers")
            
            VStack(spacing: 12) {
                // Model Card Example
                ModelCardView(model: .init(
                    id: "example-1",
                    name: "Example Model",
                    description: "A sample model to demonstrate card styling",
                    parameters: "1.2B",
                    quantization: "4bit",
                    imageURL: nil,
                    isDownloaded: true,
                    isDownloading: false,
                    downloadProgress: nil,
                    statusMessage: "Ready to use"
                ))
                
                // Simple Card
                VStack(alignment: .leading, spacing: 8) {
                    Text("Simple Card")
                        .font(.headline)
                        .foregroundColor(uiaiStyle.foregroundColor)
                    
                    Text("This is a basic card component that adapts to your selected style and color scheme.")
                        .font(.body)
                        .foregroundColor(uiaiStyle.foregroundColor.opacity(0.8))
                }
                .padding(16)
                .background(uiaiStyle.backgroundColor)
                .cornerRadius(uiaiStyle.cornerRadius)
                .shadow(color: uiaiStyle.shadow?.color ?? .clear, radius: uiaiStyle.shadow?.radius ?? 0, x: uiaiStyle.shadow?.x ?? 0, y: uiaiStyle.shadow?.y ?? 0)
            }
        }
    }
    
    private var buttonsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Buttons & Controls")
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button("Primary") {
                        // Action
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(uiaiStyle.accentColor)
                    
                    Button("Secondary") {
                        // Action
                    }
                    .buttonStyle(.bordered)
                    .foregroundColor(uiaiStyle.accentColor)
                }
                
                HStack(spacing: 12) {
                    Button("Small") {
                        // Action
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .foregroundColor(uiaiStyle.accentColor)
                    
                    Button("Large") {
                        // Action
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(uiaiStyle.accentColor)
                }
                
                // Custom styled button
                Button(action: {
                    // Action
                }) {
                    HStack {
                        Image(systemName: "star.fill")
                        Text("Custom Button")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(uiaiStyle.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(uiaiStyle.cornerRadius)
                }
            }
        }
    }
    
    private var inputsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Inputs & Forms")
            
            VStack(spacing: 12) {
                TextField("Enter text here...", text: .constant(""))
                    .textFieldStyle(.roundedBorder)
                    .foregroundColor(uiaiStyle.foregroundColor)
                
                TextField("Search...", text: .constant(""))
                    .textFieldStyle(.roundedBorder)
                    .overlay(
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(uiaiStyle.foregroundColor.opacity(0.5))
                            Spacer()
                        }
                        .padding(.leading, 8)
                    )
                
                // Chat Input Example
                ChatInputView(text: .constant(""), onSend: {})
            }
        }
    }
    
    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Progress & Loading")
            
            VStack(spacing: 12) {
                ProgressView(value: 0.7)
                    .progressViewStyle(.linear)
                    .tint(uiaiStyle.accentColor)
                
                TokenProgressBar(progress: 0.65, label: "Processing tokens...", style: .normal)
                
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(uiaiStyle.foregroundColor.opacity(0.7))
                }
            }
        }
    }
    
    private var bannersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Banners & Feedback")
            
            VStack(spacing: 12) {
                ErrorBanner(message: "This is an example error message", isPresented: .constant(true))
                
                OnboardingBanner(
                    title: "Welcome to SwiftUIKit",
                    message: "This library provides universal UI components that adapt to your app's style."
                )
                
                ModelSuggestionBanner(
                    modelName: "Minimal Style",
                    modelDescription: "Try the Minimal style for a clean, modern look.",
                    onSelect: {}
                )
            }
        }
    }
    
    private var utilitiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Utilities")
            
            VStack(spacing: 12) {
                // Async Image Example
                AsyncImageView(
                    url: URL(string: "https://picsum.photos/200/100"),
                    placeholder: Image(systemName: "photo")
                )
                .frame(height: 100)
                .cornerRadius(uiaiStyle.cornerRadius)
                
                // Debug Panel Example
                DisclosureGroup("Debug Information") {
                    DebugPanel()
                        .frame(height: 200)
                }
                .foregroundColor(uiaiStyle.foregroundColor)
            }
        }
    }
    
    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Feedback & Notifications")
            ToastDemo()
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.title2.bold())
            .foregroundColor(uiaiStyle.foregroundColor)
            .padding(.top, 8)
    }
}

private struct ToastDemo: View {
    @Environment(\.uiaiStyle) private var uiaiStyle: any UIAIStyle
    @State private var showToast = false
    
    var body: some View {
        VStack(spacing: 12) {
            Button("Show Toast") {
                showToast = true
            }
            .buttonStyle(.borderedProminent)
            .toast(
                isPresented: $showToast,
                message: "This is a universal toast!",
                icon: "bell.fill",
                actionTitle: "Undo",
                action: { print("Undo tapped") },
                style: uiaiStyle,
                duration: 2.5
            )
        }
    }
}

#if DEBUG
#Preview {
    ComponentsShowcaseView()
        .uiaiStyle(MinimalStyle(colorScheme: .light))
}
#endif 
import SwiftUI
import Foundation

public struct AppearanceSettingsView: View {
    @Binding var selectedStyleKindRaw: String
    @Binding var selectedColorSchemeRaw: String
    @Environment(\.dismiss) private var dismiss
    
    private var selectedStyleKind: UIAIStyleKind {
        UIAIStyleKind(rawValue: selectedStyleKindRaw) ?? .minimal
    }
    private var selectedColorScheme: UIAIColorScheme {
        UIAIColorScheme(rawValue: selectedColorSchemeRaw) ?? .light
    }
    private var currentStyle: any UIAIStyle {
        UIAIStyleRegistry.style(for: selectedStyleKind, colorScheme: selectedColorScheme)
    }
    
    @State private var tempStyleKind: UIAIStyleKind? = nil
    @State private var tempColorScheme: UIAIColorScheme? = nil
    
    private let styleKinds: [UIAIStyleKind] = UIAIStyleKind.allCases
    private let colorSchemes: [UIAIColorScheme] = UIAIColorScheme.allCases
    
    public init(selectedStyleKindRaw: Binding<String>, selectedColorSchemeRaw: Binding<String>) {
        self._selectedStyleKindRaw = selectedStyleKindRaw
        self._selectedColorSchemeRaw = selectedColorSchemeRaw
    }
    
    public var body: some View {
        VStack(spacing: 32) {
            Text("Appearance")
                .font(.title.bold())
                .padding(.top, 16)
            stylePicker
            colorSchemePicker
            previewCard
            Spacer()
            actionButtons
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .onAppear {
            tempStyleKind = selectedStyleKind
            tempColorScheme = selectedColorScheme
        }
    }
    
    private var stylePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(styleKinds, id: \.self) { kind in
                    Button(action: {
                        tempStyleKind = kind
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: kind.iconName)
                                .foregroundColor(kind == (tempStyleKind ?? selectedStyleKind) ? .white : .primary)
                            Text(kind.displayName)
                                .font(.headline)
                                .foregroundColor(kind == (tempStyleKind ?? selectedStyleKind) ? .white : .primary)
                        }
                        .padding(.vertical, 10)
                        .padding(.horizontal, 18)
                        .background(kind == (tempStyleKind ?? selectedStyleKind) ? Color.accentColor : Color(.systemGray6))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(kind == (tempStyleKind ?? selectedStyleKind) ? Color.accentColor : Color.clear, lineWidth: 2)
                        )
                        .shadow(color: kind == (tempStyleKind ?? selectedStyleKind) ? Color.accentColor.opacity(0.2) : .clear, radius: 4, x: 0, y: 2)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var colorSchemePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(colorSchemes, id: \.self) { scheme in
                    Button(action: {
                        tempColorScheme = scheme
                    }) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(UIAIStyleRegistry.style(for: tempStyleKind ?? selectedStyleKind, colorScheme: scheme).accentColor)
                                .frame(width: 28, height: 28)
                                .overlay(
                                    Circle()
                                        .stroke(scheme == (tempColorScheme ?? selectedColorScheme) ? Color.accentColor : Color.clear, lineWidth: 3)
                                )
                            Text(scheme.displayName)
                                .font(.subheadline)
                                .foregroundColor(scheme == (tempColorScheme ?? selectedColorScheme) ? .accentColor : .primary)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(scheme == (tempColorScheme ?? selectedColorScheme) ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
                        .cornerRadius(14)
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var previewCard: some View {
        VStack(spacing: 16) {
            Text((tempStyleKind ?? selectedStyleKind).displayName)
                .font(.title2.bold())
                .foregroundColor(currentStyle.accentColor)
            ModelCardView(model: .init(
                id: "preview",
                name: "Preview Model",
                description: "A preview model for style and color.",
                parameters: "1.2B",
                quantization: "4bit",
                imageURL: nil,
                isDownloaded: false,
                isDownloading: false,
                downloadProgress: nil,
                statusMessage: "Preview",
                statusColor: currentStyle.accentColor,
                architecture: "llama"
            ))
            ErrorBanner(message: "Preview error banner.", style: .error, isPresented: .constant(true))
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(28)
        .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 8)
        .padding(.horizontal, 16)
    }
    
    private var actionButtons: some View {
        HStack {
            Button(action: {
                tempStyleKind = nil
                tempColorScheme = nil
                selectedStyleKindRaw = UIAIStyleKind.minimal.rawValue
                selectedColorSchemeRaw = UIAIColorScheme.light.rawValue
            }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset")
                }
                .foregroundColor(.red)
            }
            Spacer()
            Button(action: {
                if let kind = tempStyleKind {
                    selectedStyleKindRaw = kind.rawValue
                }
                if let scheme = tempColorScheme {
                    selectedColorSchemeRaw = scheme.rawValue
                }
                dismiss()
            }) {
                Text("Use this style")
                    .fontWeight(.semibold)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            Button(action: {
                dismiss()
            }) {
                Text("Done")
                    .fontWeight(.regular)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 24)
    }
}

// MARK: - Helpers for display names and icons

extension UIAIStyleKind {
    var displayName: String {
        switch self {
        case .minimal: return "Minimal"
        case .liquidGlass: return "Liquid Glass"
        case .skeuomorphic: return "Skeuomorphic"
        }
    }
    var iconName: String {
        switch self {
        case .minimal: return "rectangle"
        case .liquidGlass: return "sparkles"
        case .skeuomorphic: return "circle.lefthalf.filled"
        }
    }
} 
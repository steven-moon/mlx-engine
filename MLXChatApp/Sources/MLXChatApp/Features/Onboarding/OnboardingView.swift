import SwiftUI
import SwiftUIKit

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var currentStep = 0
    @AppStorage("selectedStyleKind") private var selectedStyleKindRaw: String = UIAIStyleKind.minimal.rawValue
    @AppStorage("selectedColorScheme") private var selectedColorSchemeRaw: String = UIAIColorScheme.light.rawValue
    @State private var tempStyleKind: UIAIStyleKind = .minimal
    @State private var tempColorScheme: UIAIColorScheme = .light
    
    private let steps: [OnboardingStep] = [
        .welcome,
        .privacy,
        .personalize,
        .modelSelection,
        .ready
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentStep) {
                ForEach(0..<steps.count, id: \ .self) { idx in
                    if steps[idx] == .personalize {
                        VStack(spacing: 32) {
                            Text("Personalize Your Experience")
                                .font(.title2.bold())
                                .multilineTextAlignment(.center)
                                .padding(.top, 32)
                            AppearanceOnboardingPicker(tempStyleKind: $tempStyleKind, tempColorScheme: $tempColorScheme)
                                .frame(maxWidth: 400)
                            Spacer()
                        }
                        .uiaiStyle(UIAIStyleRegistry.style(for: tempStyleKind, colorScheme: tempColorScheme))
                        .background(UIAIStyleRegistry.style(for: tempStyleKind, colorScheme: tempColorScheme).backgroundColor.ignoresSafeArea())
                        .tag(idx)
                    } else {
                        OnboardingStepView(
                            step: steps[idx],
                            isLast: idx == steps.count - 1,
                            onNext: {
                                if idx == steps.count - 1 {
                                    selectedStyleKindRaw = tempStyleKind.rawValue
                                    selectedColorSchemeRaw = tempColorScheme.rawValue
                                    onComplete()
                                } else {
                                    withAnimation { currentStep += 1 }
                                }
                            }
                        )
                        .tag(idx)
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .ignoresSafeArea(edges: .top)
            Spacer(minLength: 0)
            // Pager dots only, no blue bar
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \ .self) { idx in
                    Circle()
                        .fill(idx == currentStep ? Color.white : Color.gray.opacity(0.4))
                        .frame(width: 10, height: 10)
                        .shadow(radius: idx == currentStep ? 2 : 0)
                }
            }
            .padding(.bottom, 32) // More space before button
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                if currentStep == 3 { // Model selection step (now index 3)
                    HStack {
                        Button(action: { withAnimation { currentStep += 1 } }) {
                            Text("Skip for now")
                                .foregroundColor(.gray)
                                .underline()
                        }
                        Spacer()
                        Button("Continue") {
                            withAnimation { currentStep += 1 }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                } else if currentStep == 2 { // Personalize step
                    Button("Continue") {
                        withAnimation { currentStep += 1 }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                } else {
                    Button(currentStep == steps.count - 1 ? "Get Started" : "Continue") {
                        if currentStep == steps.count - 1 {
                            selectedStyleKindRaw = tempStyleKind.rawValue
                            selectedColorSchemeRaw = tempColorScheme.rawValue
                            onComplete()
                        } else {
                            withAnimation { currentStep += 1 }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .background(Color.clear)
        }
        .background(Color.black.ignoresSafeArea())
    }
}

enum OnboardingStep: CaseIterable {
    case welcome, privacy, personalize, modelSelection, ready
    
    var title: String {
        switch self {
        case .welcome: return "Welcome to MLX Chat"
        case .privacy: return "Privacy First"
        case .personalize: return "Personalize Your Experience"
        case .modelSelection: return "Choose Your AI"
        case .ready: return "Ready to Chat"
        }
    }
    
    var subtitle: String {
        switch self {
        case .welcome: return "The world's best local LLM chat app"
        case .privacy: return "Your conversations stay private"
        case .personalize: return "Customize your AI experience"
        case .modelSelection: return "Download your first model"
        case .ready: return "You're all set!"
        }
    }
    
    var description: String {
        switch self {
        case .welcome:
            return "Experience intelligent conversations powered by Apple Silicon. Fast, private, and completely local."
        case .privacy:
            return "All processing happens on your device. No data is sent to external servers. Your privacy is guaranteed."
        case .personalize:
            return "Customize your AI experience to your liking"
        case .modelSelection:
            return "Browse hundreds of optimized models from HuggingFace Hub. Start with our recommended models."
        case .ready:
            return "MLXChat is configured and ready. Start chatting with your local AI assistant!"
        }
    }
    
    var systemImage: String {
        switch self {
        case .welcome: return "sparkles"
        case .privacy: return "lock.shield.fill"
        case .personalize: return "paintbrush.fill"
        case .modelSelection: return "brain.head.profile"
        case .ready: return "checkmark.circle.fill"
        }
    }
}

struct OnboardingStepView: View {
    let step: OnboardingStep
    let isLast: Bool
    let onNext: () -> Void
    @State private var animateButton = false
    @Environment(\.uiaiStyle) private var style

    var body: some View {
        VStack(spacing: 40) {
            Spacer(minLength: 0)
            Image(systemName: step.systemImage)
                .font(.system(size: 80))
                .foregroundStyle(style.accentColor.gradient)
            VStack(spacing: 16) {
                Text(step.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                Text(step.subtitle)
                    .font(.title3)
                    .foregroundColor(style.secondaryForegroundColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                Text(step.description)
                    .font(.body)
                    .foregroundColor(style.secondaryForegroundColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            Spacer(minLength: 0)
        }
    }
} 
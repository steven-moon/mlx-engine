import SwiftUI
import SwiftUIKit
import MLXEngine

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
                        VStack(spacing: 40) {
                            Text("Personalize Your Experience")
                                .font(.title2.bold())
                                .multilineTextAlignment(.center)
                                .padding(.top, 40)
                            AppearanceOnboardingPicker(tempStyleKind: $tempStyleKind, tempColorScheme: $tempColorScheme)
                                .frame(maxWidth: 400)
                                .padding(.horizontal, 16)
                                .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground).opacity(0.2)))
                                .padding(.bottom, 16)
                            Spacer(minLength: 32)
                        }
                        .uiaiStyle(UIAIStyleRegistry.style(for: tempStyleKind, colorScheme: tempColorScheme))
                        .background(Color.black.ignoresSafeArea())
                        .tag(idx)
                        .onAppear {
                            AppLogger.shared.info("Onboarding", "Personalize step appeared (index: \(idx))")
                        }
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
                                    withAnimation(.easeInOut) { currentStep += 1 }
                                }
                            },
                            onSkip: {
                                withAnimation(.easeInOut) { currentStep = steps.count - 1 }
                            }
                        )
                        .tag(idx)
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .ignoresSafeArea(edges: .top)
            .frame(maxHeight: .infinity)
            .onChange(of: currentStep) { newStep in
                let stepName = steps[newStep].title
                AppLogger.shared.info("Onboarding", "Navigated to step \(newStep): \(stepName)")
            }
            Spacer(minLength: 0)
            VStack(spacing: 0) {
                Spacer(minLength: 24)
                HStack(spacing: 10) {
                    ForEach(0..<steps.count, id: \ .self) { idx in
                        Circle()
                            .fill(idx == currentStep ? Color.white : Color.gray.opacity(0.4))
                            .frame(width: 12, height: 12)
                            .shadow(radius: idx == currentStep ? 3 : 0)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                if currentStep == 3 {
                    HStack {
                        Button(action: { withAnimation(.easeInOut) { currentStep += 1 } }) {
                            Text("Skip for now")
                                .foregroundColor(.gray)
                                .underline()
                        }
                        Spacer()
                        Button("Continue") {
                            withAnimation(.easeInOut) { currentStep += 1 }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .frame(height: 56)
                        .cornerRadius(14)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                } else if currentStep == 2 {
                    Button("Continue") {
                        withAnimation(.easeInOut) { currentStep += 1 }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .cornerRadius(14)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                } else {
                    HStack {
                        if currentStep < steps.count - 1 {
                            Button(action: { withAnimation(.easeInOut) { currentStep = steps.count - 1 } }) {
                                Text("Skip")
                                    .foregroundColor(.gray)
                                    .underline()
                            }
                        }
                        Spacer()
                        Button(currentStep == steps.count - 1 ? "Get Started" : "Continue") {
                            if currentStep == steps.count - 1 {
                                selectedStyleKindRaw = tempStyleKind.rawValue
                                selectedColorSchemeRaw = tempColorScheme.rawValue
                                onComplete()
                            } else {
                                withAnimation(.easeInOut) { currentStep += 1 }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.blue)
                        .frame(height: 56)
                        .cornerRadius(14)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
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
    var onSkip: (() -> Void)? = nil
    @State private var animateButton = false
    @Environment(\.uiaiStyle) private var style

    var body: some View {
        VStack(spacing: 48) {
            Image(systemName: step.systemImage)
                .font(.system(size: 90))
                .foregroundStyle(style.accentColor.gradient)
                .padding(.top, 80)
                .padding(.bottom, 16)
            VStack(spacing: 20) {
                Text(step.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)
                Text(step.subtitle)
                    .font(.title3)
                    .foregroundColor(style.secondaryForegroundColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)
                Text(step.description)
                    .font(.body)
                    .foregroundColor(style.secondaryForegroundColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)
            }
            .frame(maxWidth: 500)
            Spacer(minLength: 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .onAppear {
            AppLogger.shared.info("Onboarding", "Step appeared: \(step.title)")
        }
    }
} 
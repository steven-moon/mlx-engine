import SwiftUI
import SwiftUIKit

struct OnboardingView: View {
    let onComplete: () -> Void
    @State private var currentStep = 0
    
    private let steps: [OnboardingStep] = [
        .welcome,
        .privacy,
        .modelSelection,
        .ready
    ]
    
    var body: some View {
        ZStack {
            // Background gradient from the guide
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.1),
                    Color.purple.opacity(0.1),
                    Color.pink.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            TabView(selection: $currentStep) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    OnboardingStepView(
                        step: step,
                        isLast: index == steps.count - 1,
                        onNext: {
                            if index == steps.count - 1 {
                                onComplete()
                            } else {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    currentStep = index + 1
                                }
                            }
                        }
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
        }
    }
}

enum OnboardingStep: CaseIterable {
    case welcome, privacy, modelSelection, ready
    
    var title: String {
        switch self {
        case .welcome: return "Welcome to MLX Chat"
        case .privacy: return "Privacy First"
        case .modelSelection: return "Choose Your AI"
        case .ready: return "Ready to Chat"
        }
    }
    
    var subtitle: String {
        switch self {
        case .welcome: return "The world's best local LLM chat app"
        case .privacy: return "Your conversations stay private"
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
        case .modelSelection: return "brain.head.profile"
        case .ready: return "checkmark.circle.fill"
        }
    }
}

struct OnboardingStepView: View {
    let step: OnboardingStep
    let isLast: Bool
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Image(systemName: step.systemImage)
                .font(.system(size: 80))
                .foregroundStyle(Color.blue.gradient)
                //.symbolEffect(.bounce, options: .nonRepeating)

            VStack(spacing: 16) {
                Text(step.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text(step.subtitle)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Text(step.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            if step == .modelSelection {
                ModelSetupView(onContinue: onNext)
            }
            
            Spacer()

            if step != .modelSelection {
                Button(action: onNext) {
                    Text(isLast ? "Get Started" : "Continue")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
            } else {
                // The button is part of the ModelSetupView now,
                // but we might want a skip button or it's handled internally.
                // For now, let's keep the layout consistent and add a disabled-like button area
                // or just rely on the one in ModelSetupView
                Spacer()
                    .frame(height: 60)
            }
        }
    }
} 
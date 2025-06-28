import SwiftUI
import MLXEngine

/// View for managing HuggingFace API token
struct HuggingFaceTokenView: View {
    @State private var token = ""
    @State private var isTestingToken = false
    @State private var tokenStatus: TokenStatus = .unknown
    @State private var username: String?
    @Environment(\.dismiss) private var dismiss
    
    private let huggingFaceAPI = HuggingFaceAPI.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)
                    
                    Text("HuggingFace Token")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Add your HuggingFace token for faster downloads and access to gated models")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Token input
                VStack(alignment: .leading, spacing: 8) {
                    Text("API Token")
                        .font(.headline)
                    
                    SecureField("hf_...", text: $token)
                        .textFieldStyle(.roundedBorder)
                        .onAppear {
                            token = UserDefaults.standard.string(forKey: "huggingFaceToken") ?? ""
                        }
                    
                    Text("Get your token from [HuggingFace Settings](https://huggingface.co/settings/tokens)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Token status
                if tokenStatus != .unknown {
                    HStack {
                        Image(systemName: statusIcon)
                            .foregroundColor(statusColor)
                        Text(statusMessage)
                            .font(.subheadline)
                            .foregroundColor(statusColor)
                        Spacer()
                    }
                    .padding()
                    .background(statusColor.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Username display
                if let username = username {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .foregroundColor(.green)
                        Text("Logged in as: \(username)")
                            .font(.subheadline)
                            .foregroundColor(.green)
                        Spacer()
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    if !token.isEmpty {
                        Button(action: testToken) {
                            HStack {
                                if isTestingToken {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "checkmark.circle")
                                }
                                Text(isTestingToken ? "Testing..." : "Test Token")
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(isTestingToken)
                    }
                    
                    HStack(spacing: 12) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Save") {
                            saveToken()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(token.isEmpty)
                    }
                }
            }
            .padding()
            .navigationTitle("HuggingFace Token")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            validateCurrentToken()
        }
    }
    
    private var statusIcon: String {
        switch tokenStatus {
        case .valid: return "checkmark.circle.fill"
        case .invalid: return "xmark.circle.fill"
        case .unknown: return "questionmark.circle"
        }
    }
    
    private var statusColor: Color {
        switch tokenStatus {
        case .valid: return .green
        case .invalid: return .red
        case .unknown: return .orange
        }
    }
    
    private var statusMessage: String {
        switch tokenStatus {
        case .valid: return "Token is valid"
        case .invalid: return "Token is invalid or expired"
        case .unknown: return "Token status unknown"
        }
    }
    
    private func testToken() {
        guard !token.isEmpty else { return }
        
        isTestingToken = true
        tokenStatus = .unknown
        username = nil
        
        Task {
            do {
                let result = try await huggingFaceAPI.validateToken(token: token)
                await MainActor.run {
                    isTestingToken = false
                    if let result = result {
                        tokenStatus = .valid
                        username = result
                    } else {
                        tokenStatus = .invalid
                    }
                }
            } catch {
                await MainActor.run {
                    isTestingToken = false
                    tokenStatus = .invalid
                }
            }
        }
    }
    
    private func saveToken() {
        UserDefaults.standard.set(token, forKey: "huggingFaceToken")
        dismiss()
    }
    
    private func validateCurrentToken() {
        guard !token.isEmpty else { return }
        
        Task {
            do {
                let result = try await huggingFaceAPI.validateToken(token: token)
                await MainActor.run {
                    if let result = result {
                        tokenStatus = .valid
                        username = result
                    } else {
                        tokenStatus = .invalid
                    }
                }
            } catch {
                await MainActor.run {
                    tokenStatus = .invalid
                }
            }
        }
    }
}

/// Token validation status
enum TokenStatus {
    case valid, invalid, unknown
}

#Preview {
    HuggingFaceTokenView()
} 
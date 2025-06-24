import Foundation
import MLXEngine

@main
struct SimpleExample {
    static func main() async {
        print("🚀 MLXEngine Simple Example")
        print("==========================")
        
        // Get a model from the registry
        let model = ModelRegistry.qwen05B
        print("📦 Using model: \(model.name)")
        print("🔗 Hub ID: \(model.hubId)")
        print("💾 Estimated size: \(model.estimatedSizeGB ?? 0) GB")
        print("🏗️ Architecture: \(model.architecture ?? "Unknown")")
        print("⚙️ Parameters: \(model.parameters ?? "Unknown")")
        print("🔢 Quantization: \(model.quantization ?? "Unknown")")
        print()
        
        do {
            // Load the model
            print("⏳ Loading model...")
            let startTime = Date()
            let engine = try await InferenceEngine.loadModel(model) { progress in
                print("📊 Loading progress: \(Int(progress * 100))%")
            }
            let loadTime = Date().timeIntervalSince(startTime)
            print("✅ Model loaded successfully in \(String(format: "%.2f", loadTime))s!")
            print()
            
            // Generate text
            print("🤖 Generating response...")
            let prompt = "Hello! Can you tell me a short joke?"
            print("📝 Prompt: \"\(prompt)\"")
            
            let generateStartTime = Date()
            let response = try await engine.generate(prompt)
            let generateTime = Date().timeIntervalSince(generateStartTime)
            
            print("💬 Response:")
            print(response)
            print()
            
            // Check if we're using real MLX or mock
            if response.contains("[Mock") || response.contains("mock") {
                print("⚠️ Using mock implementation. MLX runtime may not be available.")
                print("   - This is normal in test environments or when MLX is not properly installed")
                print("   - To use real MLX, ensure MLX runtime and Metal libraries are available")
            } else {
                print("✅ Using real MLX implementation!")
                print("   - Generation time: \(String(format: "%.2f", generateTime))s")
            }
            print()
            
            // Test streaming
            print("🌊 Testing streaming...")
            let streamPrompt = "What is 2 + 2?"
            print("📝 Stream prompt: \"\(streamPrompt)\"")
            
            let streamStartTime = Date()
            print("💬 Streaming response:")
            var streamedResponse = ""
            var tokenCount = 0
            
            for try await chunk in engine.stream(streamPrompt) {
                print(chunk, terminator: "")
                streamedResponse += chunk
                tokenCount += 1
            }
            let streamTime = Date().timeIntervalSince(streamStartTime)
            print()
            print("✅ Streaming completed in \(String(format: "%.2f", streamTime))s")
            print("   - Tokens generated: \(tokenCount)")
            print()
            
            // Test different parameters
            print("⚙️ Testing with different parameters...")
            let params = GenerateParams(
                maxTokens: 50,
                temperature: 0.8,
                topP: 0.9
            )
            let customResponse = try await engine.generate("Write a haiku about coding", params: params)
            print("💬 Custom response:")
            print(customResponse)
            print()
            
            // Unload the model
            print("🗑️ Unloading model...")
            engine.unload()
            print("✅ Model unloaded!")
            
        } catch {
            print("❌ Error: \(error.localizedDescription)")
            print()
            print("🔧 Troubleshooting:")
            print("   - If you see a Metal/MLX error, check your MLX/Metal installation")
            print("   - Ensure you're running on a supported Apple Silicon Mac")
            print("   - Try running MLX examples from mlx-swift-examples repo")
            print("   - Check that default.metallib is accessible")
        }
        
        print()
        print("🎉 Example completed!")
    }
} 
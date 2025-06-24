import Foundation
import MLXEngine

@main
struct InteractivePrompt {
    static func main() async {
        print("🚀 MLXEngine Interactive Prompt System")
        print("=====================================")
        print()
        
        let downloader = ModelDownloader()
        var currentEngine: InferenceEngine?
        
        // Test MLX availability first
        print("🔍 Checking MLX availability...")
        let testConfig = ModelConfiguration(
            name: "Test Model",
            hubId: "test/model",
            description: "Test model for MLX detection"
        )
        
        do {
            let testEngine = try await InferenceEngine.loadModel(testConfig) { _ in }
            let testResponse = try await testEngine.generate("test")
            
            if testResponse.contains("[Mock") || testResponse.contains("mock") {
                print("⚠️ MLX runtime not available - using mock implementation")
                print("   - Real model inference will use mock responses")
                print("   - Download and file operations will still work")
            } else {
                print("✅ MLX runtime available - real model inference enabled")
            }
            
            testEngine.unload()
        } catch {
            print("⚠️ MLX test failed: \(error.localizedDescription)")
            print("   - Will use mock implementation for inference")
        }
        print()
        
        while true {
            showMenu()
            
            print("Enter your choice (1-15): ", terminator: "")
            guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                print("❌ Invalid input")
                continue
            }
            
            switch input {
            case "1":
                await searchModels(downloader: downloader)
            case "2":
                await getModelInfo(downloader: downloader)
            case "3":
                await listDownloadedModels(downloader: downloader)
            case "4":
                await downloadModel(downloader: downloader)
            case "5":
                currentEngine = await loadModel(downloader: downloader)
            case "6":
                await generateText(engine: currentEngine)
            case "7":
                await streamText(engine: currentEngine)
            case "8":
                await chatSession(engine: currentEngine)
            case "9":
                currentEngine?.unload()
                currentEngine = nil
                print("✅ Model unloaded")
            case "10":
                await cleanupDownloads(downloader: downloader)
            case "11":
                await showTopMLXModels()
            case "12":
                await setHuggingFaceToken()
            case "13":
                await testAuthentication()
            case "14":
                await clearToken()
            case "15":
                currentEngine?.unload()
                print("👋 Goodbye!")
                return
            default:
                print("❌ Invalid choice. Please enter 1-15.")
            }
            
            print()
        }
    }
    
    // MARK: - Command Implementations
    
    static func searchModels(downloader: ModelDownloader) async {
        print("🔍 Search Models")
        print("Enter search query: ", terminator: "")
        guard let query = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines), !query.isEmpty else {
            print("❌ Invalid query")
            return
        }
        
        do {
            print("🔍 Searching for models...")
            let models = try await downloader.searchModels(query: query, limit: 10)
            
            if models.isEmpty {
                print("❌ No models found")
                return
            }
            
            print("📦 Found \(models.count) models:")
            for (index, model) in models.enumerated() {
                print("  \(index + 1). \(model.name)")
                print("     Hub ID: \(model.hubId)")
                if let params = model.parameters {
                    print("     Parameters: \(params)")
                }
                if let quant = model.quantization {
                    print("     Quantization: \(quant)")
                }
                if let arch = model.architecture {
                    print("     Architecture: \(arch)")
                }
                print()
            }
            
        } catch {
            print("❌ Error searching models: \(error.localizedDescription)")
        }
    }
    
    static func getModelInfo(downloader: ModelDownloader) async {
        print("ℹ️ Get Model Info")
        print("Enter model hub ID: ", terminator: "")
        guard let modelId = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines), !modelId.isEmpty else {
            print("❌ Invalid model ID")
            return
        }
        
        do {
            print("ℹ️ Getting model information...")
            if let modelInfo = try await downloader.getModelInfo(modelId: modelId) {
                print("📊 Model Information:")
                print("  Model ID: \(modelInfo.modelId)")
                print("  Total Files: \(modelInfo.totalFiles)")
                print("  Model Files: \(modelInfo.modelFiles)")
                print("  Config Files: \(modelInfo.configFiles)")
                print("  Estimated Size: \(String(format: "%.2f", modelInfo.estimatedSizeGB)) GB")
                print()
                print("📁 Files to download:")
                for filename in modelInfo.filenames.prefix(10) {
                    print("  - \(filename)")
                }
                if modelInfo.filenames.count > 10 {
                    print("  ... and \(modelInfo.filenames.count - 10) more files")
                }
            } else {
                print("⚠️ Model info not available (using fallback downloader)")
            }
        } catch {
            print("❌ Error getting model info: \(error.localizedDescription)")
        }
    }
    
    static func listDownloadedModels(downloader: ModelDownloader) async {
        print("📁 Downloaded Models")
        
        do {
            let models = try await downloader.getDownloadedModels()
            
            if models.isEmpty {
                print("📭 No models downloaded yet")
                return
            }
            
            print("📦 Downloaded \(models.count) models:")
            for (index, model) in models.enumerated() {
                print("  \(index + 1). \(model.name)")
                print("     Hub ID: \(model.hubId)")
                print()
            }
            
        } catch {
            print("❌ Error listing models: \(error.localizedDescription)")
        }
    }
    
    static func downloadModel(downloader: ModelDownloader) async {
        print("📥 Download Model")
        print("Enter model hub ID (e.g., mlx-community/Qwen1.5-0.5B-Chat-4bit): ", terminator: "")
        guard let hubId = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines), !hubId.isEmpty else {
            print("❌ Invalid hub ID")
            return
        }
        
        let config = ModelConfiguration(
            name: hubId,
            hubId: hubId,
            description: "Downloaded model"
        )
        
        do {
            print("📥 Starting download...")
            let startTime = CFAbsoluteTimeGetCurrent()
            
            let modelPath = try await downloader.downloadModel(config) { progress in
                let percentage = Int(progress * 100)
                print("\r📊 Download progress: \(percentage)%", terminator: "")
                fflush(stdout)
            }
            
            let downloadTime = CFAbsoluteTimeGetCurrent() - startTime
            print("\n✅ Download completed in \(String(format: "%.2f", downloadTime))s")
            print("📁 Model saved to: \(modelPath.path)")
            
            // Verify files exist
            let configFile = modelPath.appendingPathComponent("config.json")
            let tokenizerFile = modelPath.appendingPathComponent("tokenizer.json")
            let modelFile = modelPath.appendingPathComponent("model.safetensors")
            
            if FileManager.default.fileExists(atPath: configFile.path) &&
               FileManager.default.fileExists(atPath: tokenizerFile.path) &&
               FileManager.default.fileExists(atPath: modelFile.path) {
                print("✅ All model files verified!")
            } else {
                print("⚠️ Some model files may be missing")
            }
            
        } catch {
            print("\n❌ Download failed: \(error.localizedDescription)")
        }
    }
    
    static func loadModel(downloader: ModelDownloader) async -> InferenceEngine? {
        print("⚙️ Load Model")
        print("Enter model hub ID: ", terminator: "")
        guard let hubId = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines), !hubId.isEmpty else {
            print("❌ Invalid hub ID")
            return nil
        }
        
        let config = ModelConfiguration(
            name: hubId,
            hubId: hubId,
            description: "Model to load"
        )
        
        do {
            print("⚙️ Loading model...")
            let startTime = CFAbsoluteTimeGetCurrent()
            
            let engine = try await InferenceEngine.loadModel(config) { progress in
                let percentage = Int(progress * 100)
                print("\r📊 Loading progress: \(percentage)%", terminator: "")
                fflush(stdout)
            }
            
            let loadTime = CFAbsoluteTimeGetCurrent() - startTime
            print("\n✅ Model loaded in \(String(format: "%.2f", loadTime))s")
            
            // Test if we're using real MLX or mock
            let testResponse = try await engine.generate("test")
            if testResponse.contains("[Mock") || testResponse.contains("mock") {
                print("⚠️ Using mock implementation - MLX runtime not available")
            } else {
                print("✅ Using real MLX implementation!")
            }
            
            return engine
            
        } catch {
            print("\n❌ Failed to load model: \(error.localizedDescription)")
            return nil
        }
    }
    
    static func generateText(engine: InferenceEngine?) async {
        guard let engine = engine else {
            print("❌ No model loaded. Please load a model first.")
            return
        }
        
        print("🤖 Generate Text")
        print("Enter your prompt: ", terminator: "")
        guard let prompt = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines), !prompt.isEmpty else {
            print("❌ Invalid prompt")
            return
        }
        
        print("⚙️ Generation parameters (press Enter for defaults):")
        print("Max tokens (default 100): ", terminator: "")
        let maxTokensInput = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines)
        let maxTokens = Int(maxTokensInput ?? "") ?? 100
        
        print("Temperature (default 0.7): ", terminator: "")
        let tempInput = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines)
        let temperature = Double(tempInput ?? "") ?? 0.7
        
        let params = GenerateParams(
            maxTokens: maxTokens,
            temperature: temperature,
            topP: 0.9,
            topK: 40
        )
        
        do {
            print("🤖 Generating response...")
            let startTime = CFAbsoluteTimeGetCurrent()
            
            let response = try await engine.generate(prompt, params: params)
            
            let generationTime = CFAbsoluteTimeGetCurrent() - startTime
            print("✅ Generation completed in \(String(format: "%.2f", generationTime))s")
            print("💬 Response:")
            print(response)
            
            // Check if using mock
            if response.contains("[Mock") || response.contains("mock") {
                print("\n⚠️ Using mock implementation")
            } else {
                print("\n✅ Using real MLX implementation")
            }
            
        } catch {
            print("❌ Generation failed: \(error.localizedDescription)")
        }
    }
    
    static func streamText(engine: InferenceEngine?) async {
        guard let engine = engine else {
            print("❌ No model loaded. Please load a model first.")
            return
        }
        
        print("🌊 Stream Text")
        print("Enter your prompt: ", terminator: "")
        guard let prompt = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines), !prompt.isEmpty else {
            print("❌ Invalid prompt")
            return
        }
        
        let params = GenerateParams(
            maxTokens: 200,
            temperature: 0.7,
            topP: 0.9,
            topK: 40
        )
        
        do {
            print("🌊 Streaming response:")
            let startTime = CFAbsoluteTimeGetCurrent()
            var fullResponse = ""
            
            let stream = engine.stream(prompt, params: params)
            for try await chunk in stream {
                print(chunk, terminator: "")
                fullResponse += chunk
                fflush(stdout)
            }
            
            let generationTime = CFAbsoluteTimeGetCurrent() - startTime
            print("\n✅ Streaming completed in \(String(format: "%.2f", generationTime))s")
            
            // Check if using mock
            if fullResponse.contains("[Mock") || fullResponse.contains("mock") {
                print("⚠️ Using mock implementation")
            } else {
                print("✅ Using real MLX implementation")
            }
            
        } catch {
            print("❌ Streaming failed: \(error.localizedDescription)")
        }
    }
    
    static func chatSession(engine: InferenceEngine?) async {
        guard let engine = engine else {
            print("❌ No model loaded. Please load a model first.")
            return
        }
        
        print("💬 Chat Session")
        print("Type 'quit' to exit chat")
        print()
        
        let chatSession = ChatSession(engine: engine)
        
        while true {
            print("👤 You: ", terminator: "")
            guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else {
                continue
            }
            
            if input.lowercased() == "quit" {
                break
            }
            
            if input.isEmpty {
                continue
            }
            
            do {
                print("🤖 Assistant: ", terminator: "")
                let response = try await chatSession.generateResponse(input)
                print(response)
                print()
            } catch {
                print("❌ Error: \(error.localizedDescription)")
                print()
            }
        }
        
        print("👋 Chat session ended")
    }
    
    static func cleanupDownloads(downloader: ModelDownloader) async {
        print("🧹 Cleanup Incomplete Downloads")
        
        do {
            try await downloader.cleanupIncompleteDownloads()
            print("✅ Cleanup completed")
        } catch {
            print("❌ Cleanup failed: \(error.localizedDescription)")
        }
    }
    
    static func showTopMLXModels() async {
        print("🏆 Top 5 MLX Models (by downloads)")
        do {
            let api = HuggingFaceAPI.shared
            let models = try await api.searchModels(query: "mlx", limit: 50)
            let mlxModels = models
                .filter { $0.tags?.contains("mlx") == true || $0.id.lowercased().contains("mlx") || $0.id.contains("mlx-community") }
                .sorted { ($0.downloads ?? 0) > ($1.downloads ?? 0) }
                .prefix(5)
            if mlxModels.isEmpty {
                print("❌ No MLX models found.")
                return
            }
            for (index, model) in mlxModels.enumerated() {
                let config = model.toModelConfiguration()
                let sizeGB = config.estimatedSizeGB ?? 0.0
                print("  \(index + 1). \(config.name)")
                print("     Hub ID: \(config.hubId)")
                print("     Downloads: \(model.downloads ?? 0)")
                print("     Estimated Size: \(String(format: "%.2f", sizeGB)) GB")
                print()
            }
        } catch {
            print("❌ Error fetching top MLX models: \(error.localizedDescription)")
        }
    }
    
    static func showMenu() {
        print("🚀 MLXEngine Interactive Prompt System")
        print("=====================================")
        print()
        print("📋 Available Commands:")
        print("  1. Search models")
        print("  2. Get model info")
        print("  3. List downloaded models")
        print("  4. Download model")
        print("  5. Load model")
        print("  6. Generate text")
        print("  7. Stream text")
        print("  8. Chat session")
        print("  9. Unload model")
        print("  10. Cleanup incomplete downloads")
        print("  11. Show top 5 MLX models")
        print("  12. Set Hugging Face token")
        print("  13. Test authentication")
        print("  14. Clear token")
        print("  15. Exit")
        print()
    }
    
    static func setHuggingFaceToken() async {
        print("🔑 Set Hugging Face Token")
        print("Enter your Hugging Face token (or press Enter to skip): ", terminator: "")
        guard let token = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            print("❌ Invalid input")
            return
        }
        
        if token.isEmpty {
            print("ℹ️ No token provided, skipping...")
            return
        }
        
        do {
            try HuggingFaceAPI.shared.saveToken(token)
            print("✅ Token saved successfully!")
            print("ℹ️ Token will be automatically loaded in future sessions")
        } catch {
            print("❌ Failed to save token: \(error.localizedDescription)")
        }
    }
    
    static func testAuthentication() async {
        print("🔍 Testing Hugging Face Authentication")
        
        if !HuggingFaceAPI.shared.hasToken {
            print("⚠️ No token configured")
            print("ℹ️ You can set a token using option 12")
            return
        }
        
        do {
            let username = try await HuggingFaceAPI.shared.testAuthentication()
            print("✅ Authentication successful!")
            print("👤 Logged in as: \(username)")
        } catch HuggingFaceError.authenticationRequired {
            print("❌ Authentication failed: Invalid token")
            print("ℹ️ Please check your token and try again")
        } catch {
            print("❌ Authentication test failed: \(error.localizedDescription)")
        }
    }
    
    static func clearToken() async {
        print("🗑️ Clear Hugging Face Token")
        print("Are you sure you want to clear the token? (y/N): ", terminator: "")
        guard let input = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() else {
            print("❌ Invalid input")
            return
        }
        
        if input == "y" || input == "yes" {
            HuggingFaceAPI.shared.clearToken()
            print("✅ Token cleared successfully!")
            print("ℹ️ You can set a new token using option 12")
        } else {
            print("ℹ️ Token clearing cancelled")
        }
    }
} 
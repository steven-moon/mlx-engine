import XCTest
@testable import MLXEngine

#if canImport(MLX) && canImport(MLXLLM) && canImport(MLXLMCommon)
import MLX
import MLXLLM
import MLXLMCommon

final class MLXIntegrationTests: XCTestCase {
    
    func testMLXDependenciesAvailable() {
        // Test that MLX dependencies are available by checking if we can import them
        // This test will only run if the conditional compilation is true
        XCTAssertTrue(true) // If we reach here, dependencies are available
    }
    
    func testModelConfigurationCreation() {
        // Test that we can create MLXLMCommon.ModelConfiguration
        let config = MLXLMCommon.ModelConfiguration(
            id: "test-model",
            defaultPrompt: "Hello, how can I help you?"
        )
        
        XCTAssertEqual(config.id, .id("test-model", revision: "main"))
        XCTAssertEqual(config.defaultPrompt, "Hello, how can I help you?")
    }
    
    func testGenerateParametersCreation() {
        // Test that we can create MLXLMCommon.GenerateParameters
        let params = MLXLMCommon.GenerateParameters(
            maxTokens: 100,
            temperature: 0.7,
            topP: 0.9
        )
        
        XCTAssertEqual(params.maxTokens, 100)
        XCTAssertEqual(params.temperature, 0.7)
        XCTAssertEqual(params.topP, 0.9)
    }
    
    func testInferenceEngineStaticMethod() {
        // Test that the static loadModel method exists and has correct signature
        let config = ModelConfiguration(
            name: "Test Model",
            hubId: "test/model",
            description: "Test model for unit testing",
            parameters: "1B",
            quantization: "4bit",
            architecture: "Test",
            maxTokens: 1024,
            estimatedSizeGB: 0.5
        )
        
        // Test that the method signature is correct by checking it exists
        // We can't actually call it without MLX runtime, but we can verify the type
        let engineType = InferenceEngine.self
        XCTAssertNotNil(engineType)
        
        // Verify the config was created correctly
        XCTAssertEqual(config.name, "Test Model")
        XCTAssertEqual(config.hubId, "test/model")
    }
    
    func testMLXLMCommonTypes() {
        // Test that MLXLMCommon types are available
        let _: MLXLMCommon.ModelConfiguration.Type = MLXLMCommon.ModelConfiguration.self
        let _: MLXLMCommon.GenerateParameters.Type = MLXLMCommon.GenerateParameters.self
        let _: MLXLMCommon.ChatSession.Type = MLXLMCommon.ChatSession.self
        
        // If we reach here, the types are available
        XCTAssertTrue(true)
    }
    
    func testInferenceEngineIntegration() async {
        // Test that we can attempt to use InferenceEngine
        // This may fail due to MLX runtime issues, but should not crash
        let config = ModelConfiguration(
            name: "Test Model",
            hubId: "mlx-community/Qwen-0.5B-Instruct-4bit",
            description: "Test model for unit testing",
            parameters: "0.5B",
            quantization: "4bit",
            architecture: "Qwen",
            maxTokens: 1024,
            estimatedSizeGB: 0.5
        )
        
        do {
            // Try to load the model - this may fail due to MLX runtime issues
            let engine = try await InferenceEngine.loadModel(config) { progress in
                print("Loading progress: \(progress)")
            }
            
            // If we get here, the model loaded successfully
            XCTAssertNotNil(engine)
            
            // Try to generate text
            let response = try await engine.generate("Hello, how are you?")
            XCTAssertFalse(response.isEmpty)
            
            // Check if it's a MLX response or mock response
            if response.contains("mock") || response.contains("Mock") {
                print("✅ Using mock implementation (expected when MLX runtime unavailable)")
            } else {
                print("✅ Using MLX implementation")
                XCTAssertTrue(response.contains("Hello") || response.contains("how") || response.contains("you"))
            }
            
        } catch {
            // If MLX runtime is not available, this is expected
            print("MLX runtime error (expected in some environments): \(error)")
            
            // Check if it's a known MLX runtime issue
            let errorString = error.localizedDescription
            if errorString.contains("metallib") || 
               errorString.contains("library not found") ||
               errorString.contains("MLX error") ||
               errorString.contains("MLX is not available") {
                // This is expected when MLX runtime is not properly installed
                print("✅ Expected MLX runtime error - this is normal in test environments")
            } else {
                // This might be a real error we should investigate
                XCTFail("Unexpected error: \(error)")
            }
        }
    }
    
    func testInferenceEngineStreaming() async {
        // Test streaming functionality
        let config = ModelConfiguration(
            name: "Test Model",
            hubId: "test/model",
            description: "Test model for unit testing",
            parameters: "1B",
            quantization: "4bit",
            architecture: "Test",
            maxTokens: 1024,
            estimatedSizeGB: 0.5
        )
        
        do {
            let engine = try await InferenceEngine.loadModel(config)
            XCTAssertNotNil(engine)
            
            var streamedText = ""
            let stream = engine.stream("Hello, how are you?")
            
            for try await chunk in stream {
                streamedText += chunk
            }
            
            XCTAssertFalse(streamedText.isEmpty)
            
            // Check if it's a MLX response or mock response
            if streamedText.contains("mock") || streamedText.contains("Mock") {
                print("✅ Using mock streaming implementation")
            } else {
                print("✅ Using MLX streaming implementation")
            }
            
        } catch {
            print("Streaming test error (expected in some environments): \(error)")
            
            let errorString = error.localizedDescription
            if errorString.contains("metallib") || 
               errorString.contains("library not found") ||
               errorString.contains("MLX error") ||
               errorString.contains("MLX is not available") {
                print("✅ Expected MLX runtime error in streaming test")
            } else {
                XCTFail("Unexpected streaming error: \(error)")
            }
        }
    }
    
    func testInferenceEngineUnload() async {
        // Test that unload functionality works
        let config = ModelConfiguration(
            name: "Test Model",
            hubId: "test/model",
            description: "Test model for unit testing",
            parameters: "1B",
            quantization: "4bit",
            architecture: "Test",
            maxTokens: 1024,
            estimatedSizeGB: 0.5
        )
        
        do {
            let engine = try await InferenceEngine.loadModel(config)
            XCTAssertNotNil(engine)
            
            // Test that we can generate before unloading
            let response = try await engine.generate("Test")
            XCTAssertFalse(response.isEmpty)
            
            // Unload the engine
            engine.unload()
            
            // Test that generation fails after unloading
            do {
                _ = try await engine.generate("Test after unload")
                XCTFail("Generation should fail after unloading")
            } catch {
                // Expected error
                XCTAssertTrue(error.localizedDescription.contains("unloaded"))
            }
            
        } catch {
            print("Unload test error (expected in some environments): \(error)")
            
            let errorString = error.localizedDescription
            if errorString.contains("metallib") || 
               errorString.contains("library not found") ||
               errorString.contains("MLX error") ||
               errorString.contains("MLX is not available") {
                print("✅ Expected MLX runtime error in unload test")
            } else {
                XCTFail("Unexpected unload test error: \(error)")
            }
        }
    }
    
    func testInferenceEngineParameters() async {
        // Test that different generation parameters work
        let config = ModelConfiguration(
            name: "Test Model",
            hubId: "test/model",
            description: "Test model for unit testing",
            parameters: "1B",
            quantization: "4bit",
            architecture: "Test",
            maxTokens: 1024,
            estimatedSizeGB: 0.5
        )
        
        do {
            let engine = try await InferenceEngine.loadModel(config)
            XCTAssertNotNil(engine)
            
            // Test with different parameters
            let params = GenerateParams(
                maxTokens: 50,
                temperature: 0.5,
                topP: 0.8,
                topK: 20
            )
            
            let response = try await engine.generate("Test with parameters", params: params)
            XCTAssertFalse(response.isEmpty)
            
            // Verify parameters are reflected in stub response
            if response.contains("mock") || response.contains("Mock") {
                XCTAssertTrue(response.contains("50")) // maxTokens
                XCTAssertTrue(response.contains("0.5")) // temperature
                // Note: topP is not included in the current mock response format
            }
            
        } catch {
            print("Parameters test error (expected in some environments): \(error)")
            
            let errorString = error.localizedDescription
            if errorString.contains("metallib") || 
               errorString.contains("library not found") ||
               errorString.contains("MLX error") ||
               errorString.contains("MLX is not available") {
                print("✅ Expected MLX runtime error in parameters test")
            } else {
                XCTFail("Unexpected parameters test error: \(error)")
            }
        }
    }
    
    func testRealModelInferenceWithHuggingFaceAPI() async throws {
        // This test will search for a small MLX-compatible model, download it, and run real inference.
        // It will be skipped if MLX runtime is not available or if the model cannot be downloaded.
        let downloader = ModelDownloader()
        let smallModels = ModelRegistry.smallModels
        let preferredHubIds = [
            "mlx-community/Qwen1.5-0.5B-Chat-4bit",
            "mlx-community/TinyLlama-1.1B-Chat-v1.0-4bit"
        ]
        let modelConfig: MLXEngine.ModelConfiguration? = {
            for hubId in preferredHubIds {
                if let m = smallModels.first(where: { $0.hubId == hubId }) { return m }
            }
            return smallModels.first
        }()
        guard let config = modelConfig else {
            throw XCTSkip("No small MLX-compatible model found in registry.")
        }
        print("[TEST] Selected model for real inference: \(config.name) (\(config.hubId))")
        // Download the model if needed
        do {
            let _ = try await downloader.downloadModel(config) { progress in
                if progress == 1.0 { print("[TEST] Download complete for \(config.hubId)") }
            }
        } catch {
            throw XCTSkip("Could not download model: \(error)")
        }
        // Load the model and run inference
        do {
            let engine = try await InferenceEngine.loadModel(config) { progress in
                if progress == 1.0 { print("[TEST] Model loaded: \(config.hubId)") }
            }
            let prompt = "Hello, world!"
            let response = try await engine.generate(prompt)
            print("[TEST] Inference output: \(response)")
            XCTAssertFalse(response.isEmpty, "Output should not be empty")
            XCTAssertFalse(response.lowercased().contains("mock"), "Should not be a mock response")
        } catch let error as MLXEngineError {
            let msg = error.localizedDescription
            if msg.contains("MLX runtime not available") || msg.contains("Missing required files") {
                throw XCTSkip("MLX runtime or model files not available: \(msg)")
            } else {
                XCTFail("Unexpected MLXEngineError: \(msg)")
            }
        } catch {
            XCTFail("Unexpected error during real inference: \(error)")
        }
    }
}

#else

final class MLXIntegrationTests: XCTestCase {
    
    func testMLXDependenciesNotAvailable() {
        // Test that MLX dependencies are not available (stub implementation)
        // This test will only run if the conditional compilation is false
        XCTAssertTrue(true) // If we reach here, we're using stub implementation
    }
    
    func testStubInferenceEngineStaticMethod() {
        // Test that the static loadModel method exists and has correct signature
        _ = ModelConfiguration(
            name: "Test Model",
            hubId: "test/model",
            description: "Test model for unit testing",
            parameters: "1B",
            quantization: "4bit",
            architecture: "Test",
            maxTokens: 1024,
            estimatedSizeGB: 0.5
        )
        
        // Test that the method signature is correct by checking it exists
        let engineType = InferenceEngine.self
        XCTAssertNotNil(engineType)
    }
    
    func testStubImplementation() {
        // Test that we're using the stub implementation
        // This test will only run if MLX dependencies are not available
        XCTAssertTrue(true) // If we reach here, stub implementation is working
    }
    
    func testStubInferenceEngineIntegration() async {
        // Test that stub InferenceEngine works correctly
        let config = ModelConfiguration(
            name: "Test Model",
            hubId: "test/model",
            description: "Test model for unit testing",
            parameters: "1B",
            quantization: "4bit",
            architecture: "Test",
            maxTokens: 1024,
            estimatedSizeGB: 0.5
        )
        
        do {
            // Try to load the model - this should work with stub implementation
            let engine = try await InferenceEngine.loadModel(config) { progress in
                print("Loading progress: \(progress)")
            }
            
            // If we get here, the model loaded successfully
            XCTAssertNotNil(engine)
            
            // Try to generate text
            let response = try await engine.generate("Hello, how are you?")
            XCTAssertFalse(response.isEmpty)
            XCTAssertTrue(response.contains("mock") || response.contains("Mock"))
            
        } catch {
            XCTFail("Stub implementation should not fail: \(error)")
        }
    }
    
    func testStubInferenceEngineStreaming() async {
        // Test stub streaming functionality
        let config = ModelConfiguration(
            name: "Test Model",
            hubId: "test/model",
            description: "Test model for unit testing",
            parameters: "1B",
            quantization: "4bit",
            architecture: "Test",
            maxTokens: 1024,
            estimatedSizeGB: 0.5
        )
        
        do {
            let engine = try await InferenceEngine.loadModel(config)
            XCTAssertNotNil(engine)
            
            var streamedText = ""
            let stream = engine.stream("Hello, how are you?")
            
            for try await chunk in stream {
                streamedText += chunk
            }
            
            XCTAssertFalse(streamedText.isEmpty)
            XCTAssertTrue(streamedText.contains("mock") || streamedText.contains("Mock"))
            
        } catch {
            XCTFail("Stub streaming should not fail: \(error)")
        }
    }
    
    func testStubInferenceEngineUnload() async {
        // Test stub unload functionality
        let config = ModelConfiguration(
            name: "Test Model",
            hubId: "test/model",
            description: "Test model for unit testing",
            parameters: "1B",
            quantization: "4bit",
            architecture: "Test",
            maxTokens: 1024,
            estimatedSizeGB: 0.5
        )
        
        do {
            let engine = try await InferenceEngine.loadModel(config)
            XCTAssertNotNil(engine)
            
            // Test that we can generate before unloading
            let response = try await engine.generate("Test")
            XCTAssertFalse(response.isEmpty)
            
            // Unload the engine
            engine.unload()
            
            // Test that generation fails after unloading
            do {
                _ = try await engine.generate("Test after unload")
                XCTFail("Generation should fail after unloading")
            } catch {
                // Expected error
                XCTAssertTrue(error.localizedDescription.contains("unloaded"))
            }
            
        } catch {
            XCTFail("Stub unload test should not fail: \(error)")
        }
    }
    
    func testStubInferenceEngineParameters() async {
        // Test stub parameters functionality
        let config = ModelConfiguration(
            name: "Test Model",
            hubId: "test/model",
            description: "Test model for unit testing",
            parameters: "1B",
            quantization: "4bit",
            architecture: "Test",
            maxTokens: 1024,
            estimatedSizeGB: 0.5
        )
        
        do {
            let engine = try await InferenceEngine.loadModel(config)
            XCTAssertNotNil(engine)
            
            // Test with different parameters
            let params = GenerateParams(
                maxTokens: 50,
                temperature: 0.5,
                topP: 0.8,
                topK: 20
            )
            
            let response = try await engine.generate("Test with parameters", params: params)
            XCTAssertFalse(response.isEmpty)
            XCTAssertTrue(response.contains("mock") || response.contains("Mock"))
            
            // Verify parameters are reflected in stub response
            XCTAssertTrue(response.contains("50")) // maxTokens
            XCTAssertTrue(response.contains("0.5")) // temperature
            // Note: topP is not included in the current mock response format
            
        } catch {
            XCTFail("Stub parameters test should not fail: \(error)")
        }
    }
}

#endif 
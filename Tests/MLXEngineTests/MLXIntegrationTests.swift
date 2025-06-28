import XCTest

@testable import MLXEngine

#if canImport(MLX) && canImport(MLXLLM) && canImport(MLXLMCommon)
  import MLX
  import MLXLLM
  import MLXLMCommon

  final class MLXIntegrationTests: XCTestCase {

    // MARK: - Test Configuration

    override func setUp() async throws {
      // Set up MLX GPU cache limit for testing
      #if canImport(MLX)
        MLX.GPU.set(cacheLimit: 512 * 1024 * 1024)  // 512MB
      #endif
    }

    override func tearDown() async throws {
      // Clean up any loaded models
      // This will be handled by the engine's unload method
    }

    // MARK: - Feature Detection Tests

    func testFeatureDetection() throws {
      guard ProcessInfo.processInfo.environment["RUN_REAL_MODEL_TESTS"] != nil else {
        throw XCTSkip("Skipping real model test: RUN_REAL_MODEL_TESTS not set")
      }
      print("\n🔍 [FEATURE TEST] Testing feature detection...")

      let features = InferenceEngine.supportedFeatures
      print("✅ [FEATURE TEST] Available features: \(features)")

      // Test core features
      XCTAssertTrue(
        features.contains(.streamingGeneration), "Streaming generation should be available")
      XCTAssertTrue(
        features.contains(.conversationMemory), "Conversation memory should be available")
      XCTAssertTrue(
        features.contains(.performanceMonitoring), "Performance monitoring should be available")

      // Test MLX-specific features
      #if canImport(MLX) && canImport(MLXLLM) && canImport(MLXLMCommon)
        XCTAssertTrue(
          features.contains(.quantizationSupport),
          "Quantization support should be available with MLX")
        XCTAssertTrue(
          features.contains(.modelCaching), "Model caching should be available with MLX")
        XCTAssertTrue(
          features.contains(.customTokenizers), "Custom tokenizers should be available with MLX")
      #endif

      print("✅ [FEATURE TEST] Feature detection completed successfully")
    }

    // MARK: - LLM Model Tests

    func testLLMModelDownloadAndInference() async throws {
      guard ProcessInfo.processInfo.environment["RUN_REAL_MODEL_TESTS"] != nil else {
        throw XCTSkip("Skipping real model test: RUN_REAL_MODEL_TESTS not set")
      }
      print("\n🚀 [LLM TEST] Testing LLM model download and inference...")

      // Test with a small, fast model
      let config = ModelRegistry.qwen05B
      print("📋 [LLM TEST] Using model: \(config.name) (\(config.hubId))")

      let loadProgressCollector = ProgressCollector()
      let startTime = Date()

      // Load the model
      let engine = try await InferenceEngine.loadModel(config) { progress in
        Task {
          await loadProgressCollector.addProgress(progress)
        }
      }

      let loadTime = Date().timeIntervalSince(startTime)
      let loadProgress = await loadProgressCollector.getProgressValues()

      print("✅ [LLM TEST] Model loaded successfully!")
      print("   - Load time: \(String(format: "%.2f", loadTime)) seconds")
      print("   - Progress points: \(loadProgress.count)")
      print("   - Final progress: \(loadProgress.last ?? 0.0)")

      // Test text generation
      let testPrompt = "Hello! Please respond with a short, friendly greeting."
      print("📝 [LLM TEST] Test prompt: \"\(testPrompt)\"")

      let generateStartTime = Date()
      let response = try await engine.generate(
        testPrompt, params: GenerateParams(maxTokens: 50, temperature: 0.7))
      let generateTime = Date().timeIntervalSince(generateStartTime)

      print("✅ [LLM TEST] Text generation successful!")
      print("   - Response: \"\(response)\"")
      print("   - Generation time: \(String(format: "%.2f", generateTime)) seconds")

      XCTAssertFalse(response.isEmpty, "Response should not be empty")
      XCTAssertTrue(response.count > 10, "Response should be substantial")

      // Test streaming generation
      print("\n🔄 [LLM TEST] Testing streaming generation...")
      let streamPrompt = "Tell me a very short story about a cat."
      print("📝 [LLM TEST] Stream prompt: \"\(streamPrompt)\"")

      let streamStartTime = Date()
      var streamedText = ""
      var chunkCount = 0

      for try await chunk in engine.stream(
        streamPrompt, params: GenerateParams(maxTokens: 100, temperature: 0.8))
      {
        streamedText += chunk
        chunkCount += 1
        print("   Chunk \(chunkCount): \"\(chunk)\"")
      }

      let streamTime = Date().timeIntervalSince(streamStartTime)
      print("✅ [LLM TEST] Streaming generation successful!")
      print("   - Total chunks: \(chunkCount)")
      print("   - Streamed text: \"\(streamedText)\"")
      print("   - Stream time: \(String(format: "%.2f", streamTime)) seconds")

      XCTAssertFalse(streamedText.isEmpty, "Streamed text should not be empty")
      XCTAssertTrue(chunkCount > 1, "Should have multiple chunks")

      // Test model unloading
      print("\n🧹 [LLM TEST] Testing model unloading...")
      engine.unload()
      print("✅ [LLM TEST] Model unloaded successfully")

      print("✅ [LLM TEST] LLM model test completed successfully!")
    }

    // MARK: - VLM Model Tests

    func testVLMModelDownloadAndInference() async throws {
      guard ProcessInfo.processInfo.environment["RUN_REAL_MODEL_TESTS"] != nil else {
        throw XCTSkip("Skipping real model test: RUN_REAL_MODEL_TESTS not set")
      }
      print("\n🖼️ [VLM TEST] Testing VLM model download and inference...")

      // Check if VLM features are available
      guard InferenceEngine.supportedFeatures.contains(.visionLanguageModels) else {
        print("⚠️ [VLM TEST] VLM features not available, skipping test")
        return
      }

      // Test with LLaVA model
      let config = ModelRegistry.llava16_3B
      print("📋 [VLM TEST] Using model: \(config.name) (\(config.hubId))")

      let loadProgressCollector = ProgressCollector()
      let startTime = Date()

      // Load the VLM model
      let engine = try await InferenceEngine.loadModel(config) { progress in
        Task {
          await loadProgressCollector.addProgress(progress)
        }
      }

      let loadTime = Date().timeIntervalSince(startTime)
      let loadProgress = await loadProgressCollector.getProgressValues()

      print("✅ [VLM TEST] VLM model loaded successfully!")
      print("   - Load time: \(String(format: "%.2f", loadTime)) seconds")
      print("   - Progress points: \(loadProgress.count)")

      // Test VLM-specific features
      XCTAssertTrue(
        InferenceEngine.supportedFeatures.contains(.multiModalInput),
        "Multi-modal input should be available for VLM")

      // Test text-only generation (VLM models can also do text generation)
      let testPrompt =
        "Describe what you see in this image: [No image provided, please respond with a general description of your capabilities]"
      print("📝 [VLM TEST] Test prompt: \"\(testPrompt)\"")

      let response = try await engine.generate(
        testPrompt, params: .init(maxTokens: 100, temperature: 0.7))

      print("✅ [VLM TEST] VLM text generation successful!")
      print("   - Response: \"\(response)\"")

      XCTAssertFalse(response.isEmpty, "VLM response should not be empty")

      // Test model unloading
      print("\n🧹 [VLM TEST] Testing VLM model unloading...")
      engine.unload()
      print("✅ [VLM TEST] VLM model unloaded successfully")

      print("✅ [VLM TEST] VLM model test completed successfully!")
    }

    // MARK: - Embedding Model Tests

    func testEmbeddingModelDownloadAndInference() async throws {
      guard ProcessInfo.processInfo.environment["RUN_REAL_MODEL_TESTS"] != nil else {
        throw XCTSkip("Skipping real model test: RUN_REAL_MODEL_TESTS not set")
      }
      print("\n🔗 [EMBEDDING TEST] Testing embedding model download and inference...")

      // Check if embedding features are available
      guard InferenceEngine.supportedFeatures.contains(.embeddingModels) else {
        print("⚠️ [EMBEDDING TEST] Embedding features not available, skipping test")
        return
      }

      // Test with BGE model
      let config = ModelRegistry.bgeSmallEn
      print("📋 [EMBEDDING TEST] Using model: \(config.name) (\(config.hubId))")

      let loadProgressCollector = ProgressCollector()
      let startTime = Date()

      // Load the embedding model
      let engine = try await InferenceEngine.loadModel(config) { progress in
        Task { await loadProgressCollector.addProgress(progress) }
      }

      let loadTime = Date().timeIntervalSince(startTime)
      let loadProgress = await loadProgressCollector.getProgressValues()

      print("✅ [EMBEDDING TEST] Embedding model loaded successfully!")
      print("   - Load time: \(String(format: "%.2f", loadTime)) seconds")
      print("   - Progress points: \(loadProgress.count)")

      // Test embedding-specific features
      XCTAssertTrue(
        InferenceEngine.supportedFeatures.contains(.batchProcessing),
        "Batch processing should be available for embeddings")

      // Test text embedding generation
      let testText = "This is a test sentence for embedding generation."
      print("📝 [EMBEDDING TEST] Test text: \"\(testText)\"")

      let response = try await engine.generate(
        testText, params: GenerateParams(maxTokens: 512, temperature: 0.0))

      print("✅ [EMBEDDING TEST] Embedding generation successful!")
      print("   - Response length: \(response.count)")

      XCTAssertFalse(response.isEmpty, "Embedding response should not be empty")

      // Test model unloading
      print("\n🧹 [EMBEDDING TEST] Testing embedding model unloading...")
      engine.unload()
      print("✅ [EMBEDDING TEST] Embedding model unloaded successfully")

      print("✅ [EMBEDDING TEST] Embedding model test completed successfully!")
    }

    // MARK: - Diffusion Model Tests

    func testDiffusionModelDownloadAndInference() async throws {
      guard ProcessInfo.processInfo.environment["RUN_REAL_MODEL_TESTS"] != nil else {
        throw XCTSkip("Skipping real model test: RUN_REAL_MODEL_TESTS not set")
      }
      print("\n🎨 [DIFFUSION TEST] Testing diffusion model download and inference...")

      // Check if diffusion features are available
      guard InferenceEngine.supportedFeatures.contains(.diffusionModels) else {
        print("⚠️ [DIFFUSION TEST] Diffusion features not available, skipping test")
        return
      }

      // Test with Stable Diffusion model
      let config = ModelRegistry.stableDiffusionXL
      print("📋 [DIFFUSION TEST] Using model: \(config.name) (\(config.hubId))")

      let loadProgressCollector = ProgressCollector()
      let startTime = Date()

      // Load the diffusion model
      let engine = try await InferenceEngine.loadModel(config) { progress in
        Task { await loadProgressCollector.addProgress(progress) }
      }

      let loadTime = Date().timeIntervalSince(startTime)
      let loadProgress = await loadProgressCollector.getProgressValues()

      print("✅ [DIFFUSION TEST] Diffusion model loaded successfully!")
      print("   - Load time: \(String(format: "%.2f", loadTime)) seconds")
      print("   - Progress points: \(loadProgress.count)")

      // Test diffusion-specific features
      XCTAssertTrue(
        InferenceEngine.supportedFeatures.contains(.multiModalInput),
        "Multi-modal input should be available for diffusion")

      // Test image generation prompt
      let testPrompt = "A beautiful sunset over the ocean"
      print("📝 [DIFFUSION TEST] Test prompt: \"\(testPrompt)\"")

      let response = try await engine.generate(
        testPrompt, params: GenerateParams(maxTokens: 77, temperature: 0.8))

      print("✅ [DIFFUSION TEST] Diffusion generation successful!")
      print("   - Response length: \(response.count)")

      XCTAssertFalse(response.isEmpty, "Diffusion response should not be empty")

      // Test model unloading
      print("\n🧹 [DIFFUSION TEST] Testing diffusion model unloading...")
      engine.unload()
      print("✅ [DIFFUSION TEST] Diffusion model unloaded successfully")

      print("✅ [DIFFUSION TEST] Diffusion model test completed successfully!")
    }

    // MARK: - Quantization Tests

    func testQuantizedModelInference() async throws {
      guard ProcessInfo.processInfo.environment["RUN_REAL_MODEL_TESTS"] != nil else {
        throw XCTSkip("Skipping real model test: RUN_REAL_MODEL_TESTS not set")
      }
      print("\n⚡ [QUANTIZATION TEST] Testing quantized model inference...")

      // Check if quantization features are available
      guard InferenceEngine.supportedFeatures.contains(.quantizationSupport) else {
        print("⚠️ [QUANTIZATION TEST] Quantization features not available, skipping test")
        return
      }

      // Test with FP16 quantized model
      let config = ModelRegistry.llama32_3B_fp16
      print("📋 [QUANTIZATION TEST] Using model: \(config.name) (\(config.hubId))")

      let loadProgressCollector = ProgressCollector()
      let startTime = Date()

      // Load the quantized model
      let engine = try await InferenceEngine.loadModel(config) { progress in
        Task { await loadProgressCollector.addProgress(progress) }
      }

      let loadTime = Date().timeIntervalSince(startTime)
      let loadProgress = await loadProgressCollector.getProgressValues()

      print("✅ [QUANTIZATION TEST] Quantized model loaded successfully!")
      print("   - Load time: \(String(format: "%.2f", loadTime)) seconds")
      print("   - Progress points: \(loadProgress.count)")
      print("   - Quantization: \(config.quantization ?? "unknown")")

      // Test text generation with quantized model
      let testPrompt = "Explain the benefits of model quantization in one sentence."
      print("📝 [QUANTIZATION TEST] Test prompt: \"\(testPrompt)\"")

      let response = try await engine.generate(
        testPrompt, params: GenerateParams(maxTokens: 100, temperature: 0.7))

      print("✅ [QUANTIZATION TEST] Quantized model generation successful!")
      print("   - Response: \"\(response)\"")

      XCTAssertFalse(response.isEmpty, "Quantized model response should not be empty")

      // Test model unloading
      print("\n🧹 [QUANTIZATION TEST] Testing quantized model unloading...")
      engine.unload()
      print("✅ [QUANTIZATION TEST] Quantized model unloaded successfully")

      print("✅ [QUANTIZATION TEST] Quantized model test completed successfully!")
    }

    // MARK: - Performance Monitoring Tests

    func testPerformanceMonitoring() async throws {
      guard ProcessInfo.processInfo.environment["RUN_REAL_MODEL_TESTS"] != nil else {
        throw XCTSkip("Skipping real model test: RUN_REAL_MODEL_TESTS not set")
      }
      print("\n📊 [PERFORMANCE TEST] Testing performance monitoring...")

      // Check if performance monitoring features are available
      guard InferenceEngine.supportedFeatures.contains(.performanceMonitoring) else {
        print("⚠️ [PERFORMANCE TEST] Performance monitoring features not available, skipping test")
        return
      }

      let config = ModelRegistry.qwen05B
      print("📋 [PERFORMANCE TEST] Using model: \(config.name)")

      let startTime = Date()

      // Load the model
      let engine = try await InferenceEngine.loadModel(config) { _ in }

      let loadTime = Date().timeIntervalSince(startTime)

      // Get engine status
      let status = engine.status
      print("✅ [PERFORMANCE TEST] Engine status retrieved:")
      print("   - Model loaded: \(status.isModelLoaded)")
      print("   - MLX available: \(status.mlxAvailable)")
      print("   - Load time: \(String(format: "%.2f", loadTime)) seconds")

      XCTAssertTrue(status.isModelLoaded, "Model should be loaded")
      XCTAssertTrue(status.mlxAvailable, "MLX should be available")

      // Test generation with performance monitoring
      let generateStartTime = Date()
      let response = try await engine.generate(
        "Test performance monitoring", params: .init(maxTokens: 50))
      let generateTime = Date().timeIntervalSince(generateStartTime)

      print("✅ [PERFORMANCE TEST] Generation performance:")
      print("   - Generation time: \(String(format: "%.2f", generateTime)) seconds")
      print("   - Response length: \(response.count)")

      XCTAssertTrue(generateTime > 0, "Generation time should be positive")

      // Test model unloading
      engine.unload()
      print("✅ [PERFORMANCE TEST] Performance monitoring test completed successfully!")
    }

    // MARK: - Model Registry Tests

    func testModelRegistryComprehensive() async throws {
      guard ProcessInfo.processInfo.environment["RUN_REAL_MODEL_TESTS"] != nil else {
        throw XCTSkip("Skipping real model test: RUN_REAL_MODEL_TESTS not set")
      }
      print("\n📚 [REGISTRY TEST] Testing comprehensive model registry...")

      // Test all model types
      let allModels = ModelRegistry.allModels
      print("📋 [REGISTRY TEST] Total models in registry: \(allModels.count)")

      // Group models by type
      let llmModels = allModels.filter { ModelRegistry.getModelType($0) == .llm }
      let vlmModels = allModels.filter { ModelRegistry.getModelType($0) == .vlm }
      let embedderModels = allModels.filter { ModelRegistry.getModelType($0) == .embedder }
      let diffusionModels = allModels.filter { ModelRegistry.getModelType($0) == .diffusion }

      print("📊 [REGISTRY TEST] Model distribution:")
      print("   - LLM models: \(llmModels.count)")
      print("   - VLM models: \(vlmModels.count)")
      print("   - Embedder models: \(embedderModels.count)")
      print("   - Diffusion models: \(diffusionModels.count)")

      // Test model search functionality
      let searchResults = ModelRegistry.searchModels(query: "qwen", type: .llm)
      print("🔍 [REGISTRY TEST] Search results for 'qwen': \(searchResults.count) models")

      XCTAssertTrue(searchResults.count > 0, "Should find Qwen models")

      // Test model recommendations
      let mobileModels = ModelRegistry.getRecommendedModels(for: .mobileDevelopment)
      let qualityModels = ModelRegistry.getRecommendedModels(for: .highQualityGeneration)

      print("📱 [REGISTRY TEST] Mobile models: \(mobileModels.count)")
      print("🎯 [REGISTRY TEST] Quality models: \(qualityModels.count)")

      XCTAssertTrue(mobileModels.count > 0, "Should have mobile-optimized models")
      XCTAssertTrue(qualityModels.count > 0, "Should have high-quality models")

      print("✅ [REGISTRY TEST] Model registry test completed successfully!")
    }

    // MARK: - Error Handling Tests

    func testErrorHandling() async throws {
      guard ProcessInfo.processInfo.environment["RUN_REAL_MODEL_TESTS"] != nil else {
        throw XCTSkip("Skipping real model test: RUN_REAL_MODEL_TESTS not set")
      }
      print("\n⚠️ [ERROR TEST] Testing error handling...")

      // Test with invalid model configuration
      let invalidConfig = ModelConfiguration(
        name: "Invalid Model",
        hubId: "invalid/model/that/does/not/exist",
        description: "This model does not exist",
        maxTokens: 100
      )

      do {
        let _ = try await InferenceEngine.loadModel(invalidConfig) { _ in }
        XCTFail("Should have thrown an error for invalid model")
      } catch {
        print("✅ [ERROR TEST] Correctly caught error: \(error)")
        XCTAssertTrue(error is MLXEngineError, "Error should be MLXEngineError")
      }

      // Test with unsupported features
      let engine = try await InferenceEngine.loadModel(ModelRegistry.qwen05B) { _ in }

      do {
        try await engine.loadLoRAAdapter(from: URL(string: "file:///invalid")!)
        XCTFail("Should have thrown an error for unsupported LoRA")
      } catch {
        print("✅ [ERROR TEST] Correctly caught LoRA error: \(error)")
      }

      engine.unload()
      print("✅ [ERROR TEST] Error handling test completed successfully!")
    }
  }

  // MARK: - Helper Classes

  /// Helper class to collect progress values during async operations
  actor ProgressCollector {
    private var progressValues: [Double] = []

    func addProgress(_ progress: Double) {
      progressValues.append(progress)
    }

    func getProgressValues() -> [Double] {
      return progressValues
    }
  }

#else

  final class MLXIntegrationTests: XCTestCase {

    func testMLXDependenciesNotAvailable() {
      print("\n⚠️ [MLX TEST] MLX dependencies not available, skipping integration tests")
      // This test will run when MLX dependencies are not available
      XCTAssertTrue(true)
    }
  }

#endif

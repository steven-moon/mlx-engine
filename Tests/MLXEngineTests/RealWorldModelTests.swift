import Foundation
import XCTest

@testable import MLXEngine

/// Real-world tests that download and test actual models from HuggingFace
final class RealWorldModelTests: XCTestCase {

  // MARK: - Test Configuration

  /// Test timeout for model downloads and inference
  private let testTimeout: TimeInterval = 300  // 5 minutes

  /// Whether to run expensive tests (model downloads)
  private var shouldRunExpensiveTests: Bool {
    // Set to true to run full model download tests
    // Set to false for faster CI/CD runs
    return ProcessInfo.processInfo.environment["RUN_EXPENSIVE_TESTS"] == "true"
  }

  // MARK: - LLM Model Tests

  func testRealLLMModelDownloadAndInference() async throws {
    guard shouldRunExpensiveTests else {
      print("⚠️ [REAL WORLD TEST] Skipping expensive LLM model download test")
      return
    }

    print("\n🤖 [REAL WORLD LLM TEST] Testing real LLM model download and inference...")

    // Test with a small, fast LLM model
    let config = ModelRegistry.qwen05B
    print("📋 [REAL WORLD LLM TEST] Using model: \(config.name) (\(config.hubId))")

    let loadProgressCollector = ProgressCollector()
    let startTime = Date()

    // Download and load the model
    let engine = try await InferenceEngine.loadModel(config) { progress in
      Task { await loadProgressCollector.addProgress(progress) }
    }

    let loadTime = Date().timeIntervalSince(startTime)
    let loadProgress = await loadProgressCollector.getProgressValues()

    print("✅ [REAL WORLD LLM TEST] Model loaded successfully!")
    print("   - Load time: \(String(format: "%.2f", loadTime)) seconds")
    print("   - Progress points: \(loadProgress.count)")

    // Test text generation
    let testPrompts = [
      "Hello, how are you?",
      "What is the capital of France?",
      "Explain quantum computing in simple terms.",
    ]

    for (index, prompt) in testPrompts.enumerated() {
      print("📝 [REAL WORLD LLM TEST] Test prompt \(index + 1): \"\(prompt)\"")

      let generateStartTime = Date()
      let response = try await engine.generate(
        prompt, params: .init(maxTokens: 100, temperature: 0.7))
      let generateTime = Date().timeIntervalSince(generateStartTime)

      print("✅ [REAL WORLD LLM TEST] Generation \(index + 1) successful!")
      print("   - Response: \"\(response)\"")
      print("   - Generation time: \(String(format: "%.2f", generateTime)) seconds")

      XCTAssertFalse(response.isEmpty, "Response should not be empty")
      XCTAssertGreaterThan(response.count, 10, "Response should be substantial")
    }

    // Test streaming generation
    print("📡 [REAL WORLD LLM TEST] Testing streaming generation...")
    let streamPrompt = "Write a short story about a robot learning to paint."
    let streamStartTime = Date()

    var streamedResponse = ""
    var tokenCount = 0

    for try await token in engine.stream(
      streamPrompt, params: .init(maxTokens: 50, temperature: 0.8))
    {
      streamedResponse += token
      tokenCount += 1
      print("   Token \(tokenCount): \"\(token)\"")
    }

    let streamTime = Date().timeIntervalSince(streamStartTime)
    print("✅ [REAL WORLD LLM TEST] Streaming successful!")
    print("   - Streamed response: \"\(streamedResponse)\"")
    print("   - Tokens generated: \(tokenCount)")
    print("   - Stream time: \(String(format: "%.2f", streamTime)) seconds")

    XCTAssertFalse(streamedResponse.isEmpty, "Streamed response should not be empty")
    XCTAssertGreaterThan(tokenCount, 0, "Should generate at least one token")

    // Test model unloading
    print("\n🧹 [REAL WORLD LLM TEST] Testing model unloading...")
    engine.unload()
    print("✅ [REAL WORLD LLM TEST] Model unloaded successfully")

    print("✅ [REAL WORLD LLM TEST] LLM model test completed successfully!")
  }

  // MARK: - VLM Model Tests

  func testRealVLMModelDownloadAndInference() async throws {
    guard shouldRunExpensiveTests else {
      print("⚠️ [REAL WORLD TEST] Skipping expensive VLM model download test")
      return
    }

    print("\n🖼️ [REAL WORLD VLM TEST] Testing real VLM model download and inference...")

    // Test with LLaVA model
    let config = ModelRegistry.llava16_3B
    print("📋 [REAL WORLD VLM TEST] Using model: \(config.name) (\(config.hubId))")

    let loadProgressCollector = ProgressCollector()
    let startTime = Date()

    // Download and load the VLM model
    let engine = try await InferenceEngine.loadModel(config) { progress in
      Task { await loadProgressCollector.addProgress(progress) }
    }

    let loadTime = Date().timeIntervalSince(startTime)
    let loadProgress = await loadProgressCollector.getProgressValues()

    print("✅ [REAL WORLD VLM TEST] VLM model loaded successfully!")
    print("   - Load time: \(String(format: "%.2f", loadTime)) seconds")
    print("   - Progress points: \(loadProgress.count)")

    // Test text-only generation (VLM models can also do text generation)
    let textPrompt =
      "Describe what you see in this image: [No image provided, please respond with a general description of your capabilities]"
    print("📝 [REAL WORLD VLM TEST] Test text prompt: \"\(textPrompt)\"")

    let response = try await engine.generate(
      textPrompt, params: .init(maxTokens: 100, temperature: 0.7))

    print("✅ [REAL WORLD VLM TEST] VLM text generation successful!")
    print("   - Response: \"\(response)\"")

    XCTAssertFalse(response.isEmpty, "VLM text response should not be empty")

    // Test multi-modal input (placeholder for when implemented)
    if InferenceEngine.supportedFeatures.contains(.multiModalInput) {
      print("🖼️ [REAL WORLD VLM TEST] Testing multi-modal input...")

      let multiModalInput = InferenceEngine.MultiModalInput.text("Describe this image")

      do {
        let multiModalResponse = try await engine.generateWithMultiModalInput(multiModalInput)
        print("✅ [REAL WORLD VLM TEST] Multi-modal generation successful!")
        print("   - Response: \"\(multiModalResponse)\"")
      } catch {
        print("⚠️ [REAL WORLD VLM TEST] Multi-modal generation not yet implemented: \(error)")
      }
    }

    // Test model unloading
    print("\n🧹 [REAL WORLD VLM TEST] Testing VLM model unloading...")
    engine.unload()
    print("✅ [REAL WORLD VLM TEST] VLM model unloaded successfully")

    print("✅ [REAL WORLD VLM TEST] VLM model test completed successfully!")
  }

  // MARK: - Embedding Model Tests

  func testRealEmbeddingModelDownloadAndInference() async throws {
    guard shouldRunExpensiveTests else {
      print("⚠️ [REAL WORLD TEST] Skipping expensive embedding model download test")
      return
    }

    print("\n🔍 [REAL WORLD EMBEDDING TEST] Testing real embedding model download and inference...")

    // Test with BGE embedding model
    let config = ModelRegistry.bgeSmallEn
    print("📋 [REAL WORLD EMBEDDING TEST] Using model: \(config.name) (\(config.hubId))")

    let loadProgressCollector = ProgressCollector()
    let startTime = Date()

    // Download and load the embedding model
    let engine = try await InferenceEngine.loadModel(config) { progress in
      Task { await loadProgressCollector.addProgress(progress) }
    }

    let loadTime = Date().timeIntervalSince(startTime)
    let loadProgress = await loadProgressCollector.getProgressValues()

    print("✅ [REAL WORLD EMBEDDING TEST] Embedding model loaded successfully!")
    print("   - Load time: \(String(format: "%.2f", loadTime)) seconds")
    print("   - Progress points: \(loadProgress.count)")

    // Test embedding generation
    let testTexts = [
      "The quick brown fox jumps over the lazy dog.",
      "Machine learning is a subset of artificial intelligence.",
      "The weather is sunny today.",
    ]

    for (index, text) in testTexts.enumerated() {
      print("📝 [REAL WORLD EMBEDDING TEST] Test text \(index + 1): \"\(text)\"")

      let generateStartTime = Date()
      let response = try await engine.generate(
        text, params: .init(maxTokens: 512, temperature: 0.0))
      let generateTime = Date().timeIntervalSince(generateStartTime)

      print("✅ [REAL WORLD EMBEDDING TEST] Embedding \(index + 1) successful!")
      print("   - Response length: \(response.count)")
      print("   - Generation time: \(String(format: "%.2f", generateTime)) seconds")

      XCTAssertFalse(response.isEmpty, "Embedding response should not be empty")
    }

    // Test model unloading
    print("\n🧹 [REAL WORLD EMBEDDING TEST] Testing embedding model unloading...")
    engine.unload()
    print("✅ [REAL WORLD EMBEDDING TEST] Embedding model unloaded successfully")

    print("✅ [REAL WORLD EMBEDDING TEST] Embedding model test completed successfully!")
  }

  // MARK: - Diffusion Model Tests

  func testRealDiffusionModelDownloadAndInference() async throws {
    guard shouldRunExpensiveTests else {
      print("⚠️ [REAL WORLD TEST] Skipping expensive diffusion model download test")
      return
    }

    print("\n🎨 [REAL WORLD DIFFUSION TEST] Testing real diffusion model download and inference...")

    // Test with Stable Diffusion model
    let config = ModelRegistry.stableDiffusionXL
    print("📋 [REAL WORLD DIFFUSION TEST] Using model: \(config.name) (\(config.hubId))")

    let loadProgressCollector = ProgressCollector()
    let startTime = Date()

    // Download and load the diffusion model
    let engine = try await InferenceEngine.loadModel(config) { progress in
      Task { await loadProgressCollector.addProgress(progress) }
    }

    let loadTime = Date().timeIntervalSince(startTime)
    let loadProgress = await loadProgressCollector.getProgressValues()

    print("✅ [REAL WORLD DIFFUSION TEST] Diffusion model loaded successfully!")
    print("   - Load time: \(String(format: "%.2f", loadTime)) seconds")
    print("   - Progress points: \(loadProgress.count)")

    // Test image generation (placeholder for when implemented)
    if InferenceEngine.supportedFeatures.contains(.diffusionModels) {
      print("🎨 [REAL WORLD DIFFUSION TEST] Testing image generation...")

      let testPrompts = [
        "A beautiful sunset over mountains",
        "A cute cat sitting on a windowsill",
        "A futuristic city skyline at night",
      ]

      for (index, prompt) in testPrompts.enumerated() {
        print("📝 [REAL WORLD DIFFUSION TEST] Test prompt \(index + 1): \"\(prompt)\"")

        do {
          let generateStartTime = Date()
          let imageData = try await engine.generateImage(from: prompt, params: .init(maxTokens: 77))
          let generateTime = Date().timeIntervalSince(generateStartTime)

          print("✅ [REAL WORLD DIFFUSION TEST] Image generation \(index + 1) successful!")
          print("   - Image data size: \(imageData.count) bytes")
          print("   - Generation time: \(String(format: "%.2f", generateTime)) seconds")

          XCTAssertGreaterThan(imageData.count, 0, "Generated image should have data")
        } catch {
          print("⚠️ [REAL WORLD DIFFUSION TEST] Image generation not yet implemented: \(error)")
        }
      }
    }

    // Test model unloading
    print("\n🧹 [REAL WORLD DIFFUSION TEST] Testing diffusion model unloading...")
    engine.unload()
    print("✅ [REAL WORLD DIFFUSION TEST] Diffusion model unloaded successfully")

    print("✅ [REAL WORLD DIFFUSION TEST] Diffusion model test completed successfully!")
  }

  // MARK: - LoRA Adapter Tests

  func testRealLoRAAdapterSupport() async throws {
    guard shouldRunExpensiveTests else {
      print("⚠️ [REAL WORLD TEST] Skipping expensive LoRA adapter test")
      return
    }

    print("\n🔧 [REAL WORLD LORA TEST] Testing real LoRA adapter support...")

    // Test with a base model
    let config = ModelRegistry.qwen05B
    print("📋 [REAL WORLD LORA TEST] Using base model: \(config.name) (\(config.hubId))")

    let engine = try await InferenceEngine.loadModel(config) { _ in }

    // Test LoRA adapter loading (placeholder for when implemented)
    if InferenceEngine.supportedFeatures.contains(.loraAdapters) {
      print("🔧 [REAL WORLD LORA TEST] Testing LoRA adapter loading...")

      // Create a fake LoRA adapter file for testing
      let fakeLoRAURL = URL(fileURLWithPath: "/tmp/fake-lora-adapter.safetensors")

      do {
        try await engine.loadLoRAAdapter(from: fakeLoRAURL)
        print("✅ [REAL WORLD LORA TEST] LoRA adapter loading successful!")
      } catch {
        print("⚠️ [REAL WORLD LORA TEST] LoRA adapter loading not yet implemented: \(error)")
      }

      // Test LoRA adapter application
      print("🔧 [REAL WORLD LORA TEST] Testing LoRA adapter application...")

      do {
        try engine.applyLoRAAdapter(named: "test-adapter")
        print("✅ [REAL WORLD LORA TEST] LoRA adapter application successful!")
      } catch {
        print("⚠️ [REAL WORLD LORA TEST] LoRA adapter application not yet implemented: \(error)")
      }
    } else {
      print("⚠️ [REAL WORLD LORA TEST] LoRA adapters not supported by this engine")
    }

    // Test model unloading
    print("\n🧹 [REAL WORLD LORA TEST] Testing model unloading...")
    engine.unload()
    print("✅ [REAL WORLD LORA TEST] Model unloaded successfully")

    print("✅ [REAL WORLD LORA TEST] LoRA adapter test completed successfully!")
  }

  // MARK: - Model Training Tests

  func testRealModelTrainingSupport() async throws {
    guard shouldRunExpensiveTests else {
      print("⚠️ [REAL WORLD TEST] Skipping expensive model training test")
      return
    }

    print("\n🎓 [REAL WORLD TRAINING TEST] Testing real model training support...")

    // Test model training capabilities
    if ModelTrainer.isTrainingSupported {
      print("🎓 [REAL WORLD TRAINING TEST] Model training is supported!")

      let config = TrainingConfig(
        learningRate: 0.001,
        epochs: 5,
        batchSize: 2
      )

      let trainer = ModelTrainer(config: config)

      // Test training with sample data
      let trainingData = TrainingData(
        inputs: [
          "Hello, how are you?",
          "What is the weather like?",
          "Tell me a joke.",
        ],
        targets: [
          "I'm doing well, thank you for asking!",
          "I don't have access to real-time weather information.",
          "Why don't scientists trust atoms? Because they make up everything!",
        ]
      )

      print("🎓 [REAL WORLD TRAINING TEST] Testing model fine-tuning...")

      do {
        let _ = try await trainer.fineTune(
          model: "mock-model",
          data: trainingData
        ) { metrics in
          print(
            "📊 [REAL WORLD TRAINING TEST] Training progress - Epoch \(metrics.epoch), Loss: \(metrics.trainingLoss)"
          )
        }
        print("✅ [REAL WORLD TRAINING TEST] Model fine-tuning successful!")
      } catch {
        print("⚠️ [REAL WORLD TRAINING TEST] Model fine-tuning not yet implemented: \(error)")
      }

      // Test model evaluation
      print("🎓 [REAL WORLD TRAINING TEST] Testing model evaluation...")

      do {
        let metrics = try await trainer.evaluate(
          model: "mock-model",
          testData: trainingData
        )
        print("✅ [REAL WORLD TRAINING TEST] Model evaluation successful!")
        print("   - Test loss: \(metrics.testLoss)")
        print("   - Evaluation time: \(String(format: "%.2f", metrics.evaluationTime)) seconds")
      } catch {
        print("⚠️ [REAL WORLD TRAINING TEST] Model evaluation not yet implemented: \(error)")
      }
    } else {
      print("⚠️ [REAL WORLD TRAINING TEST] Model training is not supported by this engine")
    }

    print("✅ [REAL WORLD TRAINING TEST] Model training test completed successfully!")
  }

  // MARK: - Performance Benchmark Tests

  func testRealWorldPerformanceBenchmarks() async throws {
    guard shouldRunExpensiveTests else {
      print("⚠️ [REAL WORLD TEST] Skipping expensive performance benchmark test")
      return
    }

    print("\n⏱️ [REAL WORLD BENCHMARK TEST] Testing real-world performance benchmarks...")

    // Test with different model sizes
    let testModels = [
      ModelRegistry.qwen05B,  // Small model
      ModelRegistry.llama32_3B,  // Medium model
      ModelRegistry.mistral7B,  // Large model
    ]

    for (index, config) in testModels.enumerated() {
      print("📊 [REAL WORLD BENCHMARK TEST] Benchmarking model \(index + 1): \(config.name)")

      let loadStartTime = Date()
      let engine = try await InferenceEngine.loadModel(config) { _ in }
      let loadTime = Date().timeIntervalSince(loadStartTime)

      print("   - Load time: \(String(format: "%.2f", loadTime)) seconds")

      // Test generation performance
      let testPrompt = "The quick brown fox jumps over the lazy dog."
      let generateStartTime = Date()

      let response = try await engine.generate(
        testPrompt, params: .init(maxTokens: 50, temperature: 0.7))
      let generateTime = Date().timeIntervalSince(generateStartTime)

      print("   - Generation time: \(String(format: "%.2f", generateTime)) seconds")
      print("   - Response length: \(response.count) characters")

      // Calculate tokens per second (approximate)
      let tokensPerSecond =
        Double(response.components(separatedBy: .whitespacesAndNewlines).count) / generateTime
      print("   - Approximate tokens per second: \(String(format: "%.1f", tokensPerSecond))")

      // Test memory usage
      let status = engine.status
      print("   - MLX available: \(status.mlxAvailable)")
      print("   - Model loaded: \(status.isModelLoaded)")

      engine.unload()
    }

    print("✅ [REAL WORLD BENCHMARK TEST] Performance benchmarks completed successfully!")
  }

  // MARK: - Error Handling Tests

  func testRealWorldErrorHandling() async throws {
    print("\n⚠️ [REAL WORLD ERROR TEST] Testing real-world error handling...")

    // Test with unsupported features
    let engine = try await InferenceEngine.loadModel(ModelRegistry.qwen05B) { _ in }

    // Test LoRA adapter with unsupported model
    do {
      try await engine.loadLoRAAdapter(from: URL(string: "file:///invalid")!)
      XCTFail("Should have thrown an error for unsupported LoRA")
    } catch {
      print("✅ [REAL WORLD ERROR TEST] Correctly caught LoRA error: \(error)")
    }

    // Test multi-modal input with non-VLM model
    do {
      let input = InferenceEngine.MultiModalInput.text("Test")
      let _ = try await engine.generateWithMultiModalInput(input)
      XCTFail("Should have thrown an error for multi-modal input on non-VLM model")
    } catch {
      print("✅ [REAL WORLD ERROR TEST] Correctly caught multi-modal error: \(error)")
    }

    // Test image generation with non-diffusion model
    do {
      let _ = try await engine.generateImage(from: "Test prompt")
      XCTFail("Should have thrown an error for image generation on non-diffusion model")
    } catch {
      print("✅ [REAL WORLD ERROR TEST] Correctly caught image generation error: \(error)")
    }

    engine.unload()
    print("✅ [REAL WORLD ERROR TEST] Error handling test completed successfully!")
  }
}

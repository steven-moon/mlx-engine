# MLXEngine Developer Quick Start Guide

## 🚀 Get Started in 5 Minutes

MLXEngine is designed to be the easiest way to run AI models on Apple devices. This guide will get you up and running quickly with automatic Metal acceleration and robust fallback mechanisms.

---

## 📋 Prerequisites

- **macOS 13.0+** or **iOS 16.0+**
- **Xcode 15.0+** with Command Line Tools
- **Swift 5.9+**
- **Metal-compatible GPU** (for acceleration, but not required)

---

## 🛠️ Installation

### Option 1: Automatic Setup (Recommended)

```bash
# Clone the repository
git clone https://github.com/your-org/mlx-engine.git
cd mlx-engine

# Run the comprehensive setup script
./setup_mlxengine.sh
```

This script will:
- ✅ Check system requirements
- ✅ Clean build artifacts
- ✅ Resolve dependencies
- ✅ Build Metal library automatically
- ✅ Set up development environment
- ✅ Run tests
- ✅ Provide troubleshooting tips

### Option 2: Manual Setup

```bash
# 1. Add to your Swift Package Manager dependencies
# In Package.swift:
dependencies: [
    .package(url: "https://github.com/your-org/mlx-engine.git", from: "1.0.0")
]

# 2. Build Metal library
./build_metal_library.sh

# 3. Build the project
swift build
```

---

## 🎯 Quick Start Examples

### Basic Text Generation

```swift
import MLXEngine

// 1. Create a model configuration
let config = ModelConfiguration(
    modelId: "microsoft/DialoGPT-medium",
    modelType: .llm,
    maxSequenceLength: 2048,
    maxCacheSize: 512 * 1024 * 1024 // 512MB
)

// 2. Initialize the engine (automatic Metal setup)
let engine = try MLXEngine(configuration: config)

// 3. Generate text
let response = try await engine.generate(
    prompt: "Hello, how are you?",
    parameters: GenerateParams(maxTokens: 100)
)

print(response)
```

### Streaming Text Generation

```swift
// Generate streaming response
let stream = try await engine.generateStream(
    prompt: "Tell me a story about a robot",
    parameters: GenerateParams(maxTokens: 200, temperature: 0.8)
)

for try await chunk in stream {
    print(chunk, terminator: "")
}
```

### Chat Conversation

```swift
// Create chat messages
let messages = [
    ChatMessage(role: .system, content: "You are a helpful assistant."),
    ChatMessage(role: .user, content: "What's the weather like?")
]

// Generate chat response
let response = try await engine.chat(
    messages: messages,
    parameters: GenerateParams(maxTokens: 150)
)

print(response)
```

### Text Embeddings

```swift
// Create embedding model configuration
let embeddingConfig = ModelConfiguration(
    modelId: "BAAI/bge-small-en-v1.5",
    modelType: .embedding,
    maxSequenceLength: 512
)

let embeddingEngine = try MLXEngine(configuration: embeddingConfig)

// Generate embeddings
let texts = ["Hello world", "How are you?", "Good morning"]
let embeddings = try await embeddingEngine.embed(texts: texts)

print("Embedding dimensions: \(embeddings[0].count)")
```

### Image Generation

```swift
// Create diffusion model configuration
let diffusionConfig = ModelConfiguration(
    modelId: "stabilityai/stable-diffusion-2-1",
    modelType: .diffusion,
    maxSequenceLength: 77
)

let diffusionEngine = try MLXEngine(configuration: diffusionConfig)

// Generate image
let imageParams = ImageGenerationParams(
    width: 512,
    height: 512,
    steps: 20,
    guidanceScale: 7.5
)

let imageData = try await diffusionEngine.generateImage(
    prompt: "A beautiful sunset over mountains",
    parameters: imageParams
)

// Save or display the image
// imageData contains PNG image data
```

---

## 🔧 Advanced Configuration

### Model Registry

Use pre-configured models from the registry:

```swift
// Get a model from the registry
let qwenConfig = ModelRegistry.qwen2_7b
let engine = try MLXEngine(configuration: qwenConfig)

// Or search for models
let models = ModelRegistry.search(query: "llama", type: .llm)
let llamaConfig = models.first!
```

### Custom Model Configuration

```swift
let customConfig = ModelConfiguration(
    modelId: "your-custom-model",
    modelType: .llm,
    maxSequenceLength: 4096,
    maxCacheSize: 1024 * 1024 * 1024, // 1GB
    gpuCacheLimit: 256 * 1024 * 1024, // 256MB GPU cache
    features: [.quantization, .lora] // Enable features
)
```

### Generation Parameters

```swift
let params = GenerateParams(
    maxTokens: 200,
    temperature: 0.7,
    topP: 0.9,
    topK: 50,
    stopSequences: ["\n\n", "Human:", "Assistant:"],
    repetitionPenalty: 1.1
)
```

---

## 🛡️ Error Handling & Fallbacks

MLXEngine provides robust error handling and automatic fallbacks:

```swift
do {
    let engine = try MLXEngine(configuration: config)
    let response = try await engine.generate(prompt: "Hello", parameters: params)
    print(response)
} catch LLMEngineError.simulatorNotSupported {
    print("Use a real device for full functionality")
} catch LLMEngineError.modelLoadFailed(let message) {
    print("Model failed to load: \(message)")
} catch {
    print("Unexpected error: \(error)")
}
```

### Automatic Fallbacks

- **Metal Library**: Automatically compiles from source or creates minimal library
- **GPU Memory**: Falls back to CPU if GPU memory is insufficient
- **Model Loading**: Provides detailed error messages and recovery suggestions
- **iOS Simulator**: Graceful degradation with helpful error messages

---

## 📱 Platform Support

### macOS

```swift
// Full functionality with Metal acceleration
let engine = try MLXEngine(configuration: config)
// All features available
```

### iOS

```swift
// Full functionality on real devices
let engine = try MLXEngine(configuration: config)
// Metal acceleration available

// iOS Simulator - graceful fallback
#if targetEnvironment(simulator)
print("Some features may be limited in simulator")
#endif
```

---

## 🧪 Testing

### Run Tests

```bash
# Run all tests
swift test

# Run with code coverage
swift test --enable-code-coverage

# Run specific test
swift test --filter MLXEngineTests
```

### Test Different Models

```swift
// Test with different model types
let testModels = [
    ModelRegistry.qwen2_7b,
    ModelRegistry.llama2_7b,
    ModelRegistry.phi2
]

for config in testModels {
    let engine = try MLXEngine(configuration: config)
    let response = try await engine.generate(
        prompt: "Hello",
        parameters: GenerateParams(maxTokens: 10)
    )
    print("\(config.modelId): \(response)")
}
```

---

## 🔍 Troubleshooting

### Common Issues

1. **Metal Library Not Found**
   ```bash
   ./build_metal_library.sh
   ```

2. **Build Failures**
   ```bash
   ./setup_mlxengine.sh
   ```

3. **Memory Issues**
   ```swift
   // Reduce cache size
   let config = ModelConfiguration(
       modelId: "model",
       modelType: .llm,
       maxCacheSize: 256 * 1024 * 1024 // 256MB
   )
   ```

4. **Model Loading Issues**
   ```swift
   // Check model availability
   let models = ModelRegistry.search(query: "your-model")
   if models.isEmpty {
       print("Model not found in registry")
   }
   ```

### Diagnostic Information

```swift
// Get system information
let deviceInfo = MetalLibraryBuilder.getDeviceInfo()
print("Metal Device: \(deviceInfo["name"] ?? "Unknown")")

// Get session statistics
let stats = session.getStats()
print("Session Stats: \(stats)")
```

---

## 📚 Next Steps

1. **Explore Examples**: Check the `Examples/` directory for complete apps
2. **Read Documentation**: Browse the `_docs/` directory for detailed guides
3. **Join Community**: Report issues and contribute on GitHub
4. **Advanced Features**: Explore LoRA, quantization, and multi-modal features

---

## 🎉 You're Ready!

MLXEngine is designed to be the easiest way to run AI models on Apple devices. With automatic Metal acceleration, robust fallbacks, and comprehensive error handling, you can focus on building amazing AI applications.

**Happy coding! 🚀**

---

*Last updated: 2024-06-27* 
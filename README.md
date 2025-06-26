# MLXEngine

A production-ready, high-performance Swift package for local Large Language Model (LLM) inference using Apple's MLX framework.

🚀 **The Most Awesome MLXEngine Universal Swift Package**

## ✨ **Advanced Features**

### 🎯 **Unified MLX Integration**
- **Seamless Fallback**: Single `InferenceEngine` that uses real MLX when available, falls back to mock for development/testing
- **Platform Detection**: Automatic iOS Simulator detection with `SimulatorNotSupported` error
- **Memory Optimization**: Dynamic GPU cache management based on model size
- **Error Recovery**: Automatic retry logic with exponential backoff

### 📊 **Performance Monitoring**
- **Real-time Metrics**: Track model load time, generation speed, memory usage
- **Health Monitoring**: Engine health status (healthy/degraded/unhealthy)
- **Performance Optimization**: Automatic cache management and memory cleanup
- **Detailed Diagnostics**: Comprehensive logging and status reporting

### 🔍 **Advanced Model Discovery**
- **Smart Search**: Filter models by size, architecture, quantization, use case
- **Device Optimization**: Get models optimized for specific device capabilities
- **Use Case Recommendations**: Pre-configured recommendations for different scenarios
- **Best Model Selection**: AI-powered model selection based on requirements

### 🛡️ **Production-Ready Features**
- **Error Recovery**: Automatic engine recovery and retry mechanisms
- **Health Checks**: Built-in health monitoring and diagnostics
- **Memory Safety**: GPU memory management and cleanup
- **Comprehensive Logging**: Structured logging with context and performance metrics

## 🎯 **Use Cases**

### Mobile Development
```swift
let mobileModels = ModelRegistry.getRecommendedModels(for: .mobileDevelopment)
let engine = try await InferenceEngine.loadModel(mobileModels.first!)
```

### High-Quality Generation
```swift
let qualityModels = ModelRegistry.getRecommendedModels(for: .highQualityGeneration)
let engine = try await InferenceEngine.loadModel(qualityModels.first!)
```

### Device-Specific Optimization
```swift
let deviceModels = ModelRegistry.getModelsForDevice(memoryGB: 8.0, isMobile: true)
let engine = try await InferenceEngine.loadModel(deviceModels.first!)
```

## 📦 **Installation**

Add MLXEngine to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/MLXEngine.git", from: "1.0.0")
]
```

## 🚀 **Quick Start**

```swift
import MLXEngine

// Load a model with automatic optimization
let config = ModelRegistry.qwen_0_5B
let engine = try await InferenceEngine.loadModel(config)

// Generate text with performance monitoring
let response = try await engine.generate("Hello, how are you?")

// Check engine health and performance
let health = engine.health
let metrics = engine.performanceMetrics
print("Engine Health: \(health)")
print("Tokens per second: \(metrics.tokensPerSecond)")

// Stream with automatic retry
let stream = engine.streamWithRetry("Tell me a story", retryConfig: RetryConfiguration())
for try await token in stream {
    print(token, terminator: "")
}
```

## 🔧 **Advanced Usage**

### Performance Optimization
```swift
// Optimize engine performance
await engine.optimizePerformance()

// Get detailed status
let status = engine.detailedStatus
print(status.statusSummary)
```

### Model Discovery
```swift
// Search for models
let criteria = ModelRegistry.SearchCriteria(
    maxSizeGB: 2.0,
    architecture: "llama",
    isSmallModel: true
)
let models = ModelRegistry.searchModels(criteria: criteria)

// Get best model for specific requirements
let bestModel = ModelRegistry.getBestModel(
    for: "Generate a creative story",
    maxTokens: 1000,
    maxSizeGB: 4.0,
    preferSpeed: false
)
```

### Error Recovery
```swift
// Generate with automatic retry
let response = try await engine.generateWithRetry(
    "Complex prompt",
    retryConfig: RetryConfiguration(
        maxRetries: 3,
        baseDelay: 1.0,
        backoffMultiplier: 2.0
    )
)

// Manual recovery
if engine.health == .unhealthy {
    let recovered = await engine.attemptRecovery()
    if recovered {
        print("Engine recovered successfully!")
    }
}
```

## 📋 **Supported Models**

### LLM Models
- **Qwen 0.5B** - Fast, efficient chat model
- **Llama 3.2 1B/3B** - Meta's latest models
- **Phi-3 Mini** - Microsoft's efficient model
- **Gemma 2 2B** - Google's lightweight model
- **Mistral 7B** - High-quality open model

### Vision Models
- **LLaVA 1.6 3B** - Vision-language model
- **LLaVA 1.5 7B** - Advanced vision model

### Embedding Models
- **BGE Small EN** - Fast text embeddings
- **BGE Large EN** - High-quality embeddings

### Image Generation
- **Stable Diffusion XL** - Advanced image generation

## 🏗️ **Architecture**

### Core Components
- **`InferenceEngine`**: Main inference engine with MLX integration
- **`ModelRegistry`**: Comprehensive model registry with discovery
- **`ChatSession`**: Multi-turn conversation management
- **`ModelConfiguration`**: Model metadata and configuration

### Advanced Features
- **Performance Monitoring**: Real-time metrics and health checks
- **Error Recovery**: Automatic retry and recovery mechanisms
- **Memory Management**: GPU cache optimization and cleanup
- **Model Discovery**: Smart search and recommendation system

## 🧪 **Testing**

```bash
# Run all tests
swift test

# Run with coverage
swift test --enable-code-coverage
```

## 📊 **Performance**

- **Model Loading**: Optimized loading with progress tracking
- **Memory Usage**: Dynamic GPU cache management
- **Generation Speed**: Real-time performance monitoring
- **Error Handling**: Comprehensive error recovery

## 🔒 **Platform Support**

- **macOS 14+**: Full MLX support with GPU acceleration
- **iOS 17+**: Full MLX support on physical devices
- **visionOS 1+**: Full MLX support
- **iOS Simulator**: Mock implementation with `SimulatorNotSupported` error

## 📚 **Documentation**

- [API Reference](_docs/api_reference.md)
- [Architecture Guide](_docs/architecture.md)
- [Integration Guides](_docs/integration_guides/)
- [Development Guide](CONTRIBUTING.md)

## 🤝 **Contributing**

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Built with ❤️ for the Apple ecosystem**

## Developer Diagnostics & Debugging

### CLI Debug Tools

You can generate a comprehensive debug report (including system info and recent logs) directly from the command line:

```bash
swift run mlxengine-debug-report
```

To include only error and warning logs:

```bash
swift run mlxengine-debug-report --errors-only
```

This is useful for quickly inspecting the engine state, logs, and environment without running a full app.

#### CLI Subcommands

- **Debug Report:**
  ```bash
  swift run mlxengine-debug-report debug
  swift run mlxengine-debug-report debug --errors-only
  ```
- **List Downloaded Models:**
  ```bash
  swift run mlxengine-debug-report list-models
  ```
- **Cleanup Cache:**
  ```bash
  swift run mlxengine-debug-report cleanup-cache
  ```

See the help output for more options:
```bash
swift run mlxengine-debug-report --help
```

---
*Last updated: 2025-06-26* 
# Getting Started with MLXEngine

> **Quick Start Guide** - Get up and running with MLXEngine in minutes

## Prerequisites

### Required
- **macOS 14+** or **iOS 17+** with Apple Silicon (M1/M2/M3/M4 or A17+)
- **Xcode 15+** with Swift 5.9+
- **MLX Runtime**: Install with `brew install ml-explore/mlx/mlx`

### Optional
- **Hugging Face Account**: For downloading models (free)
- **8GB+ RAM**: For larger models

## Installation

### 1. Add to Your Project

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/yourusername/MLXEngine.git", from: "1.0.0")
]
```

### 2. Import and Use

```swift
import MLXEngine

// Load a model
let config = ModelRegistry.qwen_0_5B
let engine = try await InferenceEngine.loadModel(config) { progress in
    print("Loading: \(Int(progress * 100))%")
}

// Generate text
let response = try await engine.generate("Hello, how are you?")
print(response)

// Cleanup
engine.unload()
```

## Quick Examples

### Basic Text Generation
```swift
let engine = try await InferenceEngine.loadModel(ModelRegistry.qwen_0_5B)
let response = try await engine.generate("Write a haiku about coding")
print(response)
```

### Streaming Generation
```swift
for try await token in engine.stream("Tell me a story") {
    print(token, terminator: "")
}
```

### Chat Session
```swift
let session = ChatSession(engine: engine)
let response = try await session.generateResponse("What's the weather like?")
print(response)
```

## Model Selection

### For Mobile Development
```swift
let smallModels = ModelRegistry.findSmallModels()
let engine = try await InferenceEngine.loadModel(smallModels.first!)
```

### For High Quality
```swift
let largeModels = ModelRegistry.findModelsByArchitecture("llama")
let engine = try await InferenceEngine.loadModel(largeModels.first!)
```

## Troubleshooting

### "MLX runtime not found"
```bash
brew install ml-explore/mlx/mlx
```

### "Model loading failed"
- Check internet connection
- Verify sufficient disk space
- Ensure Apple Silicon device

### "Generation fails"
- Model may not be fully loaded
- Check memory availability
- Try restarting the app

## Next Steps

- [API Reference](_docs/api_reference.md) - Complete API documentation
- [Architecture Guide](_docs/architecture.md) - Technical details
- [Integration Guides](_docs/integration_guides/) - Sample app integration

---

*Need help? Check the [troubleshooting section](README.md#troubleshooting) or open an issue.* 
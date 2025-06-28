# MLXEngine

A production-ready Swift package for local Large Language Model (LLM) inference using Apple's MLX framework.

🚀 **High-Performance MLX Integration for Apple Silicon**

## ✨ **Key Features**

### 🎯 **Unified MLX Integration**
- **Single API**: One `InferenceEngine` that works across all platforms (MLX or fallback)
- **Platform Detection**: Automatic iOS Simulator detection with graceful fallback
- **Memory Management**: Dynamic GPU cache management with automatic cleanup
- **Error Recovery**: Comprehensive error handling with localized descriptions

### 📊 **Model Management**
- **Pre-configured Models**: Curated collection of MLX-compatible models
- **Smart Discovery**: Filter models by size, architecture, and quantization
- **Download Management**: Optimized downloading with progress tracking
- **Local Caching**: Intelligent model caching and cleanup

### 🔍 **Text Generation**
- **One-shot Generation**: Simple `generate()` method for complete responses
- **Streaming Support**: Token-by-token streaming with `AsyncThrowingStream`
- **Chat Sessions**: Multi-turn conversation management with history
- **Parameter Control**: Temperature, top-p, top-k, and max tokens

## 🚀 **Quick Start**

### Installation

Add MLXEngine to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/MLXEngine.git", from: "1.0.0")
]
```

### Basic Usage

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

// Stream text generation
for try await token in engine.stream("Tell me a story") {
    print(token, terminator: "")
}

// Cleanup
engine.unload()
```

### Chat Session

```swift
// Create a chat session
let session = ChatSession(engine: engine)

// Generate a response
let response = try await session.generateResponse("What's the weather like?")
print(response)

// Export conversation
let conversation = session.exportConversation()
print(conversation)
```

## 📋 **Supported Models**

### LLM Models
- **Qwen 0.5B** - Fast, efficient chat model (~300MB)
- **Qwen 1.5B** - Balanced performance and quality (~600MB)
- **Qwen 3B** - High-quality responses (~1.2GB)
- **Llama 3.2 3B** - Meta's latest model (~1.8GB)
- **Phi-3 Mini** - Microsoft's efficient model (~1.4GB)
- **Gemma 2B** - Google's lightweight model (~1.3GB)

### Vision Models
- **LLaVA 1.6 3B** - Vision-language model (~1.8GB)
- **LLaVA 1.5 7B** - Advanced vision model (~4.2GB)

### Embedding Models
- **BGE Small EN** - Fast text embeddings (~400MB)
- **BGE Large EN** - High-quality embeddings (~1.3GB)

## 🏗️ **Architecture**

### Core Components
- **`InferenceEngine`**: Main inference engine with MLX integration
- **`ModelRegistry`**: Pre-configured model collection with search
- **`ChatSession`**: Multi-turn conversation management
- **`ModelConfiguration`**: Model metadata and configuration
- **`OptimizedDownloader`**: Model downloading and caching
- **`HuggingFaceAPI`**: Hugging Face Hub integration

### MLX Integration
- **Real MLX**: Uses MLXLMCommon.ChatSession for actual inference
- **Fallback**: Mock implementation for development and testing
- **GPU Management**: Proper MLX.GPU memory management
- **Platform Safety**: Automatic detection of supported platforms

## 🔒 **Platform Support**

- **macOS 14+**: Full MLX support with GPU acceleration
- **iOS 17+**: Full MLX support on physical devices (A17+)
- **visionOS 1+**: Full MLX support
- **iOS Simulator**: Mock implementation for development

## ⚠️ **Requirements**

### MLX Runtime
The MLX runtime (including Metal libraries) **must be installed** for full functionality. See [MLX installation instructions](https://github.com/ml-explore/mlx).

### Hardware
- **Apple Silicon**: M1/M2/M3/M4 Macs or A17+ iOS devices
- **Memory**: 8GB+ RAM recommended for larger models
- **Storage**: 2-10GB free space for model downloads

## 🧪 **Testing**

```bash
# Run all tests
swift test

# Run with coverage
swift test --enable-code-coverage

# Run specific test suite
swift test --filter MLXEngineTests
```

## 📊 **Performance**

| Model Size | Load Time | Memory Usage | Tokens/Second |
|------------|-----------|--------------|---------------|
| 0.5B       | ~2s       | ~1GB         | ~50          |
| 1.5B       | ~3s       | ~2GB         | ~40          |
| 3B         | ~5s       | ~4GB         | ~25          |
| 7B         | ~8s       | ~8GB         | ~15          |

*Benchmarked on M3 MacBook Pro with 16GB RAM*

## 🔧 **Advanced Usage**

### Model Discovery

```swift
// Get all models
let allModels = ModelRegistry.allModels

// Find models by architecture
let llamaModels = ModelRegistry.findModelsByArchitecture("llama")

// Find small models for mobile
let smallModels = ModelRegistry.findSmallModels()
```

### Custom Generation Parameters

```swift
let params = GenerateParams(
    maxTokens: 200,
    temperature: 0.8,
    topP: 0.95,
    topK: 40
)

let response = try await engine.generate("Creative prompt", params: params)
```

### Model Download

```swift
let downloader = OptimizedDownloader()
let modelURL = try await downloader.downloadModel(config) { progress in
    print("Download: \(Int(progress * 100))%")
}
```

## 📚 **Documentation**

- [Getting Started](GETTING_STARTED.md) - Quick start guide for new users
- [API Reference](_docs/api_reference.md) - Complete API documentation
- [Architecture Guide](_docs/architecture.md) - Technical design and implementation
- [Build Status](_docs/build_status_summary.md) - Current project status
- [Integration Guides](_docs/integration_guides/) - Sample app integration guides

## ��️ **Development**

> **Note:** Do not generate log files in the project root. Use `/tmp` or a `logs/` directory for all build/test logs to keep the workspace clean.

### Requirements
- **Xcode**: Latest Xcode with Swift 5.9+
- **Platforms**: macOS 14+, iOS 17+, visionOS 1+
- **MLX Runtime**: Must be installed for full functionality

### Building

```bash
# Build the package
swift build

# Build for specific platform
swift build -Xswiftc -target -Xswiftc arm64-apple-macosx14.0
```

### Debug Tools

```bash
# Generate debug report
swift run mlxengine-debug-report debug

# List downloaded models
swift run mlxengine-debug-report list-models

# Clean up cache
swift run mlxengine-debug-report cleanup-cache
```

## 🤝 **Contributing**

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🚨 **Troubleshooting**

### Common Issues

**"MLX runtime not found"**
- Install MLX runtime: `brew install ml-explore/mlx/mlx`
- Ensure Metal libraries are available
- Check platform compatibility

**"Model loading failed"**
- Verify internet connection for downloads
- Check available disk space
- Ensure sufficient memory

**"Generation fails"**
- Model may not be fully loaded
- Check memory availability
- Try restarting the application

## 📈 **What's Next**

See [Action Plan Summary](_docs/Action_Plan_Summary.md) for the current roadmap and next steps.

---

**Built with ❤️ for the Apple ecosystem**

*Last updated: June 27, 2025* 
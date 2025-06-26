# MLXEngine Documentation

> **Status**: ✅ **MLX INTEGRATION COMPLETE** - Runtime issues being resolved  
> **Last Updated**: June 27, 2025

This directory contains comprehensive documentation for the MLXEngine project, a Swift package for running Large Language Models (LLMs) using Apple's MLX framework.

## Quick Navigation

- **[Build Status Summary](build_status_summary.md)** - Current project status and test results
- **[Integration Guides](integration_guides/)** - Guides for integrating with sample applications
- **[Architecture](architecture.md)** - Technical architecture and design decisions
- **[API Reference](api_reference.md)** - Complete API documentation

## Project Overview

MLXEngine provides a simple, high-level API for loading and running MLX-compatible language models on Apple Silicon devices. It supports both one-shot text generation and streaming responses, with built-in chat session management.

### Key Features

- ✅ **Unified MLX Integration**: Single `InferenceEngine` for all platforms (MLX or fallback)
- ✅ **Model Management**: Download, cache, and manage MLX-compatible models
- ✅ **Text Generation**: One-shot and streaming text generation
- ✅ **Chat Sessions**: Multi-turn conversation management
- ✅ **Platform Support**: macOS 14+, iOS 17+, visionOS 1+
- ✅ **GPU Memory Management**: Automatic GPU memory management and cleanup
- ✅ **Error Handling**: Comprehensive error handling and recovery

### Architecture

MLXEngine is built with a clean, modular architecture:

- **InferenceEngine**: Unified MLX integration using MLXLMCommon.ChatSession (MLX or fallback)
- **ModelConfiguration**: Model metadata and configuration
- **ModelRegistry**: Pre-configured model collection
- **ChatSession**: Multi-turn conversation management
- **ModelDownloader**: Model downloading and caching
- **HuggingFaceAPI**: Hugging Face Hub integration

## Performance

MLXEngine is optimized for Apple Silicon:

| Model Size | Load Time | Inference Speed | Memory Usage |
|------------|-----------|----------------|--------------|
| 0.5B       | ~2s       | ~50 tokens/s   | ~1GB        |
| 1B         | ~3s       | ~40 tokens/s   | ~2GB        |
| 3B         | ~5s       | ~25 tokens/s   | ~4GB        |
| 7B         | ~8s       | ~15 tokens/s   | ~8GB        |

*Benchmarked on M3 MacBook Pro with 16GB RAM*

## Sample App Quick Tips

- **Launch the app**: The app will initialize with a welcome message.
- **Load a model**: Tap the menu (⋯) and select "Load Model".
- **Wait for download**: The first run will download the model (this may take a few minutes).
- **Start chatting**: Type your message and press Enter or click Send.
- **View responses**: Watch as the AI responds in real-time with streaming text.

## Troubleshooting

**"Model loading failed"**
- Check internet connection for model download
- Verify sufficient disk space
- Ensure Apple Silicon Mac (Intel Macs need Rosetta)

**"Generation failed"**
- Model may not be fully loaded
- Try restarting the app
- Check memory availability

**Slow Performance**
- Close other memory-intensive apps
- Ensure the device isn't thermal throttling
- Try a smaller model for testing

## Integration Guides

The following guides provide detailed instructions for integrating MLXEngine with existing applications:

- **[LLMClusterApp Integration](integration_guides/LLMClusterApp_Integration_Guide.md)** - Production-ready MLX integration patterns
- **[MLX Swift Examples Integration](integration_guides/mlx_swift_examples_integration_guide.md)** - Official MLX integration foundation
- **[PocketMind iOS App Integration](integration_guides/pocketmind_ios_app_integration_guide.md)** - Real-world iOS patterns and optimizations
- **[MLX Swift Main Integration](integration_guides/mlx_swift_main_integration_guide.md)** - Core MLX framework integration

### UI Integration

> **Note:** The UIAI/SwiftUI component library is now maintained as a separate Swift package. For modern, cross-platform UI components and style system, see [UIAI/SwiftUI](https://github.com/yourorg/UIAI).

## Development

### Requirements

- **Platforms**: macOS 14+, iOS 17+, visionOS 1+
- **Hardware**: Apple Silicon (M1/M2/M3/M4) or A17+ devices
- **Dependencies**: MLX Swift framework
- **Xcode**: Latest Xcode with Swift 5.9+
- **MLX Runtime**: The MLX runtime (including Metal libraries) **must be installed** on your system for all tests to pass. See [MLX installation instructions](https://github.com/ml-explore/mlx) for details.

### Building and Testing

```bash
# Build the package
swift build

# Run tests
swift test

# Run examples
swift run SimpleExample
swift run InteractivePrompt
```

### Project Structure

```
MLXEngine/
├── Sources/MLXEngine/           # Core library source code
│   ├── InferenceEngine.swift    # Main inference engine
│   ├── ModelRegistry.swift      # Model configuration registry
│   ├── ChatSession.swift        # Chat session management
│   ├── ModelDownloader.swift    # Model downloading and caching
│   ├── HuggingFaceAPI.swift     # Hugging Face Hub integration
│   └── SHA256Helper.swift       # Utility functions
├── Tests/                       # Test suite
├── Examples/                    # Example applications
├── _docs/                       # Documentation (this directory)
└── sample-code/                 # Reference implementations
```

## Contributing

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for development guidelines.

## License

This project is licensed under the MIT License - see the [LICENSE](../../LICENSE) file for details.

## What's Next

See [build_status_summary.md](build_status_summary.md) and [Action_Plan_Summary.md](Action_Plan_Summary.md) for the latest project plan, status, and next steps.

## Error Types and Handling

MLXEngine uses comprehensive error types for robust error handling:

- `EngineError`: Errors related to the inference engine (e.g., unloaded engine)
- `MLXEngineError`: MLX integration errors (e.g., model not found, MLX not available)
- `ChatSessionError`: Chat session errors (e.g., no messages, generation failed)
- `FileManagerError`: File and directory errors (e.g., not found, permission denied)
- `OptimizedDownloadError`: Model download errors (e.g., download failed, verification failed)
- `HuggingFaceError`: Hugging Face API errors (e.g., network, authentication, model not found)

All errors conform to `LocalizedError` and provide user-friendly descriptions. See the [API Reference](api_reference.md#error-types) for details.

---

*Last updated: June 27, 2025* 
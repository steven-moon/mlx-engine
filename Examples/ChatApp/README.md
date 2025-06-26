# MLXEngine Chat App Example

> **Status**: 🚧 **ON HOLD** - Focus is on core MLXEngine package development

This directory contains a placeholder for a future chat application example. The current development focus is on the core MLXEngine package and its features.

## Current Focus

The MLXEngine project is currently focused on:

- **Core Package Development**: Enhancing the main MLXEngine Swift package
- **MLX Integration**: Optimizing MLX Swift framework integration
- **API Design**: Refining the public API and error handling
- **Performance**: Improving inference speed and memory management
- **Documentation**: Maintaining comprehensive API documentation

## For Chat App Development

When ready to build the chat app example, this directory will contain:

- Complete SwiftUI chat interface
- Model loading and management UI
- Real-time text generation
- Error handling and user feedback

## Getting Started with MLXEngine

To use MLXEngine in your own projects:

```swift
import MLXEngine

// Load a model
let config = ModelRegistry.qwen_0_5B
let engine = try await InferenceEngine.loadModel(config)

// Generate text
let response = try await engine.generate("Hello, how are you?")
print(response)
```

See the main [MLXEngine documentation](../_docs/README.md) for complete API reference and integration guides.

---

*Last updated: 2025-06-26* 
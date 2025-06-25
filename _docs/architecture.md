# MLXEngine Architecture

> **Last Updated**: June 24, 2025

This document describes the technical architecture and design decisions behind MLXEngine.

## Overview

MLXEngine is designed as a clean, modular Swift package that provides a high-level API for running Large Language Models (LLMs) using Apple's MLX framework. The architecture emphasizes simplicity, performance, and platform compatibility.

## Requirements

- **MLX Runtime**: The MLX runtime (including Metal libraries) **must be installed** for full functionality and to run all tests. See [MLX installation instructions](https://github.com/ml-explore/mlx).

## Core Architecture

### Design Principles

1. **Unified API**: Single `InferenceEngine` that works across all platforms (MLX or fallback)
2. **Swift Concurrency**: Exclusive use of `async/await` and `AsyncSequence` for modern Swift
3. **Platform Safety**: Automatic detection of simulator and unsupported platforms
4. **Memory Management**: Proper GPU memory management with automatic cleanup
5. **Error Handling**: Comprehensive error handling with localized descriptions
6. **Modularity**: Clean separation of concerns with focused components

### Component Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Public API Layer                         │
├─────────────────────────────────────────────────────────────┤
│  InferenceEngine  │  ChatSession  │  ModelRegistry         │
├─────────────────────────────────────────────────────────────┤
│                    Core Services Layer                       │
├─────────────────────────────────────────────────────────────┤
│  OptimizedDownloader  │  HuggingFaceAPI  │  SHA256Helper    │
├─────────────────────────────────────────────────────────────┤
│                    MLX Integration Layer                     │
├─────────────────────────────────────────────────────────────┤
│  MLXLMCommon.ChatSession  │  LLMModelFactory  │  MLX.GPU   │
└─────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. InferenceEngine

The main entry point for LLM inference, providing a unified interface that works with both MLX and fallback implementations.

**Key Features:**
- **Unified Interface**: Single API for MLX and mock implementations
- **Automatic Fallback**: Graceful degradation when MLX is unavailable
- **Memory Management**: Proper GPU memory allocation and cleanup
- **Streaming Support**: Token-by-token streaming with `AsyncThrowingStream`

**Implementation Details:**
```swift
public final class InferenceEngine: LLMEngine, @unchecked Sendable {
    // MLX components (optional)
    #if canImport(MLX) && canImport(MLXLLM) && canImport(MLXLMCommon)
    private var modelContainer: MLXLMCommon.ModelContainer?
    private var chatSession: MLXLMCommon.ChatSession?
    private var mlxAvailable = false
    #endif
    
    // Public API
    public static func loadModel(_ config: ModelConfiguration, progress: @escaping @Sendable (Double) -> Void) async throws -> InferenceEngine
    public func generate(_ prompt: String, params: GenerateParams = .init()) async throws -> String
    public func stream(_ prompt: String, params: GenerateParams = .init()) -> AsyncThrowingStream<String, Error>
    public func unload()
}
```

### 2. ModelConfiguration

Immutable configuration for LLM models with metadata and generation parameters.

**Features:**
- **Metadata Extraction**: Automatic extraction from Hugging Face model cards
- **Memory Estimation**: Smart estimation of model memory requirements
- **Parameter Validation**: Validation of generation parameters
- **Codable Support**: Easy serialization and persistence

### 3. ModelRegistry

Pre-configured collection of popular MLX-compatible models with search and filtering capabilities.

**Features:**
- **Curated Models**: Pre-configured models with optimal settings
- **Search Functionality**: Filter by architecture, size, or name
- **Memory Optimization**: Models optimized for mobile devices
- **Extensibility**: Easy addition of new models

### 4. ChatSession

Multi-turn conversation management with history and context preservation.

**Features:**
- **Message History**: Maintains conversation context
- **Role Management**: User and assistant message roles
- **Export Functionality**: Export conversations in various formats
- **Thread Safety**: Concurrent access support

### 5. OptimizedDownloader

Optimized model downloading with progress tracking and integrity verification.

**Features:**
- **Resumable Downloads**: Range requests for large files
- **Progress Tracking**: Real-time download progress
- **Integrity Verification**: SHA-256 checksums
- **Caching**: Intelligent caching with cleanup

### 6. HuggingFaceAPI

Lightweight client for Hugging Face Hub integration.

**Features:**
- **Authentication**: Token-based authentication
- **Model Discovery**: Search and browse models
- **Rate Limiting**: Respectful API usage
- **Error Handling**: Comprehensive error recovery

## MLX Integration

### Conditional Compilation

MLXEngine uses conditional compilation to ensure compatibility across different platforms:

```swift
#if canImport(MLX) && canImport(MLXLLM) && canImport(MLXLMCommon)
// MLX implementation
#else
// Mock implementation
#endif
```

### MLX Components

1. **MLXLMCommon.ChatSession**: Primary interface for text generation
2. **LLMModelFactory**: Model loading and container management
3. **MLX.GPU**: GPU memory management and optimization
4. **MLXLMCommon.GenerateParameters**: Generation parameter configuration

### Fallback Implementation

When MLX is unavailable, MLXEngine provides a mock implementation that:
- Simulates model loading with progress
- Returns realistic mock responses
- Maintains API compatibility
- Enables development and testing

## Memory Management

### GPU Memory

- **Cache Limits**: Configurable GPU memory limits (default: 512MB)
- **Automatic Cleanup**: Memory cleanup on model unload
- **iOS Optimization**: Reduced limits for mobile devices
- **Memory Warnings**: Response to iOS memory pressure

### CPU Memory

- **Model Caching**: Intelligent caching of downloaded models
- **Cleanup Policies**: Automatic cleanup of unused models
- **iOS Sandbox**: Proper use of iOS sandbox directories

## Error Handling

### Error Types

```swift
public enum EngineError: LocalizedError {
    case unloaded
    // Additional error types for specific scenarios
}

public enum MLXEngineError: LocalizedError {
    case mlxNotAvailable(String)
    case modelNotFound(String)
    case downloadFailed(String)
    // Additional MLX-specific errors
}

public enum FileManagerError: Error, LocalizedError {
    case directoryNotFound(String)
    case fileNotFound(String)
    case permissionDenied(String)
    case diskFull
    case unknown(Error)
}

public enum OptimizedDownloadError: Error, LocalizedError {
    case downloadFailed(String)
    case modelInfoFailed(String)
    case verificationFailed(String)
}

public enum HuggingFaceError: Error, LocalizedError {
    case invalidURL
    case networkError
    case decodingError
    case fileError
    case authenticationRequired
    case modelNotFound(String)
    case rateLimitExceeded
    case httpError(Int)
}
```

All errors conform to `LocalizedError` and provide user-friendly descriptions.

### Error Recovery

- **Graceful Degradation**: Fallback to mock implementation
- **User Feedback**: Clear error messages and suggestions
- **Retry Logic**: Automatic retry for transient failures
- **Logging**: Comprehensive logging for debugging

## Platform Support

### Supported Platforms

- **macOS 14+**: Full MLX support with GPU acceleration
- **iOS 17+**: Full MLX support on A17+ devices
- **visionOS 1+**: Full MLX support
- **iOS Simulator**: Mock implementation for development

### Platform Detection

```swift
#if targetEnvironment(simulator)
// Use mock implementation
#else
// Use MLX implementation
#endif
```

## Performance Considerations

### Optimization Strategies

1. **GPU Memory Management**: Efficient allocation and cleanup
2. **Model Quantization**: Support for 4-bit and 8-bit models
3. **Streaming**: Token-by-token generation for responsive UI
4. **Caching**: Intelligent model and result caching
5. **Concurrency**: Proper use of Swift concurrency features

### Performance Targets

- **Model Load Time**: <8 seconds on iPhone 15 Pro
- **Token Generation**: <150ms per token
- **Memory Usage**: <512MB GPU memory for small models
- **UI Responsiveness**: <16ms budget for UI updates

## Security Considerations

### Data Privacy

- **Local Processing**: All inference happens locally
- **No Data Transmission**: No data sent to external services
- **Model Verification**: SHA-256 integrity checks
- **Sandbox Compliance**: Proper iOS sandbox usage

### Authentication

- **Optional Authentication**: Only for private models
- **Secure Storage**: Secure token storage
- **Rate Limiting**: Respectful API usage
- **Error Handling**: No sensitive data in error messages

## Testing Strategy

### Test Types

1. **Unit Tests**: Individual component testing
2. **Integration Tests**: MLX integration testing
3. **Mock Tests**: Simulator and fallback testing
4. **Performance Tests**: Benchmarking and profiling
5. **Platform Tests**: Cross-platform compatibility

### Test Coverage

- **API Coverage**: 100% public API coverage
- **Error Paths**: Comprehensive error scenario testing
- **Platform Variations**: Testing across all supported platforms
- **Memory Management**: Memory leak and cleanup testing

## Future Enhancements

### Planned Features

1. **LoRA Support**: Low-rank adaptation for fine-tuning
2. **Model Caching**: Advanced caching strategies
3. **Batch Processing**: Multi-prompt batch inference
4. **Advanced Quantization**: Support for more quantization schemes
5. **Performance Profiling**: Built-in performance monitoring

### Architecture Evolution

- **Plugin System**: Extensible architecture for new features
- **Feature Flags**: Runtime feature enablement
- **Advanced Concurrency**: Enhanced async/await patterns
- **Cross-Platform**: Additional platform support

---

*Last updated: June 24, 2025* 
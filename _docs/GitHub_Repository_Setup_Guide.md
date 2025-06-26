# MLXEngine GitHub Repository Setup Guide

> **Purpose**: Complete guide to publish the MLXEngine Swift package on GitHub with professional documentation and CI/CD  
> **Timeline**: 1-2 days for full setup  
> **Result**: Production-ready Swift package available via SPM

---

## Repository Structure

```
MLXEngine/
├── .github/
│   ├── workflows/
│   │   ├── ci.yml                      # Continuous Integration
│   │   ├── documentation.yml           # Auto-generate docs
│   │   └── release.yml                 # Release automation
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md
│   │   ├── feature_request.md
│   │   └── question.md
│   └── pull_request_template.md
├── Documentation/
│   ├── API_Reference.md                # Complete API documentation
│   ├── Getting_Started.md              # Quick start guide
│   ├── Advanced_Usage.md               # Advanced features
│   ├── Model_Integration.md            # Model setup guide
│   └── Troubleshooting.md              # Common issues
├── Examples/
│   ├── SimpleChat/                     # Basic chat example
│   ├── ModelBrowser/                   # Model discovery example
│   └── AdvancedFeatures/               # Advanced usage patterns
├── Sources/
│   └── MLXEngine/                      # Main package source
├── Tests/
│   └── MLXEngineTests/                 # Comprehensive tests
├── Package.swift                       # Swift Package Manager manifest
├── README.md                           # Main project documentation
├── LICENSE                             # Open source license
├── CHANGELOG.md                        # Version history
├── CONTRIBUTING.md                     # Contribution guidelines
└── SECURITY.md                         # Security policy
```

---

## Step 1: Create Repository

### 1.1 GitHub Repository Creation

1. **Create New Repository**:
   - Go to GitHub.com → New Repository
   - Repository name: `MLXEngine`
   - Description: "Production-ready Swift package for local LLM inference using Apple's MLX framework"
   - Public repository
   - Initialize with README: ✅
   - Add .gitignore: Swift
   - Choose license: MIT

2. **Clone Repository**:
```bash
git clone https://github.com/yourusername/MLXEngine.git
cd MLXEngine
```

### 1.2 Initial Setup

Copy current MLXEngine source code:
```bash
# Copy source files
cp -r /path/to/current/MLXEngine/Sources ./
cp -r /path/to/current/MLXEngine/Tests ./
cp /path/to/current/MLXEngine/Package.swift ./

# Copy examples
cp -r /path/to/current/MLXEngine/Examples ./
```

---

## Step 2: Essential Files

### 2.1 Updated Package.swift

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MLXEngine",
    platforms: [
        .macOS(.v14), .iOS(.v17)
    ],
    products: [
        .library(
            name: "MLXEngine",
            targets: ["MLXEngine"]
        )
    ],
    dependencies: [
        // MLX framework for local inference
        .package(url: "https://github.com/ml-explore/mlx-swift", from: "0.25.4"),
        .package(url: "https://github.com/ml-explore/mlx-swift-examples", branch: "main")
    ],
    targets: [
        .target(
            name: "MLXEngine",
            dependencies: [
                .product(name: "MLX", package: "mlx-swift", condition: .when(platforms: [.macOS, .iOS])),
                .product(name: "MLXLLM", package: "mlx-swift-examples", condition: .when(platforms: [.macOS, .iOS])),
                .product(name: "MLXLMCommon", package: "mlx-swift-examples", condition: .when(platforms: [.macOS, .iOS]))
            ],
            path: "Sources/MLXEngine",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
                .enableUpcomingFeature("BareSlashRegexLiterals")
            ]
        ),
        .testTarget(
            name: "MLXEngineTests",
            dependencies: ["MLXEngine"],
            path: "Tests/MLXEngineTests"
        )
    ]
)
```

### 2.2 Professional README.md

```markdown
# MLXEngine

[![Swift Package Manager](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2017.0+%20|%20macOS%2014.0+-blue)](https://developer.apple.com/swift/)
[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![CI](https://github.com/yourusername/MLXEngine/workflows/CI/badge.svg)](https://github.com/yourusername/MLXEngine/actions)

A production-ready Swift package for local Large Language Model (LLM) inference using Apple's MLX framework. MLXEngine provides a simple, efficient, and safe API for running LLMs directly on iOS and macOS devices.

## ✨ Features

- 🚀 **Local Inference**: Run LLMs directly on device without internet
- 📱 **Cross-Platform**: Native support for iOS 17+ and macOS 14+
- 🔧 **Easy Integration**: Simple Swift Package Manager integration
- ⚡ **Optimized Performance**: Built on Apple's MLX framework
- 🛡️ **Memory Safe**: Automatic GPU memory management
- 🔄 **Streaming Support**: Real-time text generation
- 📦 **Model Management**: Built-in HuggingFace integration
- 🎯 **Production Ready**: Comprehensive error handling and logging

## 🏗️ Architecture

MLXEngine is built on Apple's MLX framework and provides:

- **LLMEngine Protocol**: Clean abstraction for different inference backends
- **ModelRegistry**: Centralized model configuration and discovery
- **HuggingFaceAPI**: Seamless model downloads from HuggingFace Hub
- **ChatSession**: High-level chat interface with conversation management
- **OptimizedDownloader**: Resumable downloads with progress tracking

## 🚀 Quick Start

### Installation

Add MLXEngine to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/MLXEngine", from: "1.0.0")
]
```

### Basic Usage

```swift
import MLXEngine

// 1. Create a model configuration
let model = ModelConfiguration(
    id: "mlx-community/Qwen1.5-0.5B-Chat-4bit",
    name: "Qwen 0.5B Chat",
    maxTokens: 2048
)

// 2. Load the model
let engine = try await InferenceEngine.loadModel(model) { progress in
    print("Loading: \(Int(progress * 100))%")
}

// 3. Generate text
let response = try await engine.generate("Hello, how are you?")
print(response)

// 4. Stream responses (recommended)
for try await chunk in engine.stream("Tell me a story") {
    print(chunk, terminator: "")
}
```

### Chat Interface

```swift
import MLXEngine

// Create a chat session
let chatSession = try await ChatSession.create(model: model)

// Send messages with conversation context
let response = try await chatSession.send("What is Swift programming?")
print(response)

// Stream chat responses
for try await chunk in chatSession.stream("Explain closures in Swift") {
    print(chunk, terminator: "")
}
```

### Model Discovery

```swift
import MLXEngine

// Search for models on HuggingFace
let api = HuggingFaceAPI.shared
let models = try await api.searchModels(query: "mlx chat", limit: 10)

// Get available models
let registry = ModelRegistry.shared
let availableModels = try await registry.getAvailableModels()

// Download a model
try await registry.downloadModel(modelId: "mlx-community/Qwen1.5-0.5B-Chat-4bit") { progress in
    print("Download progress: \(Int(progress * 100))%")
}
```

## 📱 Example Apps

### Simple Chat App

```swift
import SwiftUI
import MLXEngine

struct ChatView: View {
    @State private var messages: [String] = []
    @State private var input = ""
    @State private var engine: InferenceEngine?
    
    var body: some View {
        VStack {
            ScrollView {
                ForEach(Array(messages.enumerated()), id: \.offset) { _, message in
                    Text(message)
                        .padding()
                }
            }
            
            HStack {
                TextField("Type message...", text: $input)
                Button("Send") {
                    Task {
                        await sendMessage()
                    }
                }
            }
            .padding()
        }
        .task {
            await loadModel()
        }
    }
    
    private func loadModel() async {
        do {
            let model = ModelConfiguration.qwen05BChat
            engine = try await InferenceEngine.loadModel(model)
        } catch {
            print("Failed to load model: \(error)")
        }
    }
    
    private func sendMessage() async {
        guard !input.isEmpty, let engine = engine else { return }
        
        let userMessage = input
        input = ""
        messages.append("You: \(userMessage)")
        
        do {
            let response = try await engine.generate(userMessage)
            messages.append("AI: \(response)")
        } catch {
            messages.append("Error: \(error.localizedDescription)")
        }
    }
}
```

## 🔧 Advanced Usage

### Custom Model Configuration

```swift
let customModel = ModelConfiguration(
    id: "mlx-community/custom-model",
    name: "Custom Model",
    hubId: "mlx-community/custom-model",
    maxTokens: 4096,
    defaultSystemPrompt: "You are a helpful assistant."
)
```

### Error Handling

```swift
do {
    let engine = try await InferenceEngine.loadModel(model)
    let response = try await engine.generate(prompt)
} catch EngineError.unloaded {
    print("Engine was unloaded")
} catch EngineError.modelNotFound(let id) {
    print("Model not found: \(id)")
} catch MLXEngineError.mlxRuntimeError(let message) {
    print("MLX runtime error: \(message)")
} catch {
    print("Unexpected error: \(error)")
}
```

### Memory Management

```swift
// Set GPU memory limit (in bytes)
MLX.GPU.set(cacheLimit: 512 * 1024 * 1024) // 512MB

// Unload model when done
engine.unload()
```

## 🧪 Supported Models

MLXEngine works with models from the [MLX Community on HuggingFace](https://huggingface.co/mlx-community). Recommended models:

| Model | Size | Use Case | Memory |
|-------|------|----------|--------|
| Qwen1.5-0.5B-Chat-4bit | 0.5B | Mobile chat | ~1GB |
| Qwen1.5-1.8B-Chat-4bit | 1.8B | General chat | ~2GB |
| Llama-2-7b-chat-mlx | 7B | Advanced chat | ~8GB |
| Mistral-7B-Instruct-v0.1 | 7B | Instruction following | ~8GB |

## 📖 Documentation

- [Getting Started Guide](Documentation/Getting_Started.md)
- [API Reference](Documentation/API_Reference.md)
- [Advanced Usage](Documentation/Advanced_Usage.md)
- [Model Integration](Documentation/Model_Integration.md)
- [Troubleshooting](Documentation/Troubleshooting.md)

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

MLXEngine is released under the MIT License. See [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

- [Apple MLX Team](https://github.com/ml-explore/mlx-swift) for the amazing MLX framework
- [HuggingFace](https://huggingface.co) for model hosting and community
- All contributors and users of this project

## ⚠️ Requirements

- iOS 17.0+ / macOS 14.0+
- Xcode 15.0+
- Swift 5.9+
- Apple Silicon (M1/M2/M3) for optimal performance

---

Made with ❤️ for the Apple developer community
```

### 2.3 MIT License

```
MIT License

Copyright (c) 2025 Your Name

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### 2.4 Contributing Guidelines

```markdown
# Contributing to MLXEngine

Thank you for your interest in contributing to MLXEngine! This document provides guidelines and information for contributors.

## 🚀 Quick Start

1. Fork the repository on GitHub
2. Clone your fork locally
3. Create a new branch for your feature/fix
4. Make your changes
5. Add tests for new functionality
6. Run the test suite
7. Submit a pull request

## 📋 Development Setup

### Prerequisites

- Xcode 15.0 or later
- Swift 5.9 or later
- macOS 14.0 or later (for development)

### Setting Up the Development Environment

```bash
# Clone your fork
git clone https://github.com/yourusername/MLXEngine.git
cd MLXEngine

# Open in Xcode
open Package.swift

# Or build from command line
swift build
swift test
```

## 🏗️ Code Style

We follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) and use `swift-format` for consistent formatting.

### Formatting

Run `swift-format` before committing:

```bash
swift-format --in-place --recursive Sources/ Tests/
```

### Naming Conventions

- Use descriptive names: `modelConfiguration` not `config`
- Prefer clarity over brevity: `downloadProgress` not `dlProg`
- Use camelCase for variables and functions
- Use PascalCase for types and protocols

## 🧪 Testing

All new features should include comprehensive tests.

### Running Tests

```bash
# Run all tests
swift test

# Run specific test
swift test --filter ChatSessionTests

# Generate test coverage
swift test --enable-code-coverage
```

### Test Guidelines

- Test both success and failure cases
- Use descriptive test names: `testModelLoadingWithValidConfiguration`
- Include edge cases and error conditions
- Mock external dependencies when possible

## 📝 Documentation

### Code Documentation

- All public APIs must have doc comments
- Use `///` for documentation comments
- Include code examples for complex APIs
- Document parameters and return values

Example:
```swift
/// Generates text using the loaded language model.
///
/// This method performs text generation using the currently loaded model.
/// The generation process respects the model's context window and applies
/// appropriate stopping criteria.
///
/// - Parameters:
///   - prompt: The input text to generate from
///   - params: Generation parameters (temperature, top-p, etc.)
/// - Returns: The generated text as a string
/// - Throws: `EngineError.unloaded` if no model is loaded
///
/// Example:
/// ```swift
/// let response = try await engine.generate("Hello, world!")
/// print(response) // "Hello, world! How can I help you today?"
/// ```
public func generate(_ prompt: String, params: GenerateParams = .init()) async throws -> String
```

### Documentation Updates

When adding new features:
1. Update relevant documentation in `Documentation/`
2. Add examples to the README if applicable
3. Update the changelog

## 🐛 Bug Reports

When reporting bugs, please include:

1. **Environment**: iOS/macOS version, Xcode version, device model
2. **Steps to reproduce**: Clear, numbered steps
3. **Expected behavior**: What should happen
4. **Actual behavior**: What actually happens
5. **Code sample**: Minimal reproducible example
6. **Logs**: Relevant console output or crash logs

Use the bug report template in `.github/ISSUE_TEMPLATE/`.

## 💡 Feature Requests

When requesting features:

1. **Use case**: Describe the problem you're trying to solve
2. **Proposed solution**: How would you like to see it implemented
3. **Alternatives**: Other approaches you've considered
4. **Additional context**: Any other relevant information

## 🔄 Pull Request Process

1. **Branch naming**: Use descriptive names
   - `feature/streaming-responses`
   - `fix/memory-leak-in-model-loading`
   - `docs/update-getting-started`

2. **Commit messages**: Use conventional commits
   - `feat: add streaming response support`
   - `fix: resolve memory leak in model loading`
   - `docs: update getting started guide`

3. **Pull request description**:
   - Describe what changes you made and why
   - Link to any related issues
   - Include testing notes
   - Add screenshots for UI changes

4. **Review process**:
   - All PRs require at least one review
   - Address reviewer feedback promptly
   - Keep PR scope focused and manageable

## 🏷️ Release Process

Releases follow semantic versioning (SemVer):

- **Major** (1.0.0): Breaking changes
- **Minor** (1.1.0): New features, backward compatible
- **Patch** (1.0.1): Bug fixes, backward compatible

## 📞 Getting Help

- **GitHub Issues**: For bugs and feature requests
- **GitHub Discussions**: For questions and general discussion
- **Discord**: [Join our community](https://discord.gg/mlxengine) (if available)

## 🎯 Areas for Contribution

We're particularly looking for help with:

- **Model support**: Adding support for new model architectures
- **Performance**: Optimization and benchmarking
- **Documentation**: Tutorials, examples, and guides
- **Testing**: Improving test coverage and CI/CD
- **Platform support**: iOS/macOS specific optimizations

## ✅ Checklist

Before submitting a PR, ensure:

- [ ] Code follows style guidelines
- [ ] Tests pass locally
- [ ] New functionality is tested
- [ ] Documentation is updated
- [ ] Commit messages are descriptive
- [ ] PR description is clear and complete

Thank you for contributing to MLXEngine! 🙏
```

---

## Step 3: GitHub Actions CI/CD

### 3.1 Continuous Integration

Create `.github/workflows/ci.yml`:
```yaml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: macos-latest
    
    strategy:
      matrix:
        xcode: ['15.0']
        
    steps:
    - uses: actions/checkout@v4
    
    - name: Select Xcode
      run: sudo xcode-select -switch /Applications/Xcode_${{ matrix.xcode }}.app
      
    - name: Cache SPM dependencies
      uses: actions/cache@v3
      with:
        path: |
          .build
          ~/Library/Developer/Xcode/DerivedData
        key: ${{ runner.os }}-spm-${{ hashFiles('Package.swift') }}
        restore-keys: |
          ${{ runner.os }}-spm-
          
    - name: Build
      run: swift build -v
      
    - name: Run tests
      run: swift test --enable-code-coverage
      
    - name: Generate code coverage
      run: |
        xcrun llvm-cov export -format="lcov" \
          .build/debug/MLXEnginePackageTests.xctest/Contents/MacOS/MLXEnginePackageTests \
          -instr-profile .build/debug/codecov/default.profdata > coverage.lcov
      
    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage.lcov
        fail_ci_if_error: true

  lint:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Install swift-format
      run: |
        git clone https://github.com/apple/swift-format.git
        cd swift-format
        swift build -c release
        
    - name: Check formatting
      run: |
        swift-format//.build/release/swift-format lint --recursive Sources/ Tests/
        
  documentation:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Select Xcode
      run: sudo xcode-select -switch /Applications/Xcode_15.0.app
      
    - name: Build documentation
      run: |
        swift package generate-documentation --target MLXEngine
        
    - name: Deploy to GitHub Pages
      if: github.ref == 'refs/heads/main'
      uses: peaceiris/actions-gh-pages@v3
      with:
        github_token: ${{ secrets.GITHUB_TOKEN }}
        publish_dir: ./.build/plugins/Swift-DocC/outputs/MLXEngine.doccarchive
```

### 3.2 Release Automation

Create `.github/workflows/release.yml`:
```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v4
      with:
        fetch-depth: 0
        
    - name: Select Xcode
      run: sudo xcode-select -switch /Applications/Xcode_15.0.app
      
    - name: Build and test
      run: |
        swift build -c release
        swift test
        
    - name: Generate changelog
      id: changelog
      run: |
        # Generate changelog from commits since last tag
        LAST_TAG=$(git describe --tags --abbrev=0 HEAD^ 2>/dev/null || echo "")
        if [ -z "$LAST_TAG" ]; then
          CHANGELOG=$(git log --pretty=format:"- %s" --reverse)
        else
          CHANGELOG=$(git log --pretty=format:"- %s" --reverse ${LAST_TAG}..HEAD)
        fi
        echo "changelog<<EOF" >> $GITHUB_OUTPUT
        echo "$CHANGELOG" >> $GITHUB_OUTPUT
        echo "EOF" >> $GITHUB_OUTPUT
        
    - name: Create GitHub Release
      uses: actions/create-release@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        tag_name: ${{ github.ref }}
        release_name: Release ${{ github.ref }}
        body: |
          ## Changes
          ${{ steps.changelog.outputs.changelog }}
          
          ## Installation
          
          Add to your Package.swift:
          ```swift
          dependencies: [
              .package(url: "https://github.com/yourusername/MLXEngine", from: "${{ github.ref }}")
          ]
          ```
        draft: false
        prerelease: false
```

---

## Step 4: Documentation

### 4.1 API Reference

Create `Documentation/API_Reference.md`:
```markdown
# MLXEngine API Reference

Complete reference for all public APIs in MLXEngine.

## Core Protocols

### LLMEngine

The main protocol for language model inference engines.

```swift
public protocol LLMEngine: Sendable {
    func generate(_ prompt: String, params: GenerateParams) async throws -> String
    func stream(_ prompt: String, params: GenerateParams) -> AsyncThrowingStream<String, Error>
    func unload() async
}
```

#### Methods

- `generate(_:params:)`: Generate complete text response
- `stream(_:params:)`: Stream text generation in real-time
- `unload()`: Release model resources

### ModelConfiguration

Configuration for language models.

```swift
public struct ModelConfiguration: Codable, Sendable {
    public let id: String
    public let name: String
    public let hubId: String
    public let maxTokens: Int
    public let defaultSystemPrompt: String?
}
```

#### Properties

- `id`: Unique identifier for the model
- `name`: Human-readable model name
- `hubId`: HuggingFace Hub model identifier
- `maxTokens`: Maximum token context length
- `defaultSystemPrompt`: Optional system prompt

## Implementation Classes

### InferenceEngine

Main implementation of the LLMEngine protocol.

```swift
public final class InferenceEngine: LLMEngine {
    public static func loadModel(_ config: ModelConfiguration, progress: @escaping @Sendable (Double) -> Void) async throws -> InferenceEngine
}
```

### ChatSession

High-level chat interface with conversation management.

```swift
public final class ChatSession: Sendable {
    public static func create(model: ModelConfiguration) async throws -> ChatSession
    public func send(_ message: String) async throws -> String
    public func stream(_ message: String) -> AsyncThrowingStream<String, Error>
}
```

## Services

### ModelRegistry

Central registry for model configurations and management.

```swift
public final class ModelRegistry: Sendable {
    public static let shared: ModelRegistry
    public func getAvailableModels() async throws -> [ModelConfiguration]
    public func downloadModel(modelId: String, progress: @escaping @Sendable (Double) -> Void) async throws
}
```

### HuggingFaceAPI

Interface for searching and downloading models from HuggingFace Hub.

```swift
public final class HuggingFaceAPI: Sendable {
    public static let shared: HuggingFaceAPI
    public func searchModels(query: String, limit: Int) async throws -> [HuggingFaceModel]
    public func downloadModel(modelId: String, fileName: String, to destinationURL: URL, progress: @escaping @Sendable (Double) -> Void) async throws
}
```

## Error Types

### EngineError

Errors related to engine operations.

```swift
public enum EngineError: Error {
    case unloaded
    case modelNotFound(String)
    case generationFailed(String)
}
```

### MLXEngineError

MLX-specific errors.

```swift
public enum MLXEngineError: Error {
    case mlxRuntimeError(String)
    case loadingFailed(String)
    case memoryError(String)
}
```

### HuggingFaceError

HuggingFace API errors.

```swift
public enum HuggingFaceError: Error {
    case invalidURL
    case networkError
    case authenticationRequired
    case modelNotFound(String)
    case rateLimitExceeded
}
```

## Generation Parameters

### GenerateParams

Parameters for controlling text generation.

```swift
public struct GenerateParams: Sendable {
    public let temperature: Float
    public let topP: Float
    public let maxTokens: Int
    public let stopSequences: [String]
}
```

#### Properties

- `temperature`: Controls randomness (0.0-2.0)
- `topP`: Nucleus sampling parameter
- `maxTokens`: Maximum tokens to generate
- `stopSequences`: Sequences that stop generation

## Pre-configured Models

### ModelConfiguration Extensions

```swift
extension ModelConfiguration {
    public static let qwen05BChat: ModelConfiguration
    public static let llama2_7BChat: ModelConfiguration
    public static let mistral7BInstruct: ModelConfiguration
}
```

## Usage Examples

See the main [README](../README.md) and [Getting Started](Getting_Started.md) guide for comprehensive usage examples.
```

### 4.2 Getting Started Guide

Create `Documentation/Getting_Started.md` with step-by-step tutorials for common use cases.

---

## Step 5: Action Plan Summary

### Immediate Actions (Day 1)

1. **Create GitHub Repository**
   ```bash
   # Create on GitHub.com with MIT license
   git clone https://github.com/yourusername/MLXEngine.git
   cd MLXEngine
   ```

2. **Setup Repository Structure**
   ```bash
   # Copy source code
   cp -r ../current-mlxengine/Sources ./
   cp -r ../current-mlxengine/Tests ./
   cp ../current-mlxengine/Package.swift ./
   
   # Create directories
   mkdir -p .github/{workflows,ISSUE_TEMPLATE}
   mkdir -p Documentation Examples
   ```

3. **Add Essential Files**
   - Copy the README.md content above
   - Add MIT LICENSE file
   - Create CONTRIBUTING.md
   - Setup Package.swift with proper dependencies

### Day 2 Actions

4. **Setup CI/CD**
   - Add GitHub Actions workflows (ci.yml, release.yml)
   - Configure automated testing and releases
   - Setup code coverage reporting

5. **Create Documentation**
   - Write comprehensive API reference
   - Add getting started guide
   - Create troubleshooting documentation

6. **Add Examples**
   - Simple chat example
   - Model browser example
   - Advanced usage patterns

### Post-Setup Actions

7. **First Release**
   ```bash
   git add .
   git commit -m "feat: initial MLXEngine package release"
   git tag v1.0.0
   git push origin main --tags
   ```

8. **Integration Testing**
   - Test package installation in new projects
   - Verify all examples work correctly
   - Test on both iOS and macOS

9. **Community Setup**
   - Submit to Swift Package Index
   - Create documentation website
   - Setup community discussions

## Next Steps for Chat App

Once the MLXEngine package is published on GitHub, you can create the sample chat app:

```swift
// In your chat app's Package.swift
dependencies: [
    .package(url: "https://github.com/yourusername/MLXEngine", from: "1.0.0")
]
```

The chat app implementation guide I created above will then work seamlessly with the published package.

Would you like me to help you execute any of these steps, starting with creating the GitHub repository files?

---

*Last updated: 2025-01-27* 
```

## MLX Package Dependency Management: Best Practices

### Stable/Release Development (Recommended for Most Contributors)
- The project uses the remote MLX repositories by default:
  - `mlx-swift` from GitHub, e.g. `from: 0.10.0`
  - `mlx-swift-examples` from GitHub, branch `main`
- **To update to a new MLX version:**
  1. Edit `project.yml` and `Package.swift` to update the version/tag/branch.
  2. Run `swift package update` and regenerate your Xcode project (`xcodegen generate`).
  3. Clean and rebuild your project.
- This ensures all contributors use the same, stable MLX code.

### Local MLX Development (For Core/Advanced Contributors)
- If you want to make changes to MLX and see them reflected immediately:
  1. Clone `mlx-swift` locally (e.g., `git clone https://github.com/ml-explore/mlx-swift.git ~/Documents/GitHub/mlx-swift`).
  2. In `project.yml` and `Package.swift`, change the MLX dependency to use a local path:
     - `project.yml`:
       ```yaml
       packages:
         mlx-swift:
           path: ../mlx-swift
       ```
     - `Package.swift`:
       ```swift
       .package(name: "mlx-swift", path: "../mlx-swift"),
       ```
  3. Regenerate your Xcode project and rebuild.
  4. Any changes you make in `mlx-swift` will now be reflected immediately in your app.
- **To return to remote/stable:**
  1. Revert the path to the remote URL and version/tag.
  2. Run `swift package update` and rebuild.

### General Advice for Open Source Contributors
- Use remote dependencies for stability and reproducibility.
- Use local path dependencies only for active MLX development.
- Always commit and push changes to your fork/branch before updating the app to use a new version/tag.
- Document any custom changes to MLX in your PRs/issues.

---
*Last updated: 2025-06-26*
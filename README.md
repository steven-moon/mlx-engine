# MLXEngine

A production-ready Swift package for local Large Language Model (LLM) inference using Apple's MLX framework.

- **Unified MLX Integration**: Single `InferenceEngine` for all platforms (MLX or fallback)
- **Model Management**: Download, cache, and manage MLX-compatible models
- **Text Generation**: One-shot and streaming text generation
- **Chat Sessions**: Multi-turn conversation management
- **Platform Support**: macOS 14+, iOS 17+, visionOS 1+

## Installation

Add MLXEngine to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/MLXEngine.git", from: "1.0.0")
]
```

## Quick Start

```swift
import MLXEngine

let config = ModelRegistry.qwen_0_5B
let engine = try await InferenceEngine.loadModel(config)
let response = try await engine.generate("Hello, how are you?")
print(response)
```

## Documentation

**Full documentation, API reference, architecture, and guides are in [`_docs/README.md`](./_docs/README.md).**

- [API Reference](./_docs/api_reference.md)
- [Architecture Guide](./_docs/architecture.md)
- [Integration Guides](./_docs/integration_guides/)

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

## License

MIT License. See [LICENSE](LICENSE) for details.

## Running the Sample Chat App

A full-featured SwiftUI sample app is included for macOS, iOS, and more. This is the best way to try MLXEngine interactively.

### Command Line (macOS)

```bash
cd Examples/ChatApp
swift run MLXChatApp
```

### In Xcode (all platforms)

1. Open `Examples/ChatApp/Package.swift` in Xcode.
2. Select the desired platform and run the `MLXChatApp` scheme.

See [`Examples/ChatApp/README.md`](Examples/ChatApp/README.md) for more details and platform-specific notes.

## Developer Diagnostics & Debugging

### In-App DebugPanel (ChatApp)

The ChatApp example now includes a developer DebugPanel (DEBUG builds only):
- Access from the Settings screen via "Show Debug Panel".
- View and filter recent logs by level.
- Generate and copy a comprehensive debug report (system info, logs, model info).
- Designed for rapid troubleshooting and sharing diagnostics with maintainers.

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
*Last updated: 2025-06-25* 
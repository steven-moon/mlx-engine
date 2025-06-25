# MLXEngine Unified API Design

## Overview

This document formalizes the unified, protocol-driven API and engine architecture for MLXEngine, supporting MLX, Llama.cpp, Whisper.cpp, and cloud APIs (OpenAI, Claude, Gemini, etc.). It is based on the latest best practices from [llama.cpp](https://github.com/ggml-org/llama.cpp), [mlx-swift](https://github.com/ml-explore/mlx-swift), [mlx-swift-examples](https://github.com/ml-explore/mlx-swift-examples), [whisper.cpp](https://github.com/ggml-org/whisper.cpp), and the PocketMind app.

---

## 1. Protocol-Driven API

### Core Protocols

```swift
public protocol LLMEngine: Sendable {
    static var engineType: LLMEngineType { get }
    var supportsStreaming: Bool { get }
    func loadModel(configuration: ModelConfiguration) async throws
    func generate(prompt: String, params: GenerateParams) async throws -> String
    func stream(prompt: String, params: GenerateParams) -> AsyncThrowingStream<String, Error>
    func unload()
}

public protocol AudioToTextEngine: Sendable {
    static var engineType: AudioEngineType { get }
    func transcribe(audio: Data) async throws -> String
    func streamTranscribe(audio: Data) -> AsyncThrowingStream<String, Error>
}

public protocol TextToAudioEngine: Sendable {
    static var engineType: AudioEngineType { get }
    func synthesize(text: String) async throws -> Data
    func streamSynthesize(text: String) -> AsyncThrowingStream<Data, Error>
}

public protocol MultimodalEngine: Sendable {
    static var engineType: MultimodalEngineType { get }
    // Future: vision, audio+text, etc.
}
```

### EngineType Enums

```swift
enum LLMEngineType: String, Codable, CaseIterable {
    case mlx, llamaCpp, openAI, claude, gemini
}
enum AudioEngineType: String, Codable, CaseIterable {
    case whisperCpp, openAI, gemini
}
enum MultimodalEngineType: String, Codable, CaseIterable {
    case gemini, gpt4o
}
```

---

## 2. Engine Implementations

- **MLXEngine**: MLX, MLXLLM, MLXLMCommon
- **LlamaCppEngine**: [llama.cpp](https://github.com/ggml-org/llama.cpp) (XCFramework or FFI)
- **WhisperCppEngine**: [whisper.cpp](https://github.com/ggml-org/whisper.cpp)
- **OpenAIEngine**: OpenAI GPT/Whisper APIs
- **ClaudeEngine**: Anthropic Claude API
- **GeminiEngine**: Google Gemini API
- **Future Engines**: Bark, GPT-4o, Gemini Vision, etc.

---

## 3. Engine Registry & Factory

- **EngineRegistry**: Enumerates available engines and their capabilities.
- **EngineFactory**: Instantiates engines by type and configuration.
- **ModelRegistry**: Unified model metadata for all engines.

---

## 4. Model Management & Download

- Unified `ModelConfiguration` struct for all engines.
- Model download/caching (Hugging Face, local, remote).
- Shared infrastructure for both on-device and API-based engines.

---

## 5. Chat Session & Prompt Management

- Unified `ChatSession` and `PromptEngine` for all engines.
- Multi-turn, prompt templating, stop sequences, streaming, and cancellation.

---

## 6. Audio & Multimodal Support

- **Audio-to-text**: Whisper.cpp, OpenAI Whisper, Gemini, etc.
- **Text-to-audio**: Plan for Bark, OpenAI TTS, etc.
- **Multimodal**: Plan for Gemini Vision, GPT-4o, etc.
- **Engine capability introspection**: Each engine declares its supported modalities.

---

## 7. Utility Services

- File and cache management
- API key/credential management
- Network utilities for streaming, error handling, and retries

---

## 8. Engine/Modality Matrix

| Engine         | Text | Streaming | Audio-to-Text | Text-to-Audio | Multimodal | Local | API | Reference           |
|----------------|------|-----------|---------------|---------------|------------|-------|-----|---------------------|
| MLXEngine      | ✅   | ✅        | Planned       | Planned       | Planned    | ✅    |     | mlx-swift-examples  |
| LlamaCppEngine | ✅   | ✅        | Planned       | Planned       | Planned    | ✅    |     | llama.cpp           |
| WhisperCpp     |      |           | ✅            |               |            | ✅    |     | whisper.cpp         |
| OpenAIEngine   | ✅   | ✅        | ✅            | ✅            | Planned    |       | ✅  | PocketMind/OpenAI   |
| ClaudeEngine   | ✅   | ✅        |               |               | Planned    |       | ✅  | PocketMind/Claude   |
| GeminiEngine   | ✅   | ✅        | ✅            | Planned       | ✅         |       | ✅  | PocketMind/Gemini   |

---

## 9. Extensibility & Future-Proofing

- Add new engines by conforming to the relevant protocol.
- Add new modalities (vision, audio, etc.) by extending the protocol set.
- Unified chat and session management for all engines.
- Pluggable model registry for local, remote, and API-based models.

---

## 10. Example Usage

```swift
let engine = EngineFactory.makeEngine(type: .llamaCpp, config: myModelConfig)
try await engine.loadModel(configuration: myModelConfig)
let response = try await engine.generate(prompt: "Hello, world!", params: .default)
for try await token in engine.stream(prompt: "Tell me a story") {
    print(token, terminator: "")
}

let asrEngine = EngineFactory.makeAudioToTextEngine(type: .whisperCpp, config: myWhisperConfig)
let transcript = try await asrEngine.transcribe(audio: myAudioData)
```

---

## 11. References

- [llama.cpp](https://github.com/ggml-org/llama.cpp)
- [mlx-swift](https://github.com/ml-explore/mlx-swift)
- [mlx-swift-examples](https://github.com/ml-explore/mlx-swift-examples)
- [whisper.cpp](https://github.com/ggml-org/whisper.cpp)

---

*Last updated: {{date}}* 
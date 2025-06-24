# MLXEngine API Reference

> **Last Updated**: June 24, 2025

This document provides a comprehensive reference for all public APIs in MLXEngine.

## Table of Contents

- [InferenceEngine](#inferenceengine)
- [ModelConfiguration](#modelconfiguration)
- [ModelRegistry](#modelregistry)
- [ChatSession](#chatsession)
- [ModelDownloader](#modeldownloader)
- [HuggingFaceAPI](#huggingfaceapi)
- [Error Types](#error-types)

## InferenceEngine

The main entry point for LLM inference, providing a unified interface for text generation.

### Protocol

```swift
public protocol LLMEngine: Sendable {
    static func loadModel(_ config: ModelConfiguration, progress: @escaping @Sendable (Double) -> Void) async throws -> Self
    func generate(_ prompt: String, params: GenerateParams) async throws -> String
    func stream(_ prompt: String, params: GenerateParams) -> AsyncThrowingStream<String, Error>
    func unload()
}
```

### Class

```swift
public final class InferenceEngine: LLMEngine, @unchecked Sendable
```

### Methods

#### `loadModel(_:progress:)`

Loads a model with the specified configuration.

```swift
public static func loadModel(
    _ config: ModelConfiguration, 
    progress: @escaping @Sendable (Double) -> Void = { _ in }
) async throws -> InferenceEngine
```

**Parameters:**
- `config`: The model configuration to load
- `progress`: Optional progress callback (0.0 to 1.0)

**Returns:** An initialized `InferenceEngine` instance

**Throws:** `EngineError` or `MLXEngineError` if loading fails

**Example:**
```swift
let config = ModelRegistry.qwen_0_5B
let engine = try await InferenceEngine.loadModel(config) { progress in
    print("Loading: \(Int(progress * 100))%")
}
```

#### `generate(_:params:)`

Generates text from a prompt using one-shot completion.

```swift
public func generate(
    _ prompt: String, 
    params: GenerateParams = .init()
) async throws -> String
```

**Parameters:**
- `prompt`: The input prompt for text generation
- `params`: Optional generation parameters

**Returns:** The generated text response

**Throws:** `EngineError` if the engine is unloaded

**Example:**
```swift
let response = try await engine.generate("Hello, how are you?")
print(response)
```

#### `stream(_:params:)`

Generates text from a prompt using streaming completion.

```swift
public func stream(
    _ prompt: String, 
    params: GenerateParams = .init()
) -> AsyncThrowingStream<String, Error>
```

**Parameters:**
- `prompt`: The input prompt for text generation
- `params`: Optional generation parameters

**Returns:** An `AsyncThrowingStream` that yields tokens as they're generated

**Example:**
```swift
for try await token in engine.stream("Tell me a story") {
    print(token, terminator: "")
}
```

#### `unload()`

Unloads the model and frees associated resources.

```swift
public func unload()
```

**Example:**
```swift
engine.unload()
```

## ModelConfiguration

Configuration for LLM models with metadata and generation parameters.

### Struct

```swift
public struct ModelConfiguration: Codable, Sendable
```

### Properties

```swift
public let name: String
public let hubId: String
public let description: String
public let parameters: String
public let quantization: String
public let architecture: String
public let maxTokens: Int
public let estimatedSizeGB: Double
public let defaultSystemPrompt: String?
```

### Initializers

#### `init(name:hubId:description:parameters:quantization:architecture:maxTokens:estimatedSizeGB:defaultSystemPrompt:)`

Creates a new model configuration.

```swift
public init(
    name: String,
    hubId: String,
    description: String = "",
    parameters: String = "",
    quantization: String = "",
    architecture: String = "",
    maxTokens: Int = 1024,
    estimatedSizeGB: Double = 0.0,
    defaultSystemPrompt: String? = nil
)
```

**Example:**
```swift
let config = ModelConfiguration(
    name: "Qwen 0.5B",
    hubId: "mlx-community/Qwen1.5-0.5B-Chat-4bit",
    parameters: "0.5B",
    quantization: "4bit",
    architecture: "Qwen",
    maxTokens: 1024,
    estimatedSizeGB: 0.3
)
```

### Methods

#### `isSmallModel()`

Returns whether this model is considered small (suitable for mobile devices).

```swift
public func isSmallModel() -> Bool
```

**Returns:** `true` if the model is small enough for mobile devices

## ModelRegistry

Pre-configured collection of popular MLX-compatible models.

### Struct

```swift
public struct ModelRegistry
```

### Static Properties

#### Pre-configured Models

```swift
public static let qwen_0_5B: ModelConfiguration
public static let qwen_1_5B: ModelConfiguration
public static let qwen_3B: ModelConfiguration
public static let llama_3_2_3B: ModelConfiguration
public static let mistral_7B: ModelConfiguration
public static let phi_3_mini: ModelConfiguration
public static let gemma_2B: ModelConfiguration
public static let gemma_7B: ModelConfiguration
```

### Static Methods

#### `allModels`

Returns all available models.

```swift
public static var allModels: [ModelConfiguration]
```

**Returns:** Array of all pre-configured models

#### `findModelByName(_:)`

Finds a model by name.

```swift
public static func findModelByName(_ name: String) -> ModelConfiguration?
```

**Parameters:**
- `name`: The name of the model to find

**Returns:** The model configuration if found, `nil` otherwise

#### `findModelsByArchitecture(_:)`

Finds models by architecture.

```swift
public static func findModelsByArchitecture(_ architecture: String) -> [ModelConfiguration]
```

**Parameters:**
- `architecture`: The architecture to search for

**Returns:** Array of models with the specified architecture

#### `findSmallModels()`

Returns all models suitable for mobile devices.

```swift
public static func findSmallModels() -> [ModelConfiguration]
```

**Returns:** Array of small models

## ChatSession

Multi-turn conversation management with history and context preservation.

### Class

```swift
public final class ChatSession: @unchecked Sendable
```

### Initializers

#### `init(engine:)`

Creates a new chat session with the specified engine.

```swift
public init(engine: LLMEngine)
```

**Parameters:**
- `engine`: The LLM engine to use for generation

### Methods

#### `addMessage(_:content:)`

Adds a message to the conversation history.

```swift
public func addMessage(_ role: MessageRole, content: String) async throws
```

**Parameters:**
- `role`: The role of the message (user or assistant)
- `content`: The message content

**Throws:** `ChatSessionError` if the message cannot be added

#### `generateResponse(_:)`

Generates a response to a user message.

```swift
public func generateResponse(_ userMessage: String) async throws -> String
```

**Parameters:**
- `userMessage`: The user's message

**Returns:** The assistant's response

**Throws:** `ChatSessionError` if generation fails

#### `streamResponse(_:)`

Streams a response to a user message.

```swift
public func streamResponse(_ userMessage: String) -> AsyncThrowingStream<String, Error>
```

**Parameters:**
- `userMessage`: The user's message

**Returns:** An `AsyncThrowingStream` that yields response tokens

#### `clearHistory()`

Clears the conversation history.

```swift
public func clearHistory()
```

#### `removeLastMessage()`

Removes the last message from the conversation.

```swift
public func removeLastMessage() throws
```

**Throws:** `ChatSessionError` if no messages exist

#### `exportConversation()`

Exports the conversation in a formatted string.

```swift
public func exportConversation() -> String
```

**Returns:** The formatted conversation

### Properties

#### `messages`

Returns all messages in the conversation.

```swift
public var messages: [ChatMessage] { get }
```

#### `messageCount`

Returns the number of messages in the conversation.

```swift
public var messageCount: Int { get }
```

## GenerateParams

Configuration for text generation parameters.

### Struct

```swift
public struct GenerateParams: Sendable
```

### Properties

```swift
public var maxTokens: Int
public var temperature: Double
public var topP: Double
public var topK: Int
```

### Initializers

#### `init(maxTokens:temperature:topP:topK:)`

Creates new generation parameters.

```swift
public init(
    maxTokens: Int = 100,
    temperature: Double = 0.7,
    topP: Double = 0.9,
    topK: Int = 50
)
```

**Example:**
```swift
let params = GenerateParams(
    maxTokens: 200,
    temperature: 0.8,
    topP: 0.95,
    topK: 40
)
```

## MessageRole

Enumeration for message roles in chat sessions.

### Enum

```swift
public enum MessageRole: String, Codable, Sendable
```

### Cases

```swift
case user
case assistant
```

## ChatMessage

Represents a message in a chat conversation.

### Struct

```swift
public struct ChatMessage: Codable, Sendable
```

### Properties

```swift
public let id: UUID
public let role: MessageRole
public let content: String
public let timestamp: Date
```

## ModelDownloader

Optimized model downloading with progress tracking and integrity verification.

### Class

```swift
public final class ModelDownloader: @unchecked Sendable
```

### Initializers

#### `init()`

Creates a new model downloader.

```swift
public init()
```

### Methods

#### `downloadModel(_:progress:)`

Downloads a model with progress tracking.

```swift
public func downloadModel(
    _ config: ModelConfiguration,
    progress: @escaping @Sendable (Double) -> Void
) async throws -> URL
```

**Parameters:**
- `config`: The model configuration to download
- `progress`: Progress callback (0.0 to 1.0)

**Returns:** The local URL of the downloaded model

**Throws:** `ModelDownloaderError` if download fails

#### `isModelDownloaded(_:)`

Checks if a model is already downloaded.

```swift
public func isModelDownloaded(_ config: ModelConfiguration) -> Bool
```

**Parameters:**
- `config`: The model configuration to check

**Returns:** `true` if the model is downloaded

#### `getModelURL(_:)`

Gets the local URL for a model.

```swift
public func getModelURL(_ config: ModelConfiguration) -> URL?
```

**Parameters:**
- `config`: The model configuration

**Returns:** The local URL if the model is downloaded, `nil` otherwise

## HuggingFaceAPI

Lightweight client for Hugging Face Hub integration.

### Class

```swift
public final class HuggingFaceAPI: @unchecked Sendable
```

### Static Properties

#### `shared`

The shared instance of the Hugging Face API.

```swift
public static let shared: HuggingFaceAPI
```

### Methods

#### `setToken(_:)`

Sets the authentication token for the current session.

```swift
public func setToken(_ token: String)
```

**Parameters:**
- `token`: The Hugging Face authentication token

#### `saveToken(_:)`

Saves the authentication token for future sessions.

```swift
public func saveToken(_ token: String) throws
```

**Parameters:**
- `token`: The Hugging Face authentication token

**Throws:** `HuggingFaceAPIError` if saving fails

#### `loadToken()`

Loads the saved authentication token.

```swift
public func loadToken() -> String?
```

**Returns:** The saved token if available

#### `testAuthentication()`

Tests the current authentication.

```swift
public func testAuthentication() async throws -> String
```

**Returns:** The authenticated username

**Throws:** `HuggingFaceAPIError` if authentication fails

#### `getModelInfo(_:)`

Gets information about a model.

```swift
public func getModelInfo(_ modelId: String) async throws -> ModelInfo
```

**Parameters:**
- `modelId`: The Hugging Face model ID

**Returns:** Model information

**Throws:** `HuggingFaceAPIError` if the request fails

## Error Types

### EngineError

Errors related to the inference engine.

```swift
public enum EngineError: LocalizedError
```

**Cases:**
- `unloaded`: The engine has been unloaded

### MLXEngineError

Errors related to MLX integration.

```swift
public enum MLXEngineError: LocalizedError
```

**Cases:**
- `mlxNotAvailable(String)`: MLX is not available
- `modelNotFound(String)`: Model not found
- `downloadFailed(String)`: Model download failed

### ChatSessionError

Errors related to chat sessions.

```swift
public enum ChatSessionError: LocalizedError
```

**Cases:**
- `noMessages`: No messages in conversation
- `invalidRole`: Invalid message role
- `generationFailed(String)`: Text generation failed

### ModelDownloaderError

Errors related to model downloading.

```swift
public enum ModelDownloaderError: LocalizedError
```

**Cases:**
- `downloadFailed(String)`: Download operation failed
- `invalidModel(String)`: Invalid model configuration
- `networkError(String)`: Network-related error

### HuggingFaceAPIError

Errors related to Hugging Face API operations.

```swift
public enum HuggingFaceAPIError: LocalizedError
```

**Cases:**
- `authenticationFailed(String)`: Authentication failed
- `networkError(String)`: Network-related error
- `invalidResponse(String)`: Invalid API response

## Usage Examples

### Basic Text Generation

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

### Streaming Generation

```swift
// Stream text generation
for try await token in engine.stream("Tell me a story") {
    print(token, terminator: "")
}
```

### Chat Session

```swift
// Create a chat session
let session = ChatSession(engine: engine)

// Add messages
try await session.addMessage(.user, content: "Hello!")
try await session.addMessage(.assistant, content: "Hi there! How can I help you today?")

// Generate a response
let response = try await session.generateResponse("What's the weather like?")
print(response)

// Export conversation
let conversation = session.exportConversation()
print(conversation)
```

### Model Download

```swift
// Download a model
let downloader = ModelDownloader()
let modelURL = try await downloader.downloadModel(config) { progress in
    print("Download: \(Int(progress * 100))%")
}
print("Model downloaded to: \(modelURL)")
```

### Hugging Face Authentication

```swift
// Set up authentication
HuggingFaceAPI.shared.setToken("your_token_here")

// Test authentication
let username = try await HuggingFaceAPI.shared.testAuthentication()
print("Logged in as: \(username)")
```

---

*Last updated: June 24, 2025* 
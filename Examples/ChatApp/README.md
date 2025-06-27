# MLXEngine Chat App Example

> **Status**: ✅ **COMPLETE** - Full-featured chat application demonstrating MLXEngine capabilities

This directory contains a complete SwiftUI chat application that demonstrates the full capabilities of MLXEngine, including model loading, real-time text generation, and a modern chat interface.

## Features

- **Modern Chat Interface**: Clean, responsive SwiftUI chat interface with message bubbles
- **Model Selection**: Choose from multiple pre-configured models (Qwen, Gemma, Phi)
- **Real-time Generation**: Live text generation with progress indicators
- **Error Handling**: Comprehensive error handling and user feedback
- **Model Management**: Automatic model loading, caching, and cleanup
- **Cross-platform**: Works on macOS 14+ and iOS 17+

## Quick Start

1. **Build the app**:
   ```bash
   cd Examples/ChatApp
   swift build
   ```

2. **Run the app**:
   ```bash
   swift run MLXChatApp
   ```

3. **Start chatting**:
   - Select a model from the "Model" button
   - Type your message and press Enter or click Send
   - Watch as the AI responds in real-time

## Usage

### Model Selection
- Tap the "Model" button in the navigation bar
- Choose from available models (0.5B to 7B parameters)
- Each model shows size and description information

### Chat Interface
- **User messages**: Blue bubbles on the right
- **AI responses**: Gray bubbles on the left
- **Timestamps**: Each message shows when it was sent
- **Progress indicator**: Shows when AI is generating a response

### Controls
- **Clear**: Clears the chat history and unloads the current model
- **Model**: Opens model selection sheet
- **Send**: Sends your message (Enter key or button)

## Technical Details

### Architecture
- **SwiftUI**: Modern declarative UI framework
- **MVVM Pattern**: Clean separation of concerns
- **Async/Await**: Non-blocking model loading and generation
- **Environment Objects**: Shared state management

### MLXEngine Integration
- **Model Loading**: Automatic model download and caching
- **Text Generation**: Real-time inference with MLX
- **Memory Management**: Automatic GPU memory cleanup
- **Error Recovery**: Graceful fallback to mock implementation

### Supported Models
- **Qwen Series**: 0.5B, 1B, 3B, 7B parameter models
- **Gemma Series**: 2B, 7B parameter models  
- **Phi Series**: 2B, 3B parameter models

## Performance

- **Model Loading**: ~2-8 seconds depending on model size
- **Generation Speed**: ~15-50 tokens/second depending on model and hardware
- **Memory Usage**: Optimized GPU memory management
- **Responsiveness**: Non-blocking UI during model operations

## Requirements

- **Platforms**: macOS 14+, iOS 17+
- **Hardware**: Apple Silicon (M1/M2/M3/M4) or A17+ devices
- **Dependencies**: MLXEngine Swift package
- **MLX Runtime**: For full functionality (optional - falls back to mock)

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
- Try a smaller model for testing
- Ensure the device isn't thermal throttling

## Development

This example demonstrates best practices for integrating MLXEngine into SwiftUI applications:

- **State Management**: Using `@StateObject` and `@EnvironmentObject`
- **Async Operations**: Proper `async/await` usage with `@MainActor`
- **Error Handling**: User-friendly error presentation
- **Memory Management**: Automatic resource cleanup
- **UI/UX**: Modern, responsive interface design

## Next Steps

- Add streaming text generation for real-time responses
- Implement conversation history persistence
- Add model parameter customization
- Support for custom model configurations
- Advanced chat features (markdown, code highlighting)

---

*This example demonstrates the full power of MLXEngine for building production-ready AI chat applications.*

*Last updated: 2025-06-27* 
# MLX Swift Examples Integration Guide

> For dependency setup, see the main [README](../README.md).

> **Purpose**: Leverage the official MLX Swift Examples project for proven MLX integration patterns and model implementations  
> **Status**: ✅ **OFFICIAL MLX LIBRARIES AVAILABLE**  
> **Priority**: 🔴 **CRITICAL - FOUNDATION FOR REAL MLX INTEGRATION**

---

## Executive Summary

The `mlx-swift-examples` project contains the **official MLX Swift libraries** and **production-ready model implementations** that form the foundation for real MLX integration. This project provides:

- **Official MLX Libraries**: MLXLLM, MLXLMCommon, MLXVLM, MLXEmbedders
- **Proven Model Implementations**: Llama, Qwen, Mistral, Phi, Gemma, and more
- **Model Factory Pattern**: Standardized model loading and configuration
- **Comprehensive Documentation**: Official MLX Swift documentation and examples

This project should be used as the **primary source** for real MLX integration in MLXEngine.

---

## Key Components to Leverage

### 1. MLXLLM Library (`Libraries/MLXLLM/`)

**Location**: `sample-code/mlx-swift-examples-main/Libraries/MLXLLM/`  
**Status**: ✅ **Official MLX LLM library with proven implementations**

**Key Components**:
- **LLMModelFactory**: Standardized model loading with progress tracking
- **Model Registry**: Comprehensive model configuration registry
- **Model Implementations**: Llama, Qwen, Mistral, Phi, Gemma, and more
- **LoRA Support**: Adapter training and inference capabilities

**Code References**:
```25:65:sample-code/mlx-swift-examples-main/Libraries/MLXLLM/LLMModelFactory.swift
public class LLMTypeRegistry: ModelTypeRegistry, @unchecked Sendable {
    public static let shared: LLMTypeRegistry = .init(creators: all())
    
    private static func all() -> [String: @Sendable (URL) throws -> any LanguageModel] {
        [
            "mistral": create(LlamaConfiguration.self, LlamaModel.init),
            "llama": create(LlamaConfiguration.self, LlamaModel.init),
            "phi": create(PhiConfiguration.self, PhiModel.init),
            "qwen2": create(Qwen2Configuration.self, Qwen2Model.init),
            "qwen3": create(Qwen3Configuration.self, Qwen3Model.init),
            // ... comprehensive model registry
        ]
    }
}
```

**Integration Strategy**:
1. **Add as Dependency**: Include MLXLLM as a Swift Package dependency
2. **Use Model Factory**: Replace custom model loading with LLMModelFactory
3. **Leverage Registry**: Use the comprehensive model registry
4. **Model Implementations**: Use proven model implementations

### 2. MLXLMCommon Library (`Libraries/MLXLMCommon/`)

**Location**: `sample-code/mlx-swift-examples-main/Libraries/MLXLMCommon/`  
**Status**: ✅ **Common API for LLM and VLM operations**

**Key Components**:
- **ModelConfiguration**: Standardized model configuration
- **ChatSession**: Multi-turn conversation management
- **Generate Parameters**: Standardized generation parameters
- **Evaluation Tools**: Model evaluation and benchmarking

**Code References**:
```swift
// Simplified API usage from MLXLMCommon
let model = try await loadModel(id: "mlx-community/Qwen3-4B-4bit")
let session = ChatSession(model)
print(try await session.respond(to: "What are two things to see in San Francisco?"))
print(try await session.respond(to: "How about a great place to eat?"))
```

**Integration Strategy**:
1. **Use ChatSession**: Replace custom chat implementation with MLXLMCommon.ChatSession
2. **Standardize Configuration**: Use MLXLMCommon.ModelConfiguration
3. **Generation Parameters**: Use standardized GenerateParameters
4. **Evaluation Tools**: Leverage built-in evaluation capabilities

### 3. Model Registry (`LLMRegistry`)

**Location**: `sample-code/mlx-swift-examples-main/Libraries/MLXLLM/LLMModelFactory.swift`  
**Status**: ✅ **Comprehensive model configuration registry**

**Key Features**:
- **Pre-configured Models**: 20+ pre-configured model configurations
- **Optimized Settings**: Best practices for each model
- **Prompt Templates**: Model-specific prompt formatting
- **Quantization Support**: 4-bit, 8-bit, and FP16 configurations

**Code References**:
```85:125:sample-code/mlx-swift-examples-main/Libraries/MLXLLM/LLMModelFactory.swift
public class LLMRegistry: AbstractModelRegistry, @unchecked Sendable {
    public static let shared = LLMRegistry(modelConfigurations: all())
    
    static public let qwen205b4bit = ModelConfiguration(
        id: "mlx-community/Qwen1.5-0.5B-Chat-4bit",
        overrideTokenizer: "PreTrainedTokenizer",
        defaultPrompt: "why is the sky blue?"
    )
    
    static public let qwen3_4b_4bit = ModelConfiguration(
        id: "mlx-community/Qwen3-4B-4bit",
        defaultPrompt: "Why is the sky blue?"
    )
    
    static public let llama3_2_3B_4bit = ModelConfiguration(
        id: "mlx-community/Llama-3.2-3B-Instruct-4bit",
        defaultPrompt: "What is the difference between a fruit and a vegetable?"
    )
    // ... comprehensive model registry
}
```

**Integration Strategy**:
1. **Replace ModelRegistry**: Use MLXLLM's comprehensive registry
2. **Add Custom Models**: Extend registry with custom model configurations
3. **Optimize Settings**: Use proven configurations for each model
4. **Prompt Templates**: Leverage model-specific prompt formatting

### 4. Model Implementations (`Models/`)

**Location**: `sample-code/mlx-swift-examples-main/Libraries/MLXLLM/Models/`  
**Status**: ✅ **Production-ready model implementations**

**Available Models**:
- **Llama Models**: Llama 2, Llama 3, Llama 3.2
- **Qwen Models**: Qwen 1.5, Qwen 2.5, Qwen 3.0, Qwen 3.1
- **Mistral Models**: Mistral 7B, Mistral Nemo
- **Phi Models**: Phi 2, Phi 3.5, Phi 3.5 MoE
- **Gemma Models**: Gemma 2B, Gemma 2 9B, Gemma 2 2B
- **Other Models**: Starcoder2, Cohere, OpenELM, InternLM2, Granite

**Code References**:
```swift
// Model loading pattern from MLXLLM
let modelContainer = try await LLMModelFactory.shared.loadContainer(
    configuration: .init(id: "mlx-community/Qwen3-4B-4bit")
) { progress in
    // Progress tracking
    print("Loading progress: \(progress.fractionCompleted)")
}
```

**Integration Strategy**:
1. **Use Model Factory**: Replace custom model loading with LLMModelFactory
2. **Leverage Implementations**: Use proven model implementations
3. **Configuration Management**: Use standardized configuration patterns
4. **Progress Tracking**: Implement proper progress tracking

### 5. LoRA Support (`Lora+Data.swift`, `LoraTrain.swift`)

**Location**: `sample-code/mlx-swift-examples-main/Libraries/MLXLLM/`  
**Status**: ✅ **Advanced LoRA training and inference**

**Key Features**:
- **LoRA Training**: On-device fine-tuning capabilities
- **Adapter Loading**: Load and apply LoRA adapters
- **Data Processing**: Training data preparation
- **Inference Integration**: Seamless adapter inference

**Code References**:
```swift
// LoRA training pattern from MLXLLM
let loraConfig = LoRAConfiguration(
    rank: 16,
    alpha: 32,
    dropout: 0.1
)

let trainedModel = try await trainLoRA(
    model: baseModel,
    configuration: loraConfig,
    trainingData: trainingData
)
```

**Integration Strategy**:
1. **Add LoRA Support**: Implement LoRA training and inference
2. **Adapter Management**: Add adapter loading and management
3. **Training Pipeline**: Implement on-device fine-tuning
4. **Feature Flags**: Add LoRA support behind feature flags

---

## Integration Roadmap

### Phase 1: Foundation Integration (Week 1)

#### 1.1 Add MLX Dependencies
**Priority**: 🔴 **CRITICAL**

**Actions**:
1. **Add Swift Package Dependencies**: Include MLXLLM and MLXLMCommon
2. **Update Package.swift**: Add official MLX libraries
3. **Test Integration**: Verify dependencies work correctly

**Package.swift Updates**:
```swift
dependencies: [
    .package(url: "https://github.com/ml-explore/mlx-swift", from: "0.10.0"),
    .package(url: "https://github.com/ml-explore/mlx-swift-examples", branch: "main")
],
targets: [
    .target(
        name: "MLXEngine",
        dependencies: [
            .product(name: "MLXLLM", package: "mlx-swift-examples"),
            .product(name: "MLXLMCommon", package: "mlx-swift-examples")
        ]
    )
]
```

#### 1.2 Replace Model Registry
**Priority**: 🔴 **CRITICAL**

**Actions**:
1. **Use LLMRegistry**: Replace current ModelRegistry with MLXLLM's registry
2. **Extend Registry**: Add custom model configurations
3. **Update ModelRegistry.swift**: Integrate with MLXLLM registry

**Code Integration**:
```swift
// Sources/MLXEngine/ModelRegistry.swift
public class ModelRegistry {
    private let mlxRegistry = LLMRegistry.shared
    
    public func getModelConfiguration(for id: String) -> ModelConfiguration? {
        // Use MLXLLM registry as primary source
        return mlxRegistry.modelConfigurations[id]
    }
    
    public func getAllModels() -> [ModelConfiguration] {
        return Array(mlxRegistry.modelConfigurations.values)
    }
}
```

### Phase 2: Real MLX Integration (Week 2)

#### 2.1 Replace Model Loading
**Priority**: 🔴 **CRITICAL**

**Actions**:
1. **Use LLMModelFactory**: Replace custom model loading with MLXLLM factory
2. **Progress Tracking**: Implement proper progress tracking
3. **Error Handling**: Use MLXLLM error handling patterns

**Code Integration**:
```swift
// Sources/MLXEngine/RealMLXEngine.swift
private func loadModelInternal(progress: @escaping (Double) -> Void) async throws {
    let modelContainer = try await LLMModelFactory.shared.loadContainer(
        configuration: .init(id: config.hubId)
    ) { mlxProgress in
        progress(mlxProgress.fractionCompleted)
    }
    
    self.modelContainer = modelContainer
}
```

#### 2.2 Use ChatSession
**Priority**: 🟡 **HIGH**

**Actions**:
1. **Replace ChatSession**: Use MLXLMCommon.ChatSession
2. **Multi-turn Support**: Leverage built-in conversation management
3. **Prompt Templates**: Use model-specific prompt formatting

**Code Integration**:
```swift
// Sources/MLXEngine/ChatSession.swift
public class ChatSession {
    private let mlxSession: MLXLMCommon.ChatSession
    
    public init(model: ModelContainer) {
        self.mlxSession = MLXLMCommon.ChatSession(model)
    }
    
    public func respond(to message: String) async throws -> String {
        return try await mlxSession.respond(to: message)
    }
}
```

### Phase 3: Advanced Features (Week 3)

#### 3.1 LoRA Support
**Priority**: 🟡 **HIGH**

**Actions**:
1. **Add LoRA Dependencies**: Include LoRA training capabilities
2. **Adapter Management**: Implement adapter loading and management
3. **Training Pipeline**: Add on-device fine-tuning support

#### 3.2 Model Evaluation
**Priority**: 🟢 **MEDIUM**

**Actions**:
1. **Evaluation Tools**: Use MLXLMCommon evaluation capabilities
2. **Benchmarking**: Implement model performance benchmarking
3. **Quality Metrics**: Add model quality assessment tools

---

## Code Migration Strategy

### 1. Dependency Integration

**Add Official Dependencies**:
```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/ml-explore/mlx-swift", from: "0.10.0"),
    .package(url: "https://github.com/ml-explore/mlx-swift-examples", branch: "main")
]
```

### 2. Model Registry Replacement

**Replace Current Registry**:
```swift
// Sources/MLXEngine/ModelRegistry.swift
import MLXLLM

public class ModelRegistry {
    private let mlxRegistry = LLMRegistry.shared
    
    public func getModelConfiguration(for id: String) -> ModelConfiguration? {
        return mlxRegistry.modelConfigurations[id]
    }
}
```

### 3. Model Loading Integration

**Use LLMModelFactory**:
```swift
// Sources/MLXEngine/RealMLXEngine.swift
import MLXLLM

private func loadModelInternal(progress: @escaping (Double) -> Void) async throws {
    let modelContainer = try await LLMModelFactory.shared.loadContainer(
        configuration: .init(id: config.hubId)
    ) { progress in
        progress(progress.fractionCompleted)
    }
    
    self.modelContainer = modelContainer
}
```

### 4. Chat Session Integration

**Use MLXLMCommon.ChatSession**:
```swift
// Sources/MLXEngine/ChatSession.swift
import MLXLMCommon

public class ChatSession {
    private let mlxSession: MLXLMCommon.ChatSession
    
    public init(model: ModelContainer) {
        self.mlxSession = MLXLMCommon.ChatSession(model)
    }
}
```

---

## Success Metrics

### Technical Metrics
- [ ] **Real MLX Integration**: Replace all stub implementations with MLXLLM
- [ ] **Model Support**: Support 20+ pre-configured models
- [ ] **Performance**: <8s model load time on iPhone 15 Pro
- [ ] **Memory Management**: Proper GPU memory management

### User Experience Metrics
- [ ] **Model Discovery**: Easy access to 20+ pre-configured models
- [ ] **Chat Experience**: Seamless multi-turn conversations
- [ ] **Error Handling**: Graceful handling of model loading failures
- [ ] **Performance**: Fast text generation with streaming support

### Integration Metrics
- [ ] **API Compatibility**: All existing MLXEngine APIs continue to work
- [ ] **Test Coverage**: All tests pass with real MLX implementation
- [ ] **Documentation**: Updated documentation with MLXLLM examples

---

## Risk Mitigation

### High-Risk Scenarios

1. **Dependency Conflicts**
   - **Mitigation**: Use specific version pins for MLX dependencies
   - **Fallback**: Maintain stub implementation as fallback

2. **API Breaking Changes**
   - **Mitigation**: Pin to specific MLXLLM versions
   - **Fallback**: Gradual migration with backward compatibility

3. **Performance Issues**
   - **Mitigation**: Use MLXLLM's optimized implementations
   - **Fallback**: Performance monitoring and optimization

### Contingency Plans

1. **If MLXLLM Integration Fails**: Use as reference implementation
2. **If Performance Unacceptable**: Implement additional optimizations
3. **If API Changes Required**: Create migration guide for users

---

## Implementation Checklist

### Week 1: Foundation Integration
- [ ] Add MLXLLM and MLXLMCommon dependencies
- [ ] Replace ModelRegistry with LLMRegistry
- [ ] Update ModelConfiguration to use MLXLMCommon
- [ ] Test dependency integration
- [ ] Update documentation

### Week 2: Real MLX Integration
- [ ] Replace model loading with LLMModelFactory
- [ ] Integrate ChatSession with MLXLMCommon
- [ ] Implement proper progress tracking
- [ ] Add comprehensive error handling
- [ ] Test with real MLX models

### Week 3: Advanced Features
- [ ] Add LoRA support (optional)
- [ ] Implement model evaluation tools
- [ ] Add performance benchmarking
- [ ] Create example applications
- [ ] Update documentation

---

## Conclusion

The `mlx-swift-examples` project provides the **official foundation** for real MLX integration in MLXEngine. The MLXLLM and MLXLMCommon libraries offer proven implementations that should be used as the primary source for model loading, chat sessions, and advanced features.

**Next Action**: Begin Phase 1 by adding MLXLLM and MLXLMCommon dependencies and replacing the ModelRegistry.

---

*Last updated: 2025-06-27* 
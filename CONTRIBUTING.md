# Contributing to MLXEngine

Thank you for your interest in contributing to MLXEngine! This document provides guidelines for contributing to the project.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Documentation](#documentation)
- [Pull Request Process](#pull-request-process)
- [Issue Reporting](#issue-reporting)
- [Performance Considerations](#performance-considerations)

## 📜 Code of Conduct

This project follows a Code of Conduct to ensure a welcoming environment for all contributors. By participating, you agree to uphold these standards:

- **Be respectful**: Treat everyone with respect and professionalism
- **Be inclusive**: Welcome diverse perspectives and backgrounds
- **Be constructive**: Provide helpful feedback and suggestions
- **Be patient**: Help newcomers learn and grow
- **Be collaborative**: Work together toward common goals

## 🚀 Development Setup

### Prerequisites

- **macOS 14.0+** (required for MLX development)
- **Xcode 15.0+** with Swift 5.9+
- **Apple Silicon Mac** (M1/M2/M3/M4 recommended)
- **Git** for version control

### Getting Started

1. **Fork and clone the repository**:
   ```bash
   git clone https://github.com/yourusername/MLXEngine.git
   cd MLXEngine
   ```

2. **Open in Xcode**:
   ```bash
   open Package.swift
   ```

3. **Build the project**:
   ```bash
   swift build
   ```

4. **Run tests to verify setup**:
   ```bash
   swift test
   ```

5. **Install development tools**:
   ```bash
   # Install SwiftLint (optional but recommended)
   brew install swiftlint
   
   # Install swift-format (optional)
   brew install swift-format
   ```

## 🏗️ Project Structure

```
MLXEngine/
├── Sources/MLXEngine/          # Core library code
│   ├── InferenceEngine.swift   # Main inference engine
│   ├── ModelRegistry.swift     # Model configurations
│   ├── HuggingFaceAPI.swift    # Model discovery/download
│   ├── ChatSession.swift       # Chat management
│   ├── MLXModelSearchUtility.swift  # Advanced search
│   ├── FileManagerService.swift     # File operations
│   └── OptimizedDownloader.swift    # Parallel downloads
├── Tests/                      # Test suites
│   ├── MLXEngineTests/         # Unit tests
│   └── SanityTests/           # Basic sanity checks
├── Examples/                   # Example code
│   ├── simple_example.swift   # Basic usage
│   └── interactive_prompt.swift # Interactive demo
├── sample-code/               # Sample applications
│   └── LLMClusterApp/         # Production sample app
├── _docs/                     # Documentation
└── .github/workflows/         # CI/CD configuration
```

## 📝 Coding Standards

### Swift Style Guidelines

We follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) with these additions:

#### Naming Conventions
- **Types**: `PascalCase` (e.g., `InferenceEngine`, `ModelConfiguration`)
- **Functions/Variables**: `camelCase` (e.g., `loadModel`, `isDownloaded`)
- **Constants**: `camelCase` (e.g., `maxTokens`, `defaultPrompt`)
- **Acronyms**: Capitalized (e.g., `URLSession`, `MLXEngine`)

#### Code Organization
```swift
// MARK: - Public API

/// Brief description of the class/struct
public class ExampleClass {
    // MARK: - Properties
    
    /// Documentation for public properties
    public let publicProperty: String
    
    private let privateProperty: Int
    
    // MARK: - Initialization
    
    /// Initialize with required parameters
    public init(publicProperty: String) {
        self.publicProperty = publicProperty
        self.privateProperty = 0
    }
    
    // MARK: - Public Methods
    
    /// Public method documentation
    public func publicMethod() async throws -> String {
        // Implementation
    }
    
    // MARK: - Private Methods
    
    private func privateHelper() {
        // Implementation
    }
}
```

#### Documentation Requirements
- **All public APIs** must have documentation comments (`///`)
- Include parameter descriptions and return values
- Document thrown errors when applicable
- Provide usage examples for complex APIs

```swift
/// Loads a model configuration for inference
/// 
/// - Parameter config: The model configuration to load
/// - Returns: The loaded inference engine
/// - Throws: `MLXEngineError` if loading fails
/// 
/// ```swift
/// let config = ModelRegistry.qwen05B
/// let engine = try await InferenceEngine.loadModel(config)
/// ```
public static func loadModel(_ config: ModelConfiguration) async throws -> InferenceEngine {
    // Implementation
}
```

### Error Handling

Use comprehensive error types with clear messages:

```swift
public enum MLXEngineError: Error, LocalizedError {
    case modelNotFound(String)
    case loadingFailed(String)
    case inferenceError(String)
    
    public var errorDescription: String? {
        switch self {
        case .modelNotFound(let id):
            return "Model not found: \(id)"
        case .loadingFailed(let reason):
            return "Failed to load model: \(reason)"
        case .inferenceError(let details):
            return "Inference error: \(details)"
        }
    }
}
```

### Concurrency

- Use **async/await** for all asynchronous operations
- Mark concurrent types as `@unchecked Sendable` when appropriate
- Use `@MainActor` for UI-related code
- Avoid legacy callback-based APIs

```swift
/// Correct async pattern
public func generateText(_ prompt: String) async throws -> String {
    // Implementation using async/await
}

/// Incorrect - avoid callbacks
public func generateText(_ prompt: String, completion: @escaping (Result<String, Error>) -> Void) {
    // Don't use this pattern
}
```

## 🧪 Testing Guidelines

### Test Structure

- **Unit Tests**: Test individual components in isolation
- **Integration Tests**: Test component interactions
- **Sanity Tests**: Basic functionality verification

### Writing Tests

```swift
import XCTest
@testable import MLXEngine

final class ModelRegistryTests: XCTestCase {
    
    func testModelRegistryContainsExpectedModels() {
        // Given
        let allModels = ModelRegistry.allModels
        
        // When & Then
        XCTAssertFalse(allModels.isEmpty, "Model registry should contain models")
        XCTAssertTrue(allModels.contains { $0.name.contains("Qwen") }, "Should contain Qwen models")
    }
    
    func testModelSearchByArchitecture() async throws {
        // Given
        let architecture = "Llama"
        
        // When
        let llamaModels = ModelRegistry.findModels(by: architecture)
        
        // Then
        XCTAssertFalse(llamaModels.isEmpty, "Should find Llama models")
        for model in llamaModels {
            XCTAssertEqual(model.architecture, architecture)
        }
    }
}
```

### Test Requirements

- **Test Coverage**: Aim for >90% test coverage on public APIs
- **Error Cases**: Test both success and failure scenarios
- **Edge Cases**: Test boundary conditions and invalid inputs
- **Performance**: Include performance tests for critical paths

### Running Tests

```bash
# Run all tests
swift test

# Run specific test target
swift test --filter MLXEngineTests

# Run with verbose output
swift test --verbose

# Generate test coverage
swift test --enable-code-coverage
```

## 📚 Documentation

### API Documentation

- Use **DocC** format for API documentation
- Include code examples in documentation
- Document all public types, methods, and properties
- Use proper markdown formatting

### Architecture Documentation

- Update `_docs/architecture.md` for architectural changes
- Document design decisions and trade-offs
- Include diagrams for complex interactions
- Keep integration guides up to date

### README Updates

- Update examples when adding new features
- Maintain accurate installation instructions
- Keep performance benchmarks current
- Update supported platform versions

## 🔄 Pull Request Process

### Before Submitting

1. **Create a feature branch**:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Follow coding standards**:
   ```bash
   swiftlint
   swift-format Sources Tests Examples --in-place
   ```

3. **Run tests**:
   ```bash
   swift test
   ```

4. **Update documentation** if needed

5. **Write clear commit messages**:
   ```
   feat: add advanced model search functionality
   
   - Implement MLXModelSearchUtility with filtering criteria
   - Add support for architecture and quantization filtering
   - Include comprehensive error handling and logging
   - Add unit tests with 95% coverage
   
   Closes #123
   ```

### Pull Request Template

```markdown
## Description
Brief description of the changes

## Type of Change
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that causes existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] Manual testing performed
- [ ] All tests pass

## Documentation
- [ ] API documentation updated
- [ ] README updated if needed
- [ ] Architecture docs updated if needed

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex logic
- [ ] No unnecessary dependencies added
- [ ] Performance impact considered
```

### Review Process

1. **Automated Checks**: CI must pass (tests, linting, building)
2. **Code Review**: At least one maintainer review required
3. **Testing**: Reviewers should test functionality locally
4. **Documentation**: Verify documentation is complete and accurate

## 🐛 Issue Reporting

### Bug Reports

Use the bug report template:

```markdown
**Bug Description**
Clear description of the bug

**Steps to Reproduce**
1. Step one
2. Step two
3. See error

**Expected Behavior**
What should happen

**Actual Behavior**
What actually happens

**Environment**
- OS: macOS 14.1
- Xcode: 15.2
- MLXEngine Version: 1.0.0
- Device: MacBook Pro M3

**Additional Context**
Any other relevant information
```

### Feature Requests

Use the feature request template:

```markdown
**Feature Description**
Clear description of the proposed feature

**Problem Statement**
What problem does this solve?

**Proposed Solution**
How should this be implemented?

**Alternatives Considered**
Other approaches considered

**Additional Context**
Any other relevant information
```

## ⚡ Performance Considerations

### Guidelines

- **Memory Management**: Minimize allocations in hot paths
- **GPU Memory**: Implement proper cleanup for MLX resources
- **Async Performance**: Avoid blocking the main thread
- **Caching**: Cache expensive computations appropriately

### Benchmarking

- Use `CFAbsoluteTimeGetCurrent()` for timing measurements
- Test on various hardware configurations
- Include before/after performance comparisons
- Document performance implications in PR descriptions

### Example Performance Test

```swift
func testModelLoadingPerformance() async throws {
    let config = ModelRegistry.qwen05B
    
    measure {
        Task {
            let engine = try await InferenceEngine.loadModel(config)
            engine.unload()
        }
    }
}
```

## 🚀 Release Process

### Version Numbering

We follow [Semantic Versioning](https://semver.org/):
- **Major** (X.0.0): Breaking changes
- **Minor** (0.X.0): New features, backwards compatible
- **Patch** (0.0.X): Bug fixes, backwards compatible

### Release Checklist

- [ ] All tests pass
- [ ] Documentation updated
- [ ] Performance benchmarks verified
- [ ] Example code updated
- [ ] Release notes written
- [ ] Version numbers updated

## 🤝 Community

### Getting Help

- **GitHub Discussions**: Ask questions and share ideas
- **GitHub Issues**: Report bugs and request features
- **Documentation**: Check the docs for common solutions

### Contributing Areas

- **Core Library**: Improve performance and add features
- **Documentation**: Help improve guides and examples
- **Testing**: Add test coverage and improve reliability
- **Examples**: Create tutorials and sample applications
- **Performance**: Optimize critical paths and memory usage

---

Thank you for contributing to MLXEngine! Your efforts help make local AI more accessible to iOS and macOS developers. 
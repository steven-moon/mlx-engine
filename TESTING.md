# MLXEngine Testing Guide

This guide explains how to run tests for MLXEngine, including different testing strategies for various environments.

## Quick Start

### Fast Tests (Recommended for Development)
```bash
# Run fast unit tests only (mock mode)
./run_tests.sh fast

# Or directly with Swift
swift test --filter ChatSessionTests --filter MLXEngineTests --filter ModelRegistryTests --filter SanityTests
```

### Real Model Tests (Requires MLX Runtime)
```bash
# Enable real model tests and run them
MLXENGINE_RUN_REAL_TESTS=true ./run_tests.sh real

# Or run all tests
MLXENGINE_RUN_REAL_TESTS=true ./run_tests.sh all
```

## Test Categories

### 1. Fast Unit Tests (Mock Mode)
- **Purpose**: Test core functionality without requiring MLX runtime or model downloads
- **Speed**: Very fast (< 10 seconds)
- **Requirements**: None (works everywhere)
- **Coverage**: Core API, data structures, mock implementations

**Test Classes:**
- `ChatSessionTests` - Chat conversation management
- `MLXEngineTests` - Core engine functionality
- `ModelRegistryTests` - Model registry and search
- `SanityTests` - Basic sanity checks

### 2. Real Model Tests (MLX Mode)
- **Purpose**: Test with real HuggingFace models and MLX runtime
- **Speed**: Slow (5-30 minutes depending on model size)
- **Requirements**: 
  - MLX runtime properly installed
  - Internet connection for model downloads
  - Sufficient disk space (1-5 GB)
- **Coverage**: Real model loading, text generation, streaming

**Test Classes:**
- `RealisticModelTests` - Real model download and inference
- `MLXIntegrationTests` - MLX framework integration

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MLXENGINE_RUN_REAL_TESTS` | `false` | Enable real model tests |
| `MLXENGINE_VERBOSE` | `false` | Enable verbose test output |

## Testing Strategies

### For Development
Use fast tests for quick feedback during development:
```bash
./run_tests.sh fast
```

### For CI/CD
Use fast tests in CI to ensure core functionality:
```bash
# In CI pipeline
./run_tests.sh fast
```

### For Integration Testing
Use real model tests to verify full functionality:
```bash
# On development machine with MLX
MLXENGINE_RUN_REAL_TESTS=true ./run_tests.sh real
```

### For Debugging
Use clean tests to ensure fresh build:
```bash
./run_tests.sh clean
```

## Understanding Test Output

### Expected "Errors" in Fast Tests
When running fast tests, you may see messages like:
```
⚠️ MLX not available, using mock implementation: MLX runtime error: MLX runtime not available: File not found: main
```

**This is normal and expected!** These are not actual errors - they indicate that:
1. The system correctly detected MLX runtime is not available
2. It gracefully fell back to mock implementation
3. Tests continue to pass with mock responses

### Real Model Test Output
When running real model tests, you'll see:
```
🚀 [REAL MODEL TEST] Starting comprehensive real model test...
📥 [REAL MODEL TEST] Downloading model...
⚙️ [REAL MODEL TEST] Testing model loading...
💬 [REAL MODEL TEST] Testing text generation...
```

## Troubleshooting

### MLX Runtime Issues
If you see Metal library errors:
```
❌ MLX model loading failed: File not found: main
```

**Solutions:**
1. **For Development**: Use fast tests - they work without MLX
2. **For Real Testing**: Install MLX runtime properly
3. **For CI**: Use fast tests only

### Network Issues
If model downloads fail:
```
❌ Download failed: Network error occurred
```

**Solutions:**
1. Check internet connection
2. Verify HuggingFace API access
3. Use fast tests for offline development

### Memory Issues
If tests fail due to memory:
```
❌ MLX error: GPU memory allocation failed
```

**Solutions:**
1. Use smaller models in `ModelRegistry`
2. Reduce GPU cache limit in `InferenceEngine`
3. Use fast tests for development

## Test Configuration

### Custom Test Filters
Run specific test methods:
```bash
swift test --filter ChatSessionTests/testGenerateResponse
```

### Verbose Output
Enable detailed test output:
```bash
MLXENGINE_VERBOSE=true swift test
```

### Parallel Testing
Run tests in parallel (faster):
```bash
swift test --parallel
```

## Best Practices

### For Developers
1. **Use fast tests for daily development** - they're quick and reliable
2. **Run real tests before commits** - ensure full functionality
3. **Use clean tests when debugging** - avoid build cache issues

### For CI/CD
1. **Always use fast tests** - they're reliable and fast
2. **Skip real model tests** - they require special environment
3. **Use parallel testing** - faster execution

### For Integration Testing
1. **Run real tests on dedicated machines** - they need MLX runtime
2. **Use small models** - faster downloads and testing
3. **Monitor disk space** - models can be large

## Test Architecture

### Mock Implementation
The mock implementation provides:
- Realistic API responses
- Proper error handling
- Fast execution
- No external dependencies

### Real Implementation
The real implementation provides:
- Actual MLX model loading
- Real text generation
- Streaming capabilities
- Full MLX integration

### Fallback Strategy
The system automatically:
1. Tries to use MLX if available
2. Falls back to mock if MLX fails
3. Provides clear error messages
4. Continues testing with mock

## Performance Expectations

| Test Type | Duration | Memory | Network |
|-----------|----------|--------|---------|
| Fast Tests | < 10s | Low | None |
| Real Tests | 5-30m | High | Required |
| Clean Tests | 1-2m | Low | None |

## Contributing

When adding new tests:
1. **Add fast tests** for core functionality
2. **Add real tests** for MLX integration
3. **Use descriptive test names**
4. **Include proper error handling**
5. **Add to appropriate test categories**

## Support

If you encounter issues:
1. Check this guide first
2. Try running fast tests
3. Verify your environment
4. Check the main README for setup instructions
5. Open an issue with detailed error information 
# SwiftUIKit Integration Guide

## Overview

This guide explains how SwiftUIKit is integrated into the MLXEngine project as a local package, allowing you to work on and edit the SwiftUIKit code directly within this project while maintaining the ability to push changes back to the remote repository.

## Architecture

### Local Package Development

SwiftUIKit is integrated as a **local package dependency** within the MLXEngine project:

```
mlx-engine/
├── Package.swift                    # Main package with SwiftUIKit dependency
├── project.yml                      # XcodeGen configuration
├── SwiftUIKit/                      # Local SwiftUIKit package
│   ├── Package.swift               # SwiftUIKit package definition
│   ├── Sources/SwiftUIKit/         # SwiftUIKit source files
│   └── Tests/SwiftUIKitTests/      # SwiftUIKit tests
├── Sources/MLXEngine/              # MLXEngine source files
└── swiftuikit_dev_workflow.sh      # Development workflow script
```

### Key Benefits

1. **Direct Development**: Edit SwiftUIKit code directly within the MLXEngine project
2. **Integrated Testing**: Test both MLXEngine and SwiftUIKit together
3. **Version Control**: Maintain separate git history for SwiftUIKit
4. **Remote Sync**: Push changes back to the remote SwiftUIKit repository
5. **Cross-Platform**: Support for iOS, macOS, tvOS, watchOS, and visionOS

## Development Workflow

### Getting Started

1. **Clone the project** (if not already done):
   ```bash
   git clone <mlx-engine-repo>
   cd mlx-engine
   ```

2. **Sync SwiftUIKit from remote**:
   ```bash
   ./swiftuikit_dev_workflow.sh sync-remote
   ```

3. **Build the integrated project**:
   ```bash
   ./swiftuikit_dev_workflow.sh build
   ```

### Development Commands

The `swiftuikit_dev_workflow.sh` script provides several commands for managing the integration:

| Command | Description |
|---------|-------------|
| `sync-remote` | Sync changes from remote SwiftUIKit repository |
| `push-remote` | Push local changes to remote SwiftUIKit repository |
| `build` | Build the project with SwiftUIKit integration |
| `test` | Run tests for both MLXEngine and SwiftUIKit |
| `clean` | Clean build artifacts |
| `regenerate` | Regenerate Xcode project files |

### Typical Development Cycle

1. **Start development**:
   ```bash
   ./swiftuikit_dev_workflow.sh sync-remote
   ```

2. **Make changes** to SwiftUIKit code in `SwiftUIKit/Sources/SwiftUIKit/`

3. **Test changes**:
   ```bash
   ./swiftuikit_dev_workflow.sh test
   ```

4. **Build and verify**:
   ```bash
   ./swiftuikit_dev_workflow.sh build
   ```

5. **Push changes** (when ready):
   ```bash
   ./swiftuikit_dev_workflow.sh push-remote
   ```

## Package Configuration

### Main Package.swift

The main `Package.swift` includes SwiftUIKit as a local dependency:

```swift
dependencies: [
    .package(url: "https://github.com/ml-explore/mlx-swift", from: "0.10.0"),
    .package(url: "https://github.com/ml-explore/mlx-swift-examples", branch: "main"),
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.3"),
    .package(path: "SwiftUIKit")  // Local SwiftUIKit package
],
targets: [
    .target(
        name: "MLXEngine",
        dependencies: [
            // ... other dependencies
            .product(name: "SwiftUIKit", package: "SwiftUIKit")
        ],
        // ...
    )
]
```

### SwiftUIKit Package.swift

The SwiftUIKit package is self-contained:

```swift
let package = Package(
    name: "SwiftUIKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(name: "SwiftUIKit", targets: ["SwiftUIKit"])
    ],
    targets: [
        .target(name: "SwiftUIKit", path: "Sources/SwiftUIKit"),
        .testTarget(name: "SwiftUIKitTests", dependencies: ["SwiftUIKit"])
    ]
)
```

## Using SwiftUIKit in MLXEngine

### Import SwiftUIKit

In any MLXEngine source file that needs SwiftUIKit components:

```swift
import SwiftUIKit
```

### Available Components

SwiftUIKit provides a comprehensive set of SwiftUI components:

#### Core Components
- `UIAIStyle` - Style system protocol and implementations
- `ChatView` - Chat interface component
- `ModelCardView` - Model selection card
- `ModelDetailView` - Model information display
- `ModelDiscoveryView` - Model discovery interface

#### UI Components
- `SettingsPanel` - Settings interface
- `StyleGallery` - Style selection gallery
- `ErrorBanner` - Error display component
- `DebugPanel` - Debug information panel
- `TokenProgressBar` - Progress indicator
- `AsyncImageView` - Asynchronous image loading

#### Utility Components
- `ChatSessionManager` - Chat session management
- `ChatHistoryView` - Chat history display
- `ChatInputView` - Chat input interface
- `ToastView` - Toast notification component

### Style System

SwiftUIKit includes a comprehensive style system:

```swift
import SwiftUIKit

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Hello, SwiftUIKit!")
        }
        .uiaiStyle(MinimalStyle()) // Apply a built-in style
    }
}
```

## Xcode Integration

### Project Generation

The project uses XcodeGen for consistent project file generation:

```bash
# Regenerate Xcode project
./swiftuikit_dev_workflow.sh regenerate
```

### Target Configuration

All MLXEngine targets include SwiftUIKit as a dependency:

- `MLXEngine_macOS`
- `MLXEngine_iOS`
- `MLXEngine_tvOS`
- `MLXEngine_watchOS`
- `MLXEngine_visionOS`
- `MLXChatApp`
- `MLXChatApp_iOS`

### Build Settings

SwiftUIKit is configured with appropriate build settings for each platform:

- **iOS**: Deployment target 17.0+
- **macOS**: Deployment target 14.0+
- **tvOS**: Deployment target 17.0+
- **watchOS**: Deployment target 10.0+
- **visionOS**: Deployment target 1.0+

## Testing

### Running Tests

Test both MLXEngine and SwiftUIKit together:

```bash
./swiftuikit_dev_workflow.sh test
```

### Test Structure

- **MLXEngine Tests**: `Tests/MLXEngineTests/`
- **SwiftUIKit Tests**: `SwiftUIKit/Tests/SwiftUIKitTests/`

### Test Coverage

Tests cover:
- Component functionality
- Style system integration
- Cross-platform compatibility
- Performance characteristics

## Troubleshooting

### Common Issues

#### Build Errors

1. **Package Resolution Issues**:
   ```bash
   swift package clean
   swift package resolve
   ```

2. **Xcode Project Issues**:
   ```bash
   ./swiftuikit_dev_workflow.sh regenerate
   ```

#### Sync Issues

1. **Remote Sync Conflicts**:
   ```bash
   # Backup current changes
   cp -r SwiftUIKit SwiftUIKit.backup
   
   # Sync from remote
   ./swiftuikit_dev_workflow.sh sync-remote
   
   # Manually merge changes if needed
   ```

2. **Push Failures**:
   ```bash
   # Check git status in SwiftUIKit
   cd SwiftUIKit
   git status
   git log --oneline
   cd ..
   ```

### Debugging

#### Enable Verbose Logging

```bash
# Build with verbose output
swift build -v

# Test with verbose output
swift test -v
```

#### Check Package Dependencies

```bash
# Show package dependencies
swift package show-dependencies
```

## Best Practices

### Development Workflow

1. **Always sync before starting work**:
   ```bash
   ./swiftuikit_dev_workflow.sh sync-remote
   ```

2. **Test frequently**:
   ```bash
   ./swiftuikit_dev_workflow.sh test
   ```

3. **Build before committing**:
   ```bash
   ./swiftuikit_dev_workflow.sh build
   ```

4. **Push changes regularly**:
   ```bash
   ./swiftuikit_dev_workflow.sh push-remote
   ```

### Code Organization

1. **Keep SwiftUIKit self-contained**: Don't add MLXEngine-specific dependencies to SwiftUIKit
2. **Use feature flags**: For experimental features in SwiftUIKit
3. **Maintain backward compatibility**: When possible, maintain API compatibility
4. **Document changes**: Update documentation when adding new components

### Performance Considerations

1. **Lazy loading**: Use lazy loading for heavy components
2. **Memory management**: Be mindful of memory usage in SwiftUIKit components
3. **Cross-platform testing**: Test on all supported platforms

## Migration from UIAI

### What Changed

- **Package Structure**: Moved from embedded UIAI framework to SwiftUIKit package
- **Dependencies**: SwiftUIKit is now a proper Swift Package Manager dependency
- **Build System**: Uses SPM instead of Xcode framework targets
- **Development Workflow**: Added development workflow script for easier management

### Migration Steps

1. **Remove old UIAI references** (already done):
   - Removed `UIAI_iOS` target from `project.yml`
   - Updated `MLXChatApp_iOS` to use SwiftUIKit package

2. **Update imports** (if needed):
   ```swift
   // Old
   import UIAI
   
   // New
   import SwiftUIKit
   ```

3. **Update style usage** (if needed):
   ```swift
   // Old
   .uiaiStyle(style)
   
   // New (same API)
   .uiaiStyle(style)
   ```

## Future Enhancements

### Planned Features

1. **Component Library**: Expand component library with more UI components
2. **Theme System**: Enhanced theme and style system
3. **Documentation**: Interactive component documentation
4. **Performance**: Performance optimizations for large-scale usage

### Contribution Guidelines

1. **Fork the SwiftUIKit repository** for major changes
2. **Use the development workflow** for MLXEngine-specific changes
3. **Follow Swift API Design Guidelines**
4. **Add tests** for new components
5. **Update documentation** for API changes

---

*Last updated: 2024-12-19* 
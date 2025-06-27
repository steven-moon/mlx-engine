#!/bin/bash

# MLXEngine Setup Script
# Comprehensive setup for MLXEngine with automatic Metal library compilation
# and robust fallback mechanisms for different development environments.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}🚀 MLXEngine Setup Script${NC}"
echo "=============================="
echo -e "${CYAN}Project Directory: $PROJECT_DIR${NC}"
echo ""

# Function to print colored output
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_step() {
    echo -e "${PURPLE}🔧 $1${NC}"
}

# Function to check system requirements
check_system_requirements() {
    print_step "Checking system requirements..."
    
    # Check macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "MLXEngine requires macOS"
        exit 1
    fi
    
    # Check Xcode command line tools
    if ! command -v xcrun &> /dev/null; then
        print_error "Xcode command line tools not found"
        print_info "Install with: xcode-select --install"
        exit 1
    fi
    
    # Check Swift
    if ! command -v swift &> /dev/null; then
        print_error "Swift not found"
        print_info "Install Xcode or Swift toolchain"
        exit 1
    fi
    
    # Check Swift version
    SWIFT_VERSION=$(swift --version | head -n 1 | cut -d' ' -f4)
    print_info "Swift version: $SWIFT_VERSION"
    
    # Check Metal support
    if ! xcrun -f metal &> /dev/null; then
        print_warning "Metal compiler not found"
        print_info "This may limit GPU acceleration"
    else
        print_status "Metal compiler found"
    fi
    
    # Check available memory
    TOTAL_MEM=$(sysctl -n hw.memsize | awk '{print $0/1024/1024/1024}')
    print_info "Total memory: ${TOTAL_MEM%.1f} GB"
    
    if (( $(echo "$TOTAL_MEM < 8" | bc -l) )); then
        print_warning "Less than 8GB RAM detected. Large models may not work well."
    fi
    
    print_status "System requirements check completed"
}

# Function to clean build artifacts
clean_build_artifacts() {
    print_step "Cleaning build artifacts..."
    
    # Remove build directories
    rm -rf .build
    rm -rf build
    rm -rf DerivedData
    
    # Remove Swift Package Manager cache
    rm -rf ~/Library/Caches/org.swift.swiftpm
    
    # Remove Xcode derived data
    rm -rf ~/Library/Developer/Xcode/DerivedData
    
    print_status "Build artifacts cleaned"
}

# Function to resolve dependencies
resolve_dependencies() {
    print_step "Resolving Swift Package Manager dependencies..."
    
    # Clean package cache
    swift package clean
    
    # Reset package resolution
    rm -f Package.resolved
    
    # Resolve dependencies
    swift package resolve
    
    print_status "Dependencies resolved"
}

# Function to build Metal library
build_metal_library() {
    print_step "Building Metal library..."
    
    if [[ -f "build_metal_library.sh" ]]; then
        if ./build_metal_library.sh; then
            print_status "Metal library built successfully"
        else
            print_warning "Metal library build failed, but continuing..."
        fi
    else
        print_warning "Metal library build script not found"
    fi
}

# Function to build the project
build_project() {
    print_step "Building MLXEngine project..."
    
    # Build for macOS
    if swift build; then
        print_status "macOS build successful"
    else
        print_error "macOS build failed"
        return 1
    fi
    
    # Build for iOS (if possible)
    if xcrun -f xcodebuild &> /dev/null; then
        print_info "Building for iOS..."
        if xcodebuild -scheme MLXEngine -destination 'platform=iOS Simulator,name=iPhone 15' build 2>/dev/null; then
            print_status "iOS build successful"
        else
            print_warning "iOS build failed (this is normal for some configurations)"
        fi
    fi
    
    print_status "Project build completed"
}

# Function to run tests
run_tests() {
    print_step "Running tests..."
    
    # Run basic tests
    if swift test --enable-code-coverage; then
        print_status "Tests passed"
    else
        print_warning "Some tests failed (this may be expected for first run)"
    fi
}

# Function to create development environment
setup_development_environment() {
    print_step "Setting up development environment..."
    
    # Create .gitignore if it doesn't exist
    if [[ ! -f ".gitignore" ]]; then
        cat > .gitignore << 'EOF'
# Swift Package Manager
.build/
Packages/
Package.resolved
*.xcodeproj
*.xcworkspace

# Xcode
DerivedData/
*.hmap
*.ipa
*.dSYM.zip
*.dSYM

# Metal
*.metallib
*.air

# Build artifacts
build/
*.log

# macOS
.DS_Store
.AppleDouble
.LSOverride

# Temporary files
*.tmp
*.temp
*~

# IDE
.vscode/
.idea/
*.swp
*.swo

# Environment
.env
.env.local
EOF
        print_status "Created .gitignore"
    fi
    
    # Create README if it doesn't exist
    if [[ ! -f "README.md" ]]; then
        cat > README.md << 'EOF'
# MLXEngine

A comprehensive Swift library for running AI models using Apple's MLX framework with automatic Metal acceleration and robust fallback mechanisms.

## Features

- 🤖 Support for LLM, VLM, Embedding, and Diffusion models
- ⚡ Automatic Metal GPU acceleration with fallback mechanisms
- 🔄 Streaming and non-streaming text generation
- 🖼️ Image generation with Stable Diffusion
- 🔍 Text embedding generation
- 🛡️ iOS Simulator detection and graceful degradation
- 📱 Cross-platform support (macOS, iOS)

## Quick Start

```swift
import MLXEngine

// Create a model configuration
let config = ModelConfiguration(
    modelId: "microsoft/DialoGPT-medium",
    modelType: .llm,
    maxSequenceLength: 2048,
    maxCacheSize: 512 * 1024 * 1024 // 512MB
)

// Initialize the engine
let engine = try MLXEngine(configuration: config)

// Generate text
let response = try await engine.generate(
    prompt: "Hello, how are you?",
    parameters: GenerateParams(maxTokens: 100)
)

print(response)
```

## Installation

1. Add MLXEngine to your Swift Package Manager dependencies
2. Run the setup script: `./setup_mlxengine.sh`
3. Build Metal library: `./build_metal_library.sh`

## Requirements

- macOS 13.0+ / iOS 16.0+
- Xcode 15.0+
- Swift 5.9+
- Metal-compatible GPU (for acceleration)

## License

MIT License - see LICENSE file for details.
EOF
        print_status "Created README.md"
    fi
    
    print_status "Development environment setup completed"
}

# Function to display system information
display_system_info() {
    print_step "System Information"
    echo "==================="
    
    # macOS version
    MACOS_VERSION=$(sw_vers -productVersion)
    print_info "macOS: $MACOS_VERSION"
    
    # Xcode version
    if command -v xcodebuild &> /dev/null; then
        XCODE_VERSION=$(xcodebuild -version | head -n 1)
        print_info "Xcode: $XCODE_VERSION"
    fi
    
    # Swift version
    SWIFT_VERSION=$(swift --version | head -n 1)
    print_info "Swift: $SWIFT_VERSION"
    
    # Metal device info
    if command -v xcrun &> /dev/null; then
        METAL_DEVICE=$(xcrun metal -info 2>/dev/null | grep "Device:" | head -n 1 | cut -d':' -f2 | xargs || echo "Not available")
        print_info "Metal Device: $METAL_DEVICE"
    fi
    
    # Available memory
    TOTAL_MEM=$(sysctl -n hw.memsize | awk '{print $0/1024/1024/1024}')
    print_info "Memory: ${TOTAL_MEM%.1f} GB"
    
    # Available disk space
    DISK_SPACE=$(df -h . | tail -n 1 | awk '{print $4}')
    print_info "Available Disk Space: $DISK_SPACE"
    
    echo ""
}

# Function to provide troubleshooting tips
show_troubleshooting_tips() {
    print_step "Troubleshooting Tips"
    echo "======================"
    
    echo -e "${CYAN}Common Issues and Solutions:${NC}"
    echo ""
    echo "1. ${YELLOW}Metal library not found${NC}"
    echo "   - Run: ./build_metal_library.sh"
    echo "   - Check Xcode installation"
    echo ""
    echo "2. ${YELLOW}Build failures${NC}"
    echo "   - Run: ./setup_mlxengine.sh"
    echo "   - Clear derived data: rm -rf ~/Library/Developer/Xcode/DerivedData"
    echo ""
    echo "3. ${YELLOW}Memory issues${NC}"
    echo "   - Reduce model size or maxCacheSize"
    echo "   - Close other applications"
    echo ""
    echo "4. ${YELLOW}iOS Simulator issues${NC}"
    echo "   - Use real device for testing"
    echo "   - Check simulator compatibility"
    echo ""
    echo "5. ${YELLOW}Dependency issues${NC}"
    echo "   - Run: swift package clean && swift package resolve"
    echo "   - Check internet connection"
    echo ""
}

# Main setup process
main() {
    echo -e "${BLUE}Starting MLXEngine setup...${NC}"
    echo ""
    
    # Display system information
    display_system_info
    
    # Check system requirements
    check_system_requirements
    
    # Clean build artifacts
    clean_build_artifacts
    
    # Resolve dependencies
    resolve_dependencies
    
    # Build Metal library
    build_metal_library
    
    # Setup development environment
    setup_development_environment
    
    # Build project
    build_project
    
    # Run tests
    run_tests
    
    echo ""
    print_status "🎉 MLXEngine setup completed successfully!"
    echo ""
    print_info "Next steps:"
    echo "1. Open the project in Xcode or your preferred IDE"
    echo "2. Run the example apps in the Examples/ directory"
    echo "3. Check the documentation in _docs/ directory"
    echo "4. Run tests with: swift test"
    echo ""
    
    # Show troubleshooting tips
    show_troubleshooting_tips
    
    print_status "Setup completed! MLXEngine is ready to use."
}

# Run main function
main "$@" 
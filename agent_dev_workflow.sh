#!/bin/bash
# agent_dev_workflow.sh
#
# Agent-driven development workflow for MLXEngine project
# Automatically builds, tests, and runs simulator after code changes
#
# Usage: ./agent_dev_workflow.sh [command]
#
# Commands:
#   build-ios     - Build iOS app and run simulator
#   build-macos   - Build macOS app
#   test          - Run all tests
#   clean         - Clean build artifacts
#   monitor       - Monitor simulator logs
#   reset-sim     - Reset simulator state
#   full-cycle    - Complete build → test → simulate cycle

set -e

# Configuration
SIMULATOR_DEVICE="iPhone 16"
BUILD_SCHEME_IOS="MLXChatApp-iOS"
BUILD_SCHEME_MACOS="MLXChatApp-macOS"
WORKSPACE_PATH="MLXChatApp/MLXChatApp.xcodeproj/project.xcworkspace"
DERIVED_DATA_PATH="/tmp/MLXEngine-build"
LOG_FILE="/tmp/MLXEngine-build.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

function log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

function log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

function log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

function log_error() {
    echo -e "${RED}❌ $1${NC}"
}

function check_prerequisites() {
    log_info "Checking development environment..."
    
    # Check Xcode
    if ! command -v xcodebuild &> /dev/null; then
        log_error "Xcode not found. Please install Xcode."
        exit 1
    fi
    
    # Check iOS Simulator
    if ! xcrun simctl list devices | grep -q "$SIMULATOR_DEVICE"; then
        log_warning "Simulator device '$SIMULATOR_DEVICE' not found. Creating..."
        xcrun simctl create "$SIMULATOR_DEVICE" "iPhone 16" "iOS17.0"
    fi
    
    # Check xcodegen
    if ! command -v xcodegen &> /dev/null; then
        log_warning "xcodegen not found. Install with: brew install xcodegen"
    fi
    
    log_success "Development environment ready"
}

function clean_build() {
    log_info "Cleaning build artifacts..."
    
    # Clean Swift packages
    swift package clean 2>/dev/null || true
    swift package clean --package-path SwiftUIKit 2>/dev/null || true
    
    # Clean Xcode derived data
    rm -rf ~/Library/Developer/Xcode/DerivedData/*MLXEngine* 2>/dev/null || true
    rm -rf "$DERIVED_DATA_PATH" 2>/dev/null || true
    
    # Clean build logs
    rm -f "$LOG_FILE" 2>/dev/null || true
    
    log_success "Build artifacts cleaned"
}

function build_ios_app() {
    log_info "Building iOS app..."
    
    # Ensure simulator is available
    xcrun simctl boot "$SIMULATOR_DEVICE" 2>/dev/null || true
    
    # Build the app
    xcodebuild -scheme "$BUILD_SCHEME_IOS" \
        -workspace "$WORKSPACE_PATH" \
        -destination "platform=iOS Simulator,name=$SIMULATOR_DEVICE" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        build \
        > "$LOG_FILE" 2>&1
    
    if [ $? -eq 0 ]; then
        log_success "iOS app built successfully"
        return 0
    else
        log_error "iOS build failed. Check logs: $LOG_FILE"
        cat "$LOG_FILE" | tail -20
        return 1
    fi
}

function build_macos_app() {
    log_info "Building macOS app..."
    
    xcodebuild -scheme "$BUILD_SCHEME_MACOS" \
        -workspace "$WORKSPACE_PATH" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        build \
        > "$LOG_FILE" 2>&1
    
    if [ $? -eq 0 ]; then
        log_success "macOS app built successfully"
        return 0
    else
        log_error "macOS build failed. Check logs: $LOG_FILE"
        cat "$LOG_FILE" | tail -20
        return 1
    fi
}

function run_tests() {
    log_info "Running tests..."
    
    # Run MLXEngine tests
    log_info "Running MLXEngine tests..."
    swift test --package-path . --filter MLXEngineTests > "$LOG_FILE" 2>&1
    
    if [ $? -eq 0 ]; then
        log_success "MLXEngine tests passed"
    else
        log_error "MLXEngine tests failed"
        cat "$LOG_FILE" | tail -20
        return 1
    fi
    
    # Run SwiftUIKit tests if available
    if [ -d "SwiftUIKit" ]; then
        log_info "Running SwiftUIKit tests..."
        swift test --package-path SwiftUIKit >> "$LOG_FILE" 2>&1
        
        if [ $? -eq 0 ]; then
            log_success "SwiftUIKit tests passed"
        else
            log_warning "SwiftUIKit tests failed"
            cat "$LOG_FILE" | tail -20
        fi
    fi
    
    return 0
}

function launch_simulator() {
    log_info "Launching simulator and app..."
    
    # Boot simulator
    xcrun simctl boot "$SIMULATOR_DEVICE" 2>/dev/null || true
    
    # Install and launch app
    xcodebuild -scheme "$BUILD_SCHEME_IOS" \
        -workspace "$WORKSPACE_PATH" \
        -destination "platform=iOS Simulator,name=$SIMULATOR_DEVICE" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        build-for-testing test-without-building \
        > "$LOG_FILE" 2>&1
    
    if [ $? -eq 0 ]; then
        log_success "App launched in simulator"
        return 0
    else
        log_error "Failed to launch app in simulator"
        cat "$LOG_FILE" | tail -20
        return 1
    fi
}

function monitor_logs() {
    log_info "Monitoring simulator logs..."
    log_info "Press Ctrl+C to stop monitoring"
    
    # Monitor app logs
    xcrun simctl spawn booted log stream \
        --predicate 'process == "MLXChatApp"' \
        --style compact
}

function reset_simulator() {
    log_info "Resetting simulator..."
    
    # Shutdown simulator
    xcrun simctl shutdown "$SIMULATOR_DEVICE" 2>/dev/null || true
    
    # Erase simulator
    xcrun simctl erase "$SIMULATOR_DEVICE"
    
    log_success "Simulator reset complete"
}

function full_development_cycle() {
    log_info "Starting full development cycle..."
    
    # Check prerequisites
    check_prerequisites
    
    # Clean build
    clean_build
    
    # Build iOS app
    if ! build_ios_app; then
        log_error "Development cycle failed at build step"
        return 1
    fi
    
    # Run tests
    if ! run_tests; then
        log_error "Development cycle failed at test step"
        return 1
    fi
    
    # Launch simulator
    if ! launch_simulator; then
        log_error "Development cycle failed at simulator launch"
        return 1
    fi
    
    log_success "Full development cycle completed successfully!"
    log_info "App is running in simulator. Ready for testing."
    
    return 0
}

function show_status() {
    log_info "Development Environment Status:"
    echo "  Simulator Device: $SIMULATOR_DEVICE"
    echo "  iOS Scheme: $BUILD_SCHEME_IOS"
    echo "  macOS Scheme: $BUILD_SCHEME_MACOS"
    echo "  Workspace: $WORKSPACE_PATH"
    echo "  Derived Data: $DERIVED_DATA_PATH"
    echo "  Log File: $LOG_FILE"
    
    # Check simulator status
    if xcrun simctl list devices | grep -q "$SIMULATOR_DEVICE.*Booted"; then
        log_success "Simulator is running"
    else
        log_warning "Simulator is not running"
    fi
}

function show_help() {
    echo "Agent Development Workflow for MLXEngine"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  build-ios     - Build iOS app and prepare simulator"
    echo "  build-macos   - Build macOS app"
    echo "  test          - Run all tests"
    echo "  clean         - Clean build artifacts"
    echo "  monitor       - Monitor simulator logs"
    echo "  reset-sim     - Reset simulator state"
    echo "  full-cycle    - Complete build → test → simulate cycle"
    echo "  status        - Show development environment status"
    echo "  help          - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 full-cycle    # Complete development cycle"
    echo "  $0 build-ios     # Build iOS app only"
    echo "  $0 monitor       # Monitor app logs"
}

# Main command handling
case "${1:-help}" in
    "build-ios")
        check_prerequisites
        build_ios_app
        ;;
    "build-macos")
        check_prerequisites
        build_macos_app
        ;;
    "test")
        run_tests
        ;;
    "clean")
        clean_build
        ;;
    "monitor")
        monitor_logs
        ;;
    "reset-sim")
        reset_simulator
        ;;
    "full-cycle")
        full_development_cycle
        ;;
    "status")
        show_status
        ;;
    "help"|*)
        show_help
        ;;
esac 
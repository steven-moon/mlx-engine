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

# Configuration - Updated to match actual project structure
SIMULATOR_DEVICE="iPhone 16"
BUILD_SCHEME_IOS="MLXChatApp-iOS"
BUILD_SCHEME_MACOS="MLXChatApp-macOS"
WORKSPACE_PATH="MLXChatApp/MLXChatApp.xcodeproj/project.xcworkspace"
DERIVED_DATA_PATH="/tmp/MLXEngine-build"
LOG_FILE="/tmp/MLXEngine-build.log"

# Bundle and process identifiers - Updated to match actual values
BUNDLE_ID="com.clevercoding.MLXChatApp-iOS"
PROCESS_NAME="MLXChatApp-iOS"

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

function ensure_simulator_ready() {
    log_info "Ensuring Simulator GUI is open..."
    open -a Simulator

    log_info "Booting simulator device: $SIMULATOR_DEVICE"
    xcrun simctl boot "$SIMULATOR_DEVICE" 2>/dev/null || true

    # Wait for simulator to be fully booted
    log_info "Waiting for simulator to boot..."
    for i in {1..15}; do
        if xcrun simctl list devices | grep "$SIMULATOR_DEVICE" | grep -q "Booted"; then
            log_success "Simulator is booted"
            return 0
        fi
        sleep 2
    done
    
    log_error "Simulator failed to boot within 30 seconds"
    return 1
}

function install_and_launch_app() {
    # Find the built app
    APP_PATH=$(find "$DERIVED_DATA_PATH" -name "*.app" -path "*/Debug-iphonesimulator/*" | head -1)
    if [ -z "$APP_PATH" ]; then
        log_error "Could not find built .app bundle in $DERIVED_DATA_PATH"
        log_info "Available files:"
        find "$DERIVED_DATA_PATH" -name "*.app" 2>/dev/null || true
        return 1
    fi

    log_info "Found app: $APP_PATH"
    
    # Verify bundle ID matches
    ACTUAL_BUNDLE_ID=$(plutil -extract CFBundleIdentifier raw "$APP_PATH/Info.plist" 2>/dev/null || echo "")
    if [ "$ACTUAL_BUNDLE_ID" != "$BUNDLE_ID" ]; then
        log_warning "Bundle ID mismatch. Expected: $BUNDLE_ID, Found: $ACTUAL_BUNDLE_ID"
        log_info "Using actual bundle ID: $ACTUAL_BUNDLE_ID"
        BUNDLE_ID="$ACTUAL_BUNDLE_ID"
    fi

    # Uninstall existing app if present
    log_info "Uninstalling existing app if present..."
    xcrun simctl uninstall booted "$BUNDLE_ID" 2>/dev/null || true

    # Install the app
    log_info "Installing app: $APP_PATH"
    if ! xcrun simctl install booted "$APP_PATH"; then
        log_error "App install failed."
        return 1
    fi

    # Launch the app
    log_info "Launching app with bundle ID: $BUNDLE_ID"
    if ! xcrun simctl launch booted "$BUNDLE_ID"; then
        log_error "App launch failed."
        return 1
    fi

    # Wait a moment for app to start
    sleep 3

    # Verify app is running
    if xcrun simctl get_app_container booted "$BUNDLE_ID" > /dev/null 2>&1; then
        log_success "App is running in simulator."
        # Extract executable name from Info.plist
        APP_EXECUTABLE=$(plutil -extract CFBundleExecutable raw "$APP_PATH/Info.plist")
        log_info "Tailing logs for simulator process: $APP_EXECUTABLE"
        xcrun simctl spawn booted log stream --predicate "process == \"$APP_EXECUTABLE\"" --style compact
        return 0
    else
        log_warning "App may not be running. Checking logs..."
        return 1
    fi
}

function launch_simulator() {
    # Ensure simulator is ready
    if ! ensure_simulator_ready; then
        return 1
    fi

    # Install and launch the app
    if ! install_and_launch_app; then
        log_error "Failed to install and launch app"
        return 1
    fi

    log_success "Simulator launch completed successfully"
}

function monitor_logs() {
    log_info "Monitoring simulator logs..."
    # Find the built app
    APP_PATH=$(find "$DERIVED_DATA_PATH" -name "*.app" -path "*/Debug-iphonesimulator/*" | head -1)
    if [ -z "$APP_PATH" ]; then
        log_error "Could not find built .app bundle in $DERIVED_DATA_PATH"
        return 1
    fi
    APP_EXECUTABLE=$(plutil -extract CFBundleExecutable raw "$APP_PATH/Info.plist")
    log_info "Tailing logs for simulator process: $APP_EXECUTABLE"
    xcrun simctl spawn booted log stream --predicate "process == \"$APP_EXECUTABLE\"" --style compact
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
    
    # Reset and clean
    reset_simulator
    clean_build
    
    # Build the app
    if ! build_ios_app; then
        log_error "Build failed. Stopping cycle."
        return 1
    fi
    
    # Launch simulator and app
    if ! launch_simulator; then
        log_error "Simulator launch failed. Stopping cycle."
        return 1
    fi
    
    log_success "Development cycle completed successfully"
    log_info "App should now be running in the simulator"
}

function show_status() {
    log_info "Development Environment Status:"
    echo "  Simulator Device: $SIMULATOR_DEVICE"
    echo "  iOS Scheme: $BUILD_SCHEME_IOS"
    echo "  macOS Scheme: $BUILD_SCHEME_MACOS"
    echo "  Workspace: $WORKSPACE_PATH"
    echo "  Derived Data: $DERIVED_DATA_PATH"
    echo "  Log File: $LOG_FILE"
    echo "  Bundle ID: $BUNDLE_ID"
    echo "  Process Name: $PROCESS_NAME"
    
    # Check simulator status
    if xcrun simctl list devices | grep -q "$SIMULATOR_DEVICE.*Booted"; then
        log_success "Simulator is running"
    else
        log_warning "Simulator is not running"
    fi
    
    # Check if app is installed
    if xcrun simctl get_app_container booted "$BUNDLE_ID" > /dev/null 2>&1; then
        log_success "App is installed in simulator"
    else
        log_warning "App is not installed in simulator"
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
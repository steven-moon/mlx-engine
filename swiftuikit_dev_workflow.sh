#!/bin/bash
# swiftuikit_dev_workflow.sh
#
# Development workflow for SwiftUIKit package integration with MLXEngine
#
# Usage: ./swiftuikit_dev_workflow.sh [command]
#
# Commands:
#   sync-remote    - Sync changes from remote SwiftUIKit repository
#   push-remote    - Push local changes to remote SwiftUIKit repository
#   build          - Build the project with SwiftUIKit integration
#   test           - Run tests for both MLXEngine and SwiftUIKit
#   clean          - Clean build artifacts
#   regenerate     - Regenerate Xcode project files

set -e

SWIFTUIKIT_REMOTE="https://github.com/steven-moon/swift-uikit.git"
SWIFTUIKIT_LOCAL="SwiftUIKit"
TEMP_DIR="/tmp/swiftuikit-temp"

function sync_from_remote() {
    echo "🔄 Syncing SwiftUIKit from remote repository..."
    
    # Clone remote to temp directory
    if [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
    git clone "$SWIFTUIKIT_REMOTE" "$TEMP_DIR"
    
    # Remove git history from temp
    rm -rf "$TEMP_DIR/.git"
    
    # Backup current local changes
    if [[ -d "$SWIFTUIKIT_LOCAL" ]]; then
        echo "📦 Backing up current local changes..."
        cp -r "$SWIFTUIKIT_LOCAL" "${SWIFTUIKIT_LOCAL}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    # Replace local with remote content
    rm -rf "$SWIFTUIKIT_LOCAL"
    cp -r "$TEMP_DIR" "$SWIFTUIKIT_LOCAL"
    
    echo "✅ SwiftUIKit synced from remote repository"
    echo "💡 Local changes backed up to ${SWIFTUIKIT_LOCAL}.backup.*"
}

function push_to_remote() {
    echo "🚀 Pushing SwiftUIKit changes to remote repository..."
    
    if [[ ! -d "$SWIFTUIKIT_LOCAL" ]]; then
        echo "❌ SwiftUIKit directory not found"
        exit 1
    fi
    
    # Create temporary git repository
    cd "$SWIFTUIKIT_LOCAL"
    
    # Initialize git if not already done
    if [[ ! -d ".git" ]]; then
        git init
        git remote add origin "$SWIFTUIKIT_REMOTE"
    fi
    
    # Add all changes
    git add .
    
    # Check if there are changes to commit
    if git diff --cached --quiet; then
        echo "ℹ️  No changes to commit"
        cd ..
        return
    fi
    
    # Commit changes
    git commit -m "Update SwiftUIKit from MLXEngine development"
    
    # Push to remote
    git push origin main
    
    cd ..
    echo "✅ SwiftUIKit changes pushed to remote repository"
}

function build_project() {
    echo "🔨 Building project with SwiftUIKit integration..."
    
    # Clean previous build
    swift package clean
    
    # Build the project
    swift build
    
    echo "✅ Build completed successfully"
}

function run_tests() {
    echo "🧪 Running tests for MLXEngine and SwiftUIKit..."
    
    # Run MLXEngine tests
    echo "📋 Running MLXEngine tests..."
    swift test --package-path . --filter MLXEngineTests
    
    # Run SwiftUIKit tests
    echo "📋 Running SwiftUIKit tests..."
    swift test --package-path SwiftUIKit
    
    echo "✅ All tests completed"
}

function clean_build() {
    echo "🧹 Cleaning build artifacts..."
    
    # Clean main project
    swift package clean
    
    # Clean SwiftUIKit
    swift package clean --package-path SwiftUIKit
    
    # Remove Xcode derived data for this project
    rm -rf ~/Library/Developer/Xcode/DerivedData/*MLXEngine*
    
    echo "✅ Build artifacts cleaned"
}

function regenerate_project() {
    echo "🔄 Regenerating Xcode project files..."
    
    # Regenerate using xcodegen
    if command -v xcodegen &> /dev/null; then
        xcodegen generate
        echo "✅ Xcode project regenerated"
    else
        echo "❌ xcodegen not found. Please install it first:"
        echo "   brew install xcodegen"
    fi
}

function show_help() {
    echo "SwiftUIKit Development Workflow"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  sync-remote    - Sync changes from remote SwiftUIKit repository"
    echo "  push-remote    - Push local changes to remote SwiftUIKit repository"
    echo "  build          - Build the project with SwiftUIKit integration"
    echo "  test           - Run tests for both MLXEngine and SwiftUIKit"
    echo "  clean          - Clean build artifacts"
    echo "  regenerate     - Regenerate Xcode project files"
    echo "  help           - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 sync-remote    # Get latest changes from remote"
    echo "  $0 build          # Build the integrated project"
    echo "  $0 test           # Run all tests"
}

# Main command handling
case "${1:-help}" in
    "sync-remote")
        sync_from_remote
        ;;
    "push-remote")
        push_to_remote
        ;;
    "build")
        build_project
        ;;
    "test")
        run_tests
        ;;
    "clean")
        clean_build
        ;;
    "regenerate")
        regenerate_project
        ;;
    "help"|*)
        show_help
        ;;
esac 
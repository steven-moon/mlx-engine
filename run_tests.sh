#!/bin/bash

# MLXEngine Test Runner
# This script provides different options for running tests

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "MLXEngine Test Runner"
    echo ""
    echo "Usage: $0 [OPTION]"
    echo ""
    echo "Options:"
    echo "  fast          Run fast unit tests only (mock mode)"
    echo "  real          Run real model tests (requires MLXENGINE_RUN_REAL_TESTS=true)"
    echo "  all           Run all tests"
    echo "  clean         Clean build and run fast tests"
    echo "  help          Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  MLXENGINE_RUN_REAL_TESTS=true  Enable real model tests"
    echo "  MLXENGINE_VERBOSE=true         Enable verbose output"
    echo ""
    echo "Examples:"
    echo "  $0 fast                        # Run fast tests only"
    echo "  MLXENGINE_RUN_REAL_TESTS=true $0 real  # Run real model tests"
    echo "  $0 all                         # Run all tests"
}

# Function to run fast tests
run_fast_tests() {
    print_status "Running fast unit tests (mock mode)..."
    
    # Set environment for fast tests
    export MLXENGINE_RUN_REAL_TESTS=false
    
    # Run specific test classes that don't require real models
    swift test --filter ChatSessionTests --filter MLXEngineTests --filter ModelRegistryTests --filter SanityTests
    
    print_success "Fast tests completed!"
}

# Function to run real model tests
run_real_tests() {
    if [ "$MLXENGINE_RUN_REAL_TESTS" != "true" ]; then
        print_warning "Real model tests are disabled. Set MLXENGINE_RUN_REAL_TESTS=true to enable."
        print_status "Running fast tests instead..."
        run_fast_tests
        return
    fi
    
    print_status "Running real model tests..."
    print_warning "This may take a while and requires internet connection."
    
    # Run all tests including real model tests
    swift test
    
    print_success "Real model tests completed!"
}

# Function to run all tests
run_all_tests() {
    print_status "Running all tests..."
    
    if [ "$MLXENGINE_RUN_REAL_TESTS" != "true" ]; then
        print_warning "Real model tests are disabled. Set MLXENGINE_RUN_REAL_TESTS=true to enable full testing."
    fi
    
    swift test
    
    print_success "All tests completed!"
}

# Function to clean and run tests
run_clean_tests() {
    print_status "Cleaning build..."
    swift package clean
    
    print_status "Building..."
    swift build
    
    print_status "Running fast tests after clean build..."
    run_fast_tests
}

# Main script logic
case "${1:-fast}" in
    "fast")
        run_fast_tests
        ;;
    "real")
        run_real_tests
        ;;
    "all")
        run_all_tests
        ;;
    "clean")
        run_clean_tests
        ;;
    "help"|"-h"|"--help")
        show_usage
        ;;
    *)
        print_error "Unknown option: $1"
        echo ""
        show_usage
        exit 1
        ;;
esac 
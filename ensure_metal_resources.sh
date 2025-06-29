#!/bin/bash
set -e

# Helper for colored output
green='\033[0;32m'
red='\033[0;31m'
reset='\033[0m'
function print_status() { echo -e "${green}==> $1${reset}"; }
function print_error() { echo -e "${red}==> $1${reset}"; }

# Always resolve paths relative to this script's location
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_METALLIB="$SCRIPT_DIR/Sources/MLXEngine/Resources/default.metallib"
TEST_RESOURCES="$SCRIPT_DIR/Tests/MLXEngineTests/Resources/default.metallib"
BUILD_SCRIPT="$SCRIPT_DIR/build_metal_library.sh"

# 1. Ensure metallib is built
if [ ! -f "$SRC_METALLIB" ]; then
  print_status "default.metallib missing, running build_metal_library.sh..."
  bash "$BUILD_SCRIPT"
else
  print_status "default.metallib already present in Sources/MLXEngine/Resources."
fi

# 2. Copy to test resources
if [ ! -f "$TEST_RESOURCES" ]; then
  print_status "Copying default.metallib to Tests/MLXEngineTests/Resources..."
  mkdir -p "$(dirname "$TEST_RESOURCES")"
  cp "$SRC_METALLIB" "$TEST_RESOURCES"
else
  print_status "default.metallib already present in Tests/MLXEngineTests/Resources."
fi

# 3. Copy to all test bundle resource locations
for xctest in $(find "$SCRIPT_DIR/.build" -name MLXEnginePackageTests.xctest 2>/dev/null); do
  bundle_res="$xctest/Contents/Resources/default.metallib"
  if [ ! -f "$bundle_res" ]; then
    print_status "Copying default.metallib to $bundle_res..."
    mkdir -p "$(dirname "$bundle_res")"
    cp "$SRC_METALLIB" "$bundle_res"
  else
    print_status "default.metallib already present in $bundle_res."
  fi
done

# Final check: fail-fast if still missing from test bundle
if [ ! -f "$TEST_RESOURCES" ]; then
  print_error "default.metallib is still missing from test bundle resources: $TEST_RESOURCES"
  exit 1
fi
print_status "🎉 Metal library resource propagation complete!" 
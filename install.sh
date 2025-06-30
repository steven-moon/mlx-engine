#!/bin/bash

# MLXEngine install script: Ensures Metal library is present for both main and test targets
set -e

MAIN_METALLIB="Sources/MLXEngine/Resources/default.metallib"
TEST_METALLIB="Tests/MLXEngineTests/Resources/default.metallib"
BUILD_SCRIPT="build_metal_library.sh"

# Build main metallib if missing
if [ ! -f "$MAIN_METALLIB" ]; then
  echo "[install.sh] Main default.metallib not found. Building..."
  if [ -f "$BUILD_SCRIPT" ]; then
    bash "$BUILD_SCRIPT"
  elif [ -f "mlx-engine/$BUILD_SCRIPT" ]; then
    bash "mlx-engine/$BUILD_SCRIPT"
  else
    echo "[install.sh] ERROR: build_metal_library.sh not found!" >&2
    exit 1
  fi
else
  echo "[install.sh] Main default.metallib already present."
fi

# Copy to test resources if missing
if [ ! -f "$TEST_METALLIB" ]; then
  echo "[install.sh] Test default.metallib not found. Copying..."
  mkdir -p "Tests/MLXEngineTests/Resources"
  cp "$MAIN_METALLIB" "$TEST_METALLIB"
else
  echo "[install.sh] Test default.metallib already present."
fi

echo "[install.sh] Metal library install check complete." 
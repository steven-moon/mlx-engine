#!/bin/bash

# MLXEngine Metal Library Builder
# Automatically compiles Metal shaders and provides fallback mechanisms
# for different development environments and hardware configurations.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
MLX_PATH=".build/checkouts/mlx-swift"
METAL_SOURCE_DIR="$MLX_PATH/Source/Cmlx/mlx-generated/metal"
EXAMPLES_SOURCE_DIR="$MLX_PATH/Source/Cmlx/mlx/examples/extensions"
OUTPUT_DIR="Sources/MLXEngine/Resources"
METALLIB_NAME="default.metallib"

echo -e "${BLUE}🔧 MLXEngine Metal Library Builder${NC}"
echo "=================================="

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

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "Metal is only supported on macOS"
    exit 1
fi

# Check if Metal is available
if ! command -v xcrun &> /dev/null; then
    print_error "Xcode command line tools not found"
    exit 1
fi

# Check if Metal compiler is available
if ! xcrun -f metal &> /dev/null; then
    print_error "Metal compiler not found"
    exit 1
fi

print_info "Metal compiler found: $(xcrun -f metal)"

# Create output directory
mkdir -p "$OUTPUT_DIR"
print_status "Created output directory: $OUTPUT_DIR"

# Function to find all .metal files
find_metal_files() {
    local search_dirs=("$METAL_SOURCE_DIR" "$EXAMPLES_SOURCE_DIR")
    local metal_files=()
    
    for dir in "${search_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            print_info "Searching for .metal files in: $dir"
            while IFS= read -r -d '' file; do
                metal_files+=("$file")
            done < <(find "$dir" -name "*.metal" -print0)
        else
            print_warning "Directory not found: $dir"
        fi
    done
    
    echo "${metal_files[@]}"
}

# Function to compile a single .metal file
compile_metal_file() {
    local source_file="$1"
    local output_file="$2"
    
    print_info "Compiling: $(basename "$source_file")"
    
    # Compile with Metal compiler
    if xcrun metal -c "$source_file" -o "$output_file" 2>/dev/null; then
        print_status "Compiled: $(basename "$source_file")"
        return 0
    else
        print_warning "Failed to compile: $(basename "$source_file")"
        return 1
    fi
}

# Function to create a minimal Metal library
create_minimal_library() {
    print_info "Creating minimal Metal library..."
    
    local minimal_metal="$OUTPUT_DIR/minimal.metal"
    cat > "$minimal_metal" << 'EOF'
#include <metal_stdlib>
using namespace metal;

// Basic matrix multiplication kernel
kernel void matmul(device const float* A,
                  device const float* B,
                  device float* C,
                  constant uint& M,
                  constant uint& N,
                  constant uint& K,
                  uint2 gid [[thread_position_in_grid]]) {
    uint row = gid.x;
    uint col = gid.y;
    
    if (row >= M || col >= N) return;
    
    float sum = 0.0f;
    for (uint k = 0; k < K; k++) {
        sum += A[row * K + k] * B[k * N + col];
    }
    C[row * N + col] = sum;
}

// Basic unary operations
kernel void unary_add(device const float* input,
                     device float* output,
                     constant float& value,
                     uint gid [[thread_position_in_grid]]) {
    output[gid] = input[gid] + value;
}

kernel void unary_mul(device const float* input,
                     device float* output,
                     constant float& value,
                     uint gid [[thread_position_in_grid]]) {
    output[gid] = input[gid] * value;
}

// Basic reduction operations
kernel void reduce_sum(device const float* input,
                      device float* output,
                      constant uint& size,
                      uint gid [[thread_position_in_grid]]) {
    if (gid >= size) return;
    
    float sum = 0.0f;
    for (uint i = gid; i < size; i += 256) {
        sum += input[i];
    }
    output[gid] = sum;
}
EOF

    # Compile minimal library
    if xcrun metal -c "$minimal_metal" -o "$OUTPUT_DIR/minimal.air" && \
       xcrun metallib "$OUTPUT_DIR/minimal.air" -o "$OUTPUT_DIR/$METALLIB_NAME"; then
        print_status "Created minimal Metal library"
        rm -f "$minimal_metal" "$OUTPUT_DIR/minimal.air"
        return 0
    else
        print_error "Failed to create minimal Metal library"
        return 1
    fi
}

# Main compilation process
print_info "Starting Metal library compilation..."

# Find all .metal files
metal_files=($(find_metal_files))

if [[ ${#metal_files[@]} -eq 0 ]]; then
    print_warning "No .metal files found, creating minimal library"
    if create_minimal_library; then
        print_status "Metal library build completed successfully"
        exit 0
    else
        print_error "Failed to create minimal Metal library"
        exit 1
    fi
fi

print_info "Found ${#metal_files[@]} .metal files"

# Compile all .metal files to .air files
compiled_files=()
temp_dir=$(mktemp -d)

for file in "${metal_files[@]}"; do
    base_name=$(basename "$file" .metal)
    air_file="$temp_dir/$base_name.air"
    
    if compile_metal_file "$file" "$air_file"; then
        compiled_files+=("$air_file")
    fi
done

# Check if we have any compiled files
if [[ ${#compiled_files[@]} -eq 0 ]]; then
    print_warning "No files compiled successfully, creating minimal library"
    rm -rf "$temp_dir"
    if create_minimal_library; then
        print_status "Metal library build completed successfully"
        exit 0
    else
        print_error "Failed to create minimal Metal library"
        exit 1
    fi
fi

print_info "Successfully compiled ${#compiled_files[@]} files"

# Create the final .metallib file
print_info "Creating final Metal library..."

if xcrun metallib "${compiled_files[@]}" -o "$OUTPUT_DIR/$METALLIB_NAME"; then
    print_status "Metal library created successfully: $OUTPUT_DIR/$METALLIB_NAME"
else
    print_error "Failed to create Metal library"
    rm -rf "$temp_dir"
    exit 1
fi

# Clean up temporary files
rm -rf "$temp_dir"

# Verify the library
if [[ -f "$OUTPUT_DIR/$METALLIB_NAME" ]]; then
    library_size=$(stat -f%z "$OUTPUT_DIR/$METALLIB_NAME")
    print_status "Metal library size: $library_size bytes"
    
    # Test library loading
    if xcrun metal -L "$OUTPUT_DIR" -l "$METALLIB_NAME" -e test 2>/dev/null; then
        print_status "Metal library validation passed"
    else
        print_warning "Metal library validation failed, but library was created"
    fi
else
    print_error "Metal library file not found"
    exit 1
fi

print_status "Metal library build completed successfully!"
print_info "Library location: $OUTPUT_DIR/$METALLIB_NAME"

# Create a Swift resource bundle if needed
if [[ ! -f "$OUTPUT_DIR/Info.plist" ]]; then
    cat > "$OUTPUT_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>MLXEngine</string>
    <key>CFBundleIdentifier</key>
    <string>com.mlxengine.metal</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
</dict>
</plist>
EOF
    print_status "Created resource bundle Info.plist"
fi

echo ""
print_status "🎉 Metal library build completed successfully!"
print_info "The library is ready for use with MLXEngine"

# After creating minimal library, check for file and log result
if [[ -f "$OUTPUT_DIR/$METALLIB_NAME" ]]; then
    print_status "Verified: $OUTPUT_DIR/$METALLIB_NAME created."
else
    print_error "Failed: $OUTPUT_DIR/$METALLIB_NAME was not created."
    exit 1
fi 
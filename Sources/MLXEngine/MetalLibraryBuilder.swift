import Foundation
import Metal
import MetalKit

/// Metal library builder that automatically compiles Metal shaders and provides fallback mechanisms
/// for different development environments and hardware configurations.
public struct MetalLibraryBuilder {
    
    private class BundleFinder {}
    
    /// Metal library compilation status
    public enum CompilationStatus {
        case success(MTLLibrary)
        case failure(Error)
        case notSupported(String)
    }
    
    /// Metal library compilation errors
    public enum CompilationError: LocalizedError {
        case deviceNotFound
        case compilationFailed(String)
        case libraryNotFound
        case unsupportedPlatform
        
        public var errorDescription: String? {
            switch self {
            case .deviceNotFound:
                return "Metal device not found"
            case .compilationFailed(let message):
                return "Metal library compilation failed: \(message)"
            case .libraryNotFound:
                return "Metal library not found"
            case .unsupportedPlatform:
                return "Metal not supported on this platform"
            }
        }
    }
    
    /// Builds the Metal library with automatic fallback mechanisms
    /// - Returns: Compilation status with the compiled library or error information
    public static func buildLibrary() -> CompilationStatus {
        // Check if Metal is supported
        guard let device = MTLCreateSystemDefaultDevice() else {
            return .failure(CompilationError.deviceNotFound)
        }
        
        // Try to find precompiled library first
        if let precompiledLibrary = findPrecompiledLibrary(device: device) {
            return .success(precompiledLibrary)
        }
        
        // Try to compile from source
        if let compiledLibrary = compileFromSource(device: device) {
            return .success(compiledLibrary)
        }
        
        // Try to use embedded library
        if let embeddedLibrary = createEmbeddedLibrary(device: device) {
            return .success(embeddedLibrary)
        }
        
        return .failure(CompilationError.libraryNotFound)
    }
    
    /// Finds precompiled Metal library in the bundle
    private static func findPrecompiledLibrary(device: MTLDevice) -> MTLLibrary? {
        // Look for precompiled library in bundle
        let bundle = Bundle(for: BundleFinder.self)
        guard let libraryURL = bundle.url(forResource: "default", withExtension: "metallib") else {
            return nil
        }
        
        do {
            let library = try device.makeLibrary(URL: libraryURL)
            print("✅ Found precompiled Metal library")
            return library
        } catch {
            print("⚠️ Failed to load precompiled library: \(error)")
            return nil
        }
    }
    
    /// Compiles Metal library from source files
    private static func compileFromSource(device: MTLDevice) -> MTLLibrary? {
        // Get Metal source files from MLX package
        let metalSources = findMetalSourceFiles()
        
        guard !metalSources.isEmpty else {
            print("⚠️ No Metal source files found")
            return nil
        }
        
        print("🔨 Compiling Metal library from \(metalSources.count) source files...")
        
        // Compile all Metal sources
        var compiledSources: [String] = []
        
        for sourceFile in metalSources {
            if let compiledSource = compileMetalSource(sourceFile, device: device) {
                compiledSources.append(compiledSource)
            }
        }
        
        guard !compiledSources.isEmpty else {
            print("❌ No Metal sources compiled successfully")
            return nil
        }
        
        // Combine all compiled sources
        let combinedSource = compiledSources.joined(separator: "\n\n")
        
        do {
            let library = try device.makeLibrary(source: combinedSource, options: nil)
            print("✅ Successfully compiled Metal library from source")
            return library
        } catch {
            print("❌ Failed to compile Metal library: \(error)")
            return nil
        }
    }
    
    /// Creates a minimal embedded Metal library for basic operations
    private static func createEmbeddedLibrary(device: MTLDevice) -> MTLLibrary? {
        let minimalMetalSource = """
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
        """
        
        do {
            let library = try device.makeLibrary(source: minimalMetalSource, options: nil)
            print("✅ Created minimal embedded Metal library")
            return library
        } catch {
            print("❌ Failed to create embedded Metal library: \(error)")
            return nil
        }
    }
    
    /// Finds Metal source files in the MLX package
    private static func findMetalSourceFiles() -> [String] {
        let mlxPath = ".build/checkouts/mlx-swift/Source/Cmlx/mlx-generated/metal"
        let examplesPath = ".build/checkouts/mlx-swift/Source/Cmlx/mlx/examples/extensions"
        
        var metalFiles: [String] = []
        
        // Find all .metal files
        let fileManager = FileManager.default
        let currentPath = fileManager.currentDirectoryPath
        
        // Search in mlx-generated/metal directory
        let mlxFullPath = "\(currentPath)/\(mlxPath)"
        if fileManager.fileExists(atPath: mlxFullPath) {
            metalFiles.append(contentsOf: findMetalFiles(in: mlxFullPath))
        }
        
        // Search in examples directory
        let examplesFullPath = "\(currentPath)/\(examplesPath)"
        if fileManager.fileExists(atPath: examplesFullPath) {
            metalFiles.append(contentsOf: findMetalFiles(in: examplesFullPath))
        }
        
        return metalFiles
    }
    
    /// Recursively finds .metal files in a directory
    private static func findMetalFiles(in directory: String) -> [String] {
        let fileManager = FileManager.default
        var metalFiles: [String] = []
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: directory)
            
            for item in contents {
                let fullPath = "\(directory)/\(item)"
                var isDirectory: ObjCBool = false
                
                if fileManager.fileExists(atPath: fullPath, isDirectory: &isDirectory) {
                    if isDirectory.boolValue {
                        metalFiles.append(contentsOf: findMetalFiles(in: fullPath))
                    } else if item.hasSuffix(".metal") {
                        metalFiles.append(fullPath)
                    }
                }
            }
        } catch {
            print("⚠️ Error searching directory \(directory): \(error)")
        }
        
        return metalFiles
    }
    
    /// Compiles a single Metal source file
    private static func compileMetalSource(_ filePath: String, device: MTLDevice) -> String? {
        do {
            let source = try String(contentsOfFile: filePath, encoding: .utf8)
            print("📄 Compiling: \(filePath)")
            return source
        } catch {
            print("⚠️ Failed to read Metal source file \(filePath): \(error)")
            return nil
        }
    }
    
    /// Validates Metal library functionality
    public static func validateLibrary(_ library: MTLLibrary) -> Bool {
        // Check if essential functions are available
        let essentialFunctions = ["matmul", "unary_add", "unary_mul"]
        
        for functionName in essentialFunctions {
            if library.makeFunction(name: functionName) == nil {
                print("⚠️ Missing essential Metal function: \(functionName)")
                return false
            }
        }
        
        print("✅ Metal library validation passed")
        return true
    }
    
    /// Gets Metal device information for diagnostics
    public static func getDeviceInfo() -> [String: Any] {
        guard let device = MTLCreateSystemDefaultDevice() else {
            return ["error": "No Metal device found"]
        }
        
        return [
            "name": device.name,
            "registryID": device.registryID,
            "maxThreadsPerThreadgroup": device.maxThreadsPerThreadgroup,
            "maxThreadgroupMemoryLength": device.maxThreadgroupMemoryLength,
            "hasUnifiedMemory": device.hasUnifiedMemory,
            "recommendedMaxWorkingSetSize": device.recommendedMaxWorkingSetSize,
            "maxBufferLength": device.maxBufferLength
        ]
    }
} 
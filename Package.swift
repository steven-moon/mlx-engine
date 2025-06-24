// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MLXEngine",
    platforms: [
        .macOS(.v14), .iOS(.v17)
    ],
    products: [
        .library(name: "MLXEngine", targets: ["MLXEngine"])
    ],
    dependencies: [
        // Optional MLX dependencies - will gracefully fallback if not available
        .package(url: "https://github.com/ml-explore/mlx-swift", from: "0.25.4"),
        .package(url: "https://github.com/ml-explore/mlx-swift-examples", branch: "main"),
        // Hub library for optimized model downloads
        .package(url: "https://github.com/huggingface/swift-transformers", from: "0.1.0")
    ],
    targets: [
        .target(
            name: "MLXEngine",
            dependencies: [
                // Make MLX dependencies optional
                .product(name: "MLX", package: "mlx-swift", condition: .when(platforms: [.macOS, .iOS])),
                .product(name: "MLXLLM", package: "mlx-swift-examples", condition: .when(platforms: [.macOS, .iOS])),
                .product(name: "MLXLMCommon", package: "mlx-swift-examples", condition: .when(platforms: [.macOS, .iOS]))
            ],
            path: "Sources/MLXEngine",
            sources: [
                "ChatSession.swift", 
                "HuggingFaceAPI.swift", 
                "InferenceEngine.swift", 
                "MLXEngine.swift", 
                "ModelRegistry.swift", 
                "OptimizedDownloader.swift", 
                "SHA256Helper.swift",
                "MLXModelSearchUtility.swift",
                "FileManagerService.swift"
            ],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .executableTarget(
            name: "SimpleExample",
            dependencies: ["MLXEngine"],
            path: "Examples",
            sources: ["simple_example.swift"]
        ),
        .executableTarget(
            name: "InteractivePrompt",
            dependencies: ["MLXEngine"],
            path: "Examples",
            sources: ["interactive_prompt.swift"]
        ),
        .testTarget(
            name: "MLXEngineTests",
            dependencies: ["MLXEngine"]
        ),
        .testTarget(
            name: "SanityTests",
            dependencies: []
        )
    ]
) 
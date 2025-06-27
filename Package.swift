// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MLXEngine",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "MLXEngine", targets: ["MLXEngine"]),
        .executable(name: "mlxengine-debug-report", targets: ["mlxengine-debug-report"])
    ],
    dependencies: [
        .package(url: "https://github.com/ml-explore/mlx-swift", from: "0.10.0"),
        .package(url: "https://github.com/ml-explore/mlx-swift-examples", branch: "main"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.3"),
        .package(path: "SwiftUIKit")
    ],
    targets: [
        .target(
            name: "MLXEngine",
            dependencies: [
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXNN", package: "mlx-swift"),
                .product(name: "MLXLLM", package: "mlx-swift-examples"),
                .product(name: "MLXLMCommon", package: "mlx-swift-examples"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftUIKit", package: "SwiftUIKit")
            ],
            path: "Sources/MLXEngine",
            exclude: ["macOS"],
            resources: [
                .process("Resources/default.metallib")
            ]
        ),
        .executableTarget(
            name: "mlxengine-debug-report",
            dependencies: ["MLXEngine"],
            path: "Sources/mlxengine-debug-report"
        ),
        .testTarget(
            name: "MLXEngineTests",
            dependencies: ["MLXEngine"],
            path: "Tests/MLXEngineTests"
        )
    ]
)

// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MLXEngine",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .library(name: "MLXEngine", targets: ["MLXEngine"])
    ],
    dependencies: [
        .package(url: "https://github.com/ml-explore/mlx-swift.git", from: "0.2.0")
    ],
    targets: [
        .target(
            name: "MLXEngine",
            dependencies: [.product(name: "MLX", package: "mlx-swift")],
            path: "Sources/MLXEngine"
        ),
        .testTarget(
            name: "MLXEngineTests",
            dependencies: ["MLXEngine"],
            path: "Tests"
        )
    ]
)

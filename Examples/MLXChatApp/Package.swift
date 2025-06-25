// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MLXChatApp",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [
        .executable(name: "MLXChatApp", targets: ["MLXChatApp"])
    ],
    dependencies: [
        .package(path: "../..") // local MLXEngine
    ],
    targets: [
        .executableTarget(
            name: "MLXChatApp",
            dependencies: [.product(name: "MLXEngine", package: "MLXEngine")],
            path: "Sources"
        )
    ]
)

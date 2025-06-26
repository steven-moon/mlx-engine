// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MLXChatApp",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .visionOS(.v1),
        .tvOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .executable(name: "MLXChatApp", targets: ["MLXChatApp"])
    ],
    dependencies: [
        .package(name: "MLXEngine", path: "../../"),
    ],
    targets: [
        .executableTarget(
            name: "MLXChatApp",
            dependencies: [
                .product(name: "MLXEngine", package: "MLXEngine"),
                .product(name: "UIAI", package: "MLXEngine")
            ],
            path: "Sources/MLXChatApp"
        )
    ]
) 
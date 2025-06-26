// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "SwiftUIKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8)
    ],
    products: [
        .library(
            name: "SwiftUIKit",
            targets: ["SwiftUIKit"]
        )
    ],
    targets: [
        .target(
            name: "SwiftUIKit",
            path: "Sources/SwiftUIKit"
        ),
        .testTarget(
            name: "SwiftUIKitTests",
            dependencies: ["SwiftUIKit"],
            path: "Tests/SwiftUIKitTests"
        )
    ]
) 
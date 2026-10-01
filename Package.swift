// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftNetworkingKit",
    platforms: [.iOS(.v16), .macOS(.v14)],
    products: [
        .library(
            name: "SwiftNetworkingKit",
            targets: ["SwiftNetworkingKit"]
        ),
    ],
    targets: [
        .target(
            name: "SwiftNetworkingKit",
            path: "Sources/Networking",
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ]
        ),
        .testTarget(
            name: "SwiftNetworkingKitTests",
            dependencies: ["SwiftNetworkingKit"],
            path: "Tests/NetworkingTests",
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ]
        ),
    ]
)

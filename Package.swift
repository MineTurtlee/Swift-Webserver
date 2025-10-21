// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Swift-Webserver",
    platforms: [
       .macOS(.v13),
       .iOS(.v13)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.115.0"),
        // 🔵 Non-blocking, event-driven networking for Swift. Used for custom executors
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
    ],
    targets: [
        .executableTarget(
            name: "Swift-Webserver",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
            ],
            resources: [
                .process("Public")
            ],
            // swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "Swift-WebserverTests",
            dependencies: [
                .target(name: "Swift-Webserver"),
                .product(name: "VaporTesting", package: "vapor"),
            ],
            // swiftSettings: swiftSettings
        )
    ]
)

/* var swiftSettings: [SwiftSetting] { [
    .enableUpcomingFeature("ExistentialAny"),
] } */

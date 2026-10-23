// swift-tools-version: 5.9
import PackageDescription

var products: [Product] = [
    .library(name: "ATLASCore", targets: ["ATLASCore"]),
    .executable(name: "atlas", targets: ["ATLASCLI"]),
]

var targets: [Target] = [
    .target(
        name: "ATLASCore",
        path: "Sources/Core"
    ),
    .executableTarget(
        name: "ATLASCLI",
        dependencies: ["ATLASCore"],
        path: "Sources/ATLASCLI"
    ),
    .testTarget(
        name: "ATLASCoreTests",
        dependencies: ["ATLASCore"],
        path: "Tests/CoreTests"
    ),
]

#if os(macOS)
products.append(.executable(name: "ATLASApp", targets: ["ATLASApp"]))
targets.append(
    .executableTarget(
        name: "ATLASApp",
        dependencies: ["ATLASCore"],
        path: "Sources/ATLASApp"
    )
)
#endif

let package = Package(
    name: "ATLAS",
    platforms: [
        .macOS(.v13)
    ],
    products: products,
    targets: targets
)

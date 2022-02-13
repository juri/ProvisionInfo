// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ProvisionInfo",
    platforms: [.macOS(.v12)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "ProvisionInfoKit",
            targets: ["ProvisionInfoKit"]
        ),
        .executable(
            name: "ProvisionInfo",
            targets: ["ProvisionInfo"]
        ),
    ],
    dependencies: [
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "ProvisionInfo",
            dependencies: [
                "ProvisionInfoKit",
            ]
        ),
        .target(
            name: "ProvisionInfoKit",
            dependencies: [
            ]
        ),
        .testTarget(
            name: "ProvisionInfoKitTests",
            dependencies: ["ProvisionInfoKit"]
        ),
    ]
)

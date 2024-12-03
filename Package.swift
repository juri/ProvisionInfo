// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ProvisionInfo",
    platforms: [.macOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "ProvisionInfoKit",
            targets: ["ProvisionInfoKit"]
        ),
        .executable(
            name: "provision-info",
            targets: ["ProvisionInfo"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .executableTarget(
            name: "ProvisionInfo",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
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
            dependencies: ["ProvisionInfoKit"],
            resources: [
                .copy("Resources/TestProfile.mobileprovision"),
            ]
        ),
    ]
)

// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TetraSwift",

    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .executable(name: "tetra", targets: ["tetra"]),
        .library(name: "TetraSwift", type: .static, targets: ["TetraSwift"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "TetraSwift",
            dependencies: [],
            path: "Sources"
        ),
        .target(
            name: "tetra",
            dependencies: [ "TetraSwift" ],
            path: "Application"
        )
    ],
    swiftLanguageVersions: [.v5]
)

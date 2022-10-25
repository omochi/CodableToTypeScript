// swift-tools-version:5.6

import PackageDescription

let package = Package(
    name: "CodableToTypeScript",
    products: [
        .library(
            name: "CodableToTypeScript",
            targets: ["CodableToTypeScript"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/omochi/SwiftTypeReader", .upToNextMinor(from: "1.1.0")),
    ],
    targets: [
        .target(
            name: "TestUtils"
        ),
        .target(
            name: "TSCodeModule"
        ),
        .testTarget(
            name: "TSCodeTests",
            dependencies: [
                .target(name: "TSCodeModule")
            ]
        ),
        .target(
            name: "CodableToTypeScript",
            dependencies: [
                .target(name: "TestUtils"),
                .target(name: "TSCodeModule"),
                .product(name: "SwiftTypeReader", package: "SwiftTypeReader")
            ]
        ),
        .testTarget(
            name: "CodableToTypeScriptTests",
            dependencies: ["CodableToTypeScript"]
        ),
    ]
)

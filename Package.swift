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
        .package(url: "https://github.com/omochi/SwiftTypeReader", branch: "main"),
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
            dependencies: ["TSCodeModule"]
        ),
        .target(
            name: "CodableToTypeScript",
            dependencies: [
                "TestUtils",
                "TSCodeModule",
                .product(name: "SwiftTypeReader", package: "SwiftTypeReader")
            ]
        ),
        .testTarget(
            name: "CodableToTypeScriptTests",
            dependencies: ["CodableToTypeScript"]
        ),
    ]
)

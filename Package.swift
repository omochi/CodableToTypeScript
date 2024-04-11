// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "CodableToTypeScript",
    platforms: [.macOS(.v13)],
    products: [
        .library(
            name: "CodableToTypeScript",
            targets: ["CodableToTypeScript"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/omochi/SwiftTypeReader", from: "2.10.0"),
//        .package(path: "../SwiftTypeReader"),
        .package(url: "https://github.com/omochi/TypeScriptAST", from: "1.8.6"),
    ],
    targets: [
        .target(
            name: "TestUtils"
        ),
        .target(
            name: "CodableToTypeScript",
            dependencies: [
                .product(name: "SwiftTypeReader", package: "SwiftTypeReader"),
                .product(name: "TypeScriptAST", package: "TypeScriptAST")
            ],
            swiftSettings: [
                .enableUpcomingFeature("BareSlashRegexLiterals"),
            ]
        ),
        .testTarget(
            name: "CodableToTypeScriptTests",
            dependencies: [
                .target(name: "TestUtils"),
                .target(name: "CodableToTypeScript")
            ]
        ),
    ]
)

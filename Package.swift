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
        .package(url: "https://github.com/omochi/SwiftTypeReader.git", branch: "swift-syntax-601"),
//        .package(path: "../SwiftTypeReader"),
        .package(url: "https://github.com/omochi/TypeScriptAST.git", branch: "path-alias"),
//        .package(path: "../TypeScriptAST"),
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
            swiftSettings: swiftSettings()
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

func swiftSettings() -> [SwiftSetting] {
    return [
        .enableUpcomingFeature("BareSlashRegexLiterals"),
        .enableExperimentalFeature("StrictConcurrency")
    ]
}

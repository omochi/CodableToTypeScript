// swift-tools-version: 5.8

import PackageDescription

let isLocalDevelopment = false

let dependencies: [Package.Dependency] = if isLocalDevelopment {
    [
        .package(path: "../SwiftTypeReader"),
        .package(path: "../TypeScriptAST"),
    ]
} else {
    [
        .package(url: "https://github.com/omochi/SwiftTypeReader.git", from: "3.2.0"),
        .package(url: "https://github.com/omochi/TypeScriptAST.git", from: "2.1.0"),
    ]
}

let package = Package(
    name: "CodableToTypeScript",
    platforms: [.macOS(.v13)],
    products: [
        .library(
            name: "CodableToTypeScript",
            targets: ["CodableToTypeScript"]
        )
    ],
    dependencies: dependencies,
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

// swift-tools-version: 6.0

import PackageDescription

let isLocalDevelopment = false

let dependencies: [Package.Dependency] = if isLocalDevelopment {
    [
        .package(path: "../SwiftTypeReader"),
        .package(path: "../TypeScriptAST"),
    ]
} else {
    [
        .package(url: "https://github.com/omochi/SwiftTypeReader.git", from: "3.4.0"),
        .package(url: "https://github.com/omochi/TypeScriptAST.git", from: "2.2.0"),
    ]
}

let package = Package(
    name: "CodableToTypeScript",
    platforms: [.macOS(.v15)],
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

// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "demo",
    platforms: [.macOS(.v12)],
    products: [
        .executable(name: "C2TS", targets: ["C2TS"]),
    ],
    dependencies: [
        .package(path: ".."),
        .package(url: "https://github.com/sidepelican/WasmCallableKit.git", from: "0.3.2"),
    ],
    targets: [
        .executableTarget(
            name: "C2TS",
            dependencies: [
                "CodableToTypeScript",
                "WasmCallableKit",
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-Xclang-linker", "-mexec-model=reactor",
                    "-Xlinker", "--export=main",
                ])
            ]
        ),
        .plugin(
            name: "CodegenPlugin",
            capability: .command(
                intent: .custom(verb: "codegen", description: "Generate codes"),
                permissions: [.writeToPackageDirectory(reason: "Place generated code")]
            ),
            dependencies: [
                .product(name: "codegen", package: "WasmCallableKit"),
            ]
        ),
    ]
)

// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MimeFoundation",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v13),
        .watchOS(.v6),
        .macCatalyst(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "MimeFoundation",
            targets: ["MimeFoundation"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
        .package(url: "https://github.com/ordo-one/package-benchmark", from: "1.22.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "MimeFoundation",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto"),
                .product(name: "_CryptoExtras", package: "swift-crypto")
            ]
        ),
        .testTarget(
            name: "MimeFoundationTests",
            dependencies: ["MimeFoundation"],
            resources: [
                .copy("TestData")
            ]
        ),
        .executableTarget(
            name: "MimeBenchmarks",
            dependencies: [
                "MimeFoundation",
                .product(name: "Benchmark", package: "package-benchmark")
            ],
            path: "Benchmarks/MimeBenchmarks",
            plugins: [
                .plugin(name: "BenchmarkPlugin", package: "package-benchmark")
            ]
        ),
    ]
)

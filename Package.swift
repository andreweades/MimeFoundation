// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import Foundation

let isModernMacOS: Bool = {
    #if os(macOS)
    if #available(macOS 13, *) {
        return true
    }
    #endif
    return false
}()

// Check if we are running on a modern OS (macOS 13+ or newer) AND the user has explicitly enabled benchmarks.
// This guards consumers of the library from inheriting the higher platform requirements (macOS 13)
// just because they happen to be developing on a modern Mac.
let includeBenchmarks = isModernMacOS && (ProcessInfo.processInfo.environment["MIME_BENCHMARKS"] == "1")

var dependencies: [Package.Dependency] = [
    .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0"),
    .package(url: "https://github.com/apple/swift-certificates.git", from: "1.0.0"),
]

var targets: [Target] = [
    .target(
        name: "MimeFoundation",
        dependencies: [
            .product(name: "Crypto", package: "swift-crypto"),
            .product(name: "_CryptoExtras", package: "swift-crypto"),
            .product(name: "X509", package: "swift-certificates")
        ]
    ),
    .testTarget(
        name: "MimeFoundationTests",
        dependencies: ["MimeFoundation"],
        resources: [
            .copy("TestData")
        ]
    ),
]

// Default supported platforms (Baseline)
var platforms: [SupportedPlatform] = [
    .macOS(.v10_15),
    .iOS(.v13),
    .tvOS(.v13),
    .watchOS(.v6),
    .macCatalyst(.v13)
]

if includeBenchmarks {
    // Raise platform requirements to match package-benchmark
    platforms = [
        .macOS(.v13),
        .iOS(.v16),
        .tvOS(.v13),
        .watchOS(.v6),
        .macCatalyst(.v13)
    ]
    
    dependencies.append(
        .package(url: "https://github.com/ordo-one/package-benchmark", from: "1.22.0")
    )
    targets.append(
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
        )
    )
}

let package = Package(
    name: "MimeFoundation",
    platforms: platforms,
    products: [
        .library(
            name: "MimeFoundation",
            targets: ["MimeFoundation"]
        ),
    ],
    dependencies: dependencies,
    targets: targets
)
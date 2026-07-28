// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "AIAnalyzer",
    platforms: [
        .macOS(.v13),
        .iOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "508.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0")
    ],
    targets: [
        .executableTarget(
            name: "AIAnalyzer",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "AIAnalyzerTests",
            dependencies: ["AIAnalyzer"]
        )
    ]
)

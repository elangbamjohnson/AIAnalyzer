// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "AIAnalyzer",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "508.0.0")
    ],
    targets: [
        .executableTarget(
            name: "AIAnalyzer",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax")
            ]
        ),
        .testTarget(
            name: "AIAnalyzerTests",
            dependencies: ["AIAnalyzer"]
        )
    ]
)

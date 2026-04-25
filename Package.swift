// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.


// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AIAnalyzer",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0")
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


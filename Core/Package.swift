// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "BronzeCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "BronzeCore", targets: ["BronzeCore"])
    ],
    targets: [
        .target(name: "BronzeCore"),
        .testTarget(name: "BronzeCoreTests", dependencies: ["BronzeCore"])
    ]
)

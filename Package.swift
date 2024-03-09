// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "SteamPress",
    platforms: [
       .macOS(.v12)
    ],
    products: [
        .library(name: "SteamPress", targets: ["SteamPress"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0-rc"),
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.0.0"),
        .package(url: "https://github.com/vapor/leaf-kit.git", from: "1.0.0-rc.1"),
        .package(url: "https://github.com/vapor-community/markdown.git", from: "0.6.1"),
    ],
    targets: [
        .target(name: "SteamPress", dependencies: [
            .product(name: "Vapor", package: "vapor"),
            .product(name: "LeafKit", package: "leaf-kit"),
            "SwiftSoup",
            .product(name: "SwiftMarkdown", package: "markdown")
        ]),
        .testTarget(name: "SteamPressTests", dependencies: ["SteamPress"]),
    ]
)

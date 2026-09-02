// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "BzKeeb",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "BzKeeb", targets: ["BzKeeb"]),
    ],
    targets: [
        .executableTarget(name: "BzKeeb"),
    ],
    swiftLanguageModes: [.v5]
)

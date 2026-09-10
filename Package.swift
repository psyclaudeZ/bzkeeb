// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "bzkeeb",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "bzkeeb", targets: ["bzkeeb"]),
    ],
    targets: [
        .executableTarget(name: "bzkeeb"),
    ],
    swiftLanguageModes: [.v5]
)

// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

import PackageDescription

let package = Package(
    name: "SwangoTest",
    platforms: [
        .macOS(.v10_15)
    ],
    dependencies: [
        // Use local path during development
        .package(path: "/Users/sojo/Documents/SwangoSPM/Swango")
    ],
    targets: [
        .executableTarget(
            name: "SwangoTest",
            dependencies: ["Swango"]),
    ]
)

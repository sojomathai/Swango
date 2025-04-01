
// The swift-tools-version declares the minimum version of Swift required to build this package.

/*  Created by sojo
 
## License

This project is available under a dual license:

- **GNU Affero General Public License v3.0 (AGPL-3.0)** for open source projects
- **Commercial License** for enterprise and commercial use

If you are using this software in a commercial or enterprise context, please contact us at info@techarm.ca to obtain a commercial license.
*/

// swift-tools-version:5.5
// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Swango",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "Swango",
            targets: ["Swango"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.14.0"),
    ],
    targets: [
        .target(
            name: "Swango",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOHTTP1", package: "swift-nio"),
                .product(name: "SQLite", package: "SQLite.swift"),
            ]),
        .testTarget(
            name: "SwangoTests",
            dependencies: ["Swango"]),
    ]
)

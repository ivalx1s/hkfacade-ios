// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "hkfacade-ios",
    platforms: [
        .iOS(.v14),
        .watchOS(.v7),
    ],
    products: [
        .library(
            name: "HKFacade",
            type: .dynamic,
            targets: ["HKFacade"]),
    ],
    dependencies: [

    ],
    targets: [
        .target(
            name: "HKFacade",
            dependencies: [],
            path: "Sources"
        )
    ]
)


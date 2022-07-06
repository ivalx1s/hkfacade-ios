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
    dependencies: Package.remoteDependencies,
    targets: [
        .target(
            name: "HKFacade",
            dependencies: Package.facadeDependencies,
            path: "Sources"
        )
    ]
)

// MARK: -- Dependencies
extension Package {
    static var remoteDependencies: [Package.Dependency] {
        [
            .package(url: "https://github.com/apple/swift-algorithms.git", from: "1.0.0"),
        ]
    }

    static var facadeDependencies: [Target.Dependency] {
        [
            .product(name: "Algorithms", package: "swift-algorithms"),
        ]
    }
}

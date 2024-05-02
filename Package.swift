// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "DocereeAdsSdk",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "DocereeAdsSdk",
            targets: ["DocereeAdsSdk"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ketch-com/ketch-ios.git", exact: "4.0.0"),
        
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "DocereeAdsSdk",
            dependencies: [
                .product(name: "KetchSDK", package: "ketch-ios")
            ]),
        .testTarget(
            name: "DocereeAdsSdk",
            dependencies: ["DocereeAdsSdk"]),
    ]
)

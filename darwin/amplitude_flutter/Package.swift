// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to
// build this package.

import PackageDescription

let package = Package(
    name: "amplitude_flutter",
    platforms: [
        .iOS("13.0"),
        .macOS("10.15"),
    ],
    products: [
        .library(
            name: "amplitude-flutter",
            targets: ["amplitude_flutter"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/amplitude/Amplitude-Swift.git",
            from: "1.17.5"
        ),
    ],
    targets: [
        .target(
            name: "amplitude_flutter",
            dependencies: [
                .product(
                    name: "AmplitudeSwift",
                    package: "Amplitude-Swift"
                ),
            ]
        )
    ]
)

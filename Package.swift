// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ImageSlideshow",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        // Temporarily commented out due to SPM/XCTest compatibility issues
        // .package(url: "https://github.com/typelift/SwiftCheck.git", from: "0.12.0")
    ],
    targets: [
        .target(
            name: "ImageSlideshowLib",
            path: "Sources/ImageSlideshow"
        ),
        .executableTarget(
            name: "ImageSlideshow",
            dependencies: ["ImageSlideshowLib"],
            path: "Sources/ImageSlideshowApp"
        ),
        .testTarget(
            name: "ImageSlideshowTests",
            dependencies: [
                "ImageSlideshowLib"
                // Temporarily removed SwiftCheck due to SPM compatibility issues
                // .product(name: "SwiftCheck", package: "SwiftCheck")
            ],
            path: "Tests/ImageSlideshowTests",
            exclude: [
                "UnitTests/README.md",
                "PropertyTests/README.md"
            ]
        )
    ]
)

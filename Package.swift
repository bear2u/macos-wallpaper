// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacLiveWallpaper",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "MacLiveWallpaper",
            targets: ["MacLiveWallpaper"]
        )
    ],
    targets: [
        .executableTarget(
            name: "MacLiveWallpaper",
            path: "MacLiveWallpaper",
            exclude: [
                "Resources/Info.plist"
            ],
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .define("SWIFT_PACKAGE")
            ]
        )
    ]
)

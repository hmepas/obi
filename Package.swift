// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "obi",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "obi",
            path: "Sources/obi",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("CoreAudio"),
                .linkedFramework("CoreWLAN"),
                .linkedFramework("Carbon"),
                .linkedFramework("Network"),
                .linkedFramework("SystemConfiguration"),
            ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)

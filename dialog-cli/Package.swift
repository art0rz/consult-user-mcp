// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DialogCLI",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "DialogCLI",
            path: "Sources/DialogCLI"
        )
    ]
)

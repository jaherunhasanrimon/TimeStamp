// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "TimeStamp",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "TimeStamp", targets: ["TimeStamp"])
    ],
    targets: [
        .executableTarget(
            name: "TimeStamp",
            path: "Sources"
        ),
        .testTarget(
            name: "TimeStampTests",
            dependencies: ["TimeStamp"],
            path: "Tests",
            swiftSettings: [
                .unsafeFlags(["-F", "/Library/Developer/CommandLineTools/Library/Developer/Frameworks"])
            ],
            linkerSettings: [
                .unsafeFlags([
                    "-F", "/Library/Developer/CommandLineTools/Library/Developer/Frameworks",
                    "-Xlinker", "-rpath", "-Xlinker", "/Library/Developer/CommandLineTools/Library/Developer/Frameworks",
                    "-Xlinker", "-rpath", "-Xlinker", "/Library/Developer/CommandLineTools/Library/Developer/usr/lib"
                ])
            ]
        )
    ]
)

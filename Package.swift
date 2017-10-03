import PackageDescription

let package = Package(
    name: "TiltProvider",
    targets: [
        Target(name: "TiltProvider"),
    ],
    dependencies: [
        .Package(url: "https://github.com/vapor/vapor.git", majorVersion: 2),
    ],
    exclude: [
    ]
)

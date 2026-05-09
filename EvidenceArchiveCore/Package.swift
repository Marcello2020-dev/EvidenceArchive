// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "EvidenceArchiveCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "EvidenceArchiveCore", targets: ["EvidenceArchiveCore"])
    ],
    targets: [
        .target(name: "EvidenceArchiveCore"),
        .testTarget(name: "EvidenceArchiveCoreTests", dependencies: ["EvidenceArchiveCore"])
    ]
)

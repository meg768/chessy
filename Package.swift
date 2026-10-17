// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ChessRules",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "ChessRules", path: "Chessy",
                exclude: ["ChessyApp.swift", "ChessboardView.swift", "Assets.xcassets", "PieceArtwork-LICENSE.txt"],
                sources: ["ChessGame.swift", "GameStore.swift"]),
        .testTarget(name: "ChessRulesTests", dependencies: ["ChessRules"])
    ]
)

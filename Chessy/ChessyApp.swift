import SwiftUI

@main
struct ChessyApp: App {
    var body: some Scene {
        Window("Chessy", id: "board") {
            ChessboardView()
        }
        .defaultSize(width: 800, height: 860)
        .windowResizability(.contentMinSize)
    }
}

import SwiftUI

@main
struct ChessyApp: App {
    var body: some Scene {
        Window("Chessy", id: "board") {
            ChessboardView()
        }
        .defaultSize(width: 560, height: 600)
        .windowResizability(.contentMinSize)
    }
}

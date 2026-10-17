import SwiftUI

@main
struct ChessyApp: App {
    @State private var newGameRequested = false

    var body: some Scene {
        Window("Chessy", id: "board") {
            ChessboardView(newGameRequested: $newGameRequested)
        }
        .defaultSize(width: 800, height: 860)
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Game") { newGameRequested = true }
                    .keyboardShortcut("n")
            }
        }
    }
}

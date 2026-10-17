import Foundation

struct GameStore {
    let url: URL

    init(url: URL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Chessy/game.json")) {
        self.url = url
    }

    private struct SavedGame: Codable {
        let version: Int
        let game: ChessGame
    }

    func load() throws -> ChessGame? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let saved = try JSONDecoder().decode(SavedGame.self, from: Data(contentsOf: url))
        guard saved.version == 1 else { throw CocoaError(.coderReadCorrupt) }
        return saved.game
    }

    func save(_ game: ChessGame) throws {
        let data = try JSONEncoder().encode(SavedGame(version: 1, game: game))
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url, options: .atomic)
    }
}

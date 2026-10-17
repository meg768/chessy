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

extension ChessGame {
    // A save failure is reported to the caller without rolling back a legal move.
    // The next successful save writes the entire current position.
    @discardableResult
    mutating func move(_ move: ChessMove, savingWith save: (ChessGame) throws -> Void) throws -> Bool {
        guard self.move(move) else { return false }
        try save(self)
        return true
    }
}

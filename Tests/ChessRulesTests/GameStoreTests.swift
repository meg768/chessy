import Foundation
import XCTest
@testable import ChessRules

final class GameStoreTests: XCTestCase {
    private var folder: URL!
    private var store: GameStore!

    override func setUpWithError() throws {
        folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        store = GameStore(url: folder.appendingPathComponent("Chessy/game.json"))
    }

    override func tearDownWithError() throws {
        if FileManager.default.fileExists(atPath: folder.path) { try FileManager.default.removeItem(at: folder) }
    }

    private func play(_ game: inout ChessGame, _ from: Int, _ to: Int) {
        XCTAssertTrue(game.move(ChessMove(from: from, to: to)))
    }

    func testMissingSaveAndFirstSaveCreatesDirectory() throws {
        XCTAssertNil(try store.load())
        let game = ChessGame()
        try store.save(game)
        let restored = try XCTUnwrap(store.load())
        XCTAssertEqual(restored.board, game.board)
        XCTAssertEqual(restored.turn, .white)
        XCTAssertEqual(restored.castlingRights, game.castlingRights)
    }

    func testCompletedMovesOverwriteOneSnapshotAndPreserveEnPassant() throws {
        var game = ChessGame()
        for (from, to) in [(52, 36), (8, 16), (36, 28), (11, 27)] {
            play(&game, from, to)
            try store.save(game)
        }
        // A fresh store simulates another process loading the last committed move.
        var restored = try XCTUnwrap(GameStore(url: store.url).load())
        XCTAssertEqual(restored.board, game.board)
        XCTAssertEqual(restored.turn, .white)
        XCTAssertEqual(restored.enPassant, 19) // d6, after ...d7-d5
        XCTAssertEqual(restored.legalMoves(), game.legalMoves())
        play(&restored, 28, 19)
        XCTAssertNil(restored.board[27])
    }

    func testLostCastlingRightsSurviveRestoration() throws {
        var game = ChessGame()
        play(&game, 55, 47); play(&game, 8, 16) // h3, a6
        play(&game, 63, 55); play(&game, 16, 24) // Rh2, a5
        play(&game, 55, 63) // Rh1, right remains lost
        try store.save(game)
        let restored = try XCTUnwrap(store.load())
        XCTAssertEqual(restored.turn, .black)
        XCTAssertFalse(restored.castlingRights.contains(.whiteKing))
        XCTAssertEqual(restored.castlingRights, game.castlingRights)
    }

    func testPromotionAndCompletedGameSurviveRestoration() throws {
        var board: [ChessPiece?] = Array(repeating: nil, count: 64)
        board[56] = ChessPiece(side: .white, kind: .king)
        board[7] = ChessPiece(side: .black, kind: .king)
        board[9] = ChessPiece(side: .white, kind: .pawn)
        var promotion = ChessGame(board: board)
        XCTAssertTrue(promotion.move(ChessMove(from: 9, to: 1, promotion: .knight)))
        try store.save(promotion)
        XCTAssertEqual(try store.load()?.board[1], ChessPiece(side: .white, kind: .knight))
        var mate = ChessGame()
        for (from, to) in [(53, 45), (12, 28), (54, 38), (3, 39)] { play(&mate, from, to) }
        try store.save(mate)
        XCTAssertEqual(try store.load()?.status, .checkmate)
    }

    func testNewGameReplacesSavedGame() throws {
        var game = ChessGame()
        play(&game, 52, 36)
        try store.save(game)
        try store.save(ChessGame())
        let restored = try XCTUnwrap(store.load())
        XCTAssertEqual(restored.board, ChessGame().board)
        XCTAssertEqual(restored.turn, .white)
        XCTAssertNil(restored.enPassant)
        XCTAssertEqual(restored.castlingRights, Set(CastleRight.allCases))
    }

    func testCorruptDataThrowsWithoutDeletingOriginal() throws {
        try store.save(ChessGame())
        let bytes = Data("not JSON".utf8)
        try bytes.write(to: store.url)
        XCTAssertThrowsError(try store.load())
        XCTAssertEqual(try Data(contentsOf: store.url), bytes)
    }

    func testUnsupportedVersionAndMalformedPositionsAreRejected() throws {
        try store.save(ChessGame())
        let original = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: store.url)) as? [String: Any])
        var unsupported = original
        unsupported["version"] = 2
        try JSONSerialization.data(withJSONObject: unsupported).write(to: store.url)
        XCTAssertThrowsError(try store.load())
        for change in ["shortBoard", "missingKing", "badTarget", "overflowTarget", "unknownPiece"] {
            var data = original
            var game = try XCTUnwrap(data["game"] as? [String: Any])
            var board = try XCTUnwrap(game["board"] as? [Any])
            switch change {
            case "shortBoard": board.removeLast()
            case "missingKing": board[4] = NSNull()
            case "badTarget": game["enPassant"] = 1000
            case "overflowTarget": game["enPassant"] = Int.max
            default: board[0] = ["side": "black", "kind": "dragon"]
            }
            game["board"] = board
            data["game"] = game
            try JSONSerialization.data(withJSONObject: data).write(to: store.url)
            XCTAssertThrowsError(try store.load(), change)
        }
    }

    func testWriteFailureIsReportedAndExistingSaveIsUnchanged() throws {
        try store.save(ChessGame())
        let original = try Data(contentsOf: store.url)
        let impossible = GameStore(url: store.url.appendingPathComponent("cannot-create-child-of-file.json"))
        XCTAssertThrowsError(try impossible.save(ChessGame()))
        XCTAssertEqual(try Data(contentsOf: store.url), original)
    }

    func testMoveSaveFailureKeepsMoveAndLaterSaveCatchesUp() throws {
        var game = ChessGame()
        try store.save(game)
        let previousBytes = try Data(contentsOf: store.url)
        var saveAttempts = 0
        let unavailableDisk: (ChessGame) throws -> Void = { position in
            saveAttempts += 1
            XCTAssertEqual(position.turn, .black)
            XCTAssertEqual(position.board[36], ChessPiece(side: .white, kind: .pawn))
            throw CocoaError(.fileWriteNoPermission)
        }

        // Use the same coordination entry point as ChessboardView.finish(_:).
        XCTAssertThrowsError(try game.move(ChessMove(from: 52, to: 36), savingWith: unavailableDisk))
        XCTAssertEqual(saveAttempts, 1)
        XCTAssertNil(game.board[52])
        XCTAssertEqual(game.board[36], ChessPiece(side: .white, kind: .pawn))
        XCTAssertEqual(game.turn, .black)
        XCTAssertEqual(try Data(contentsOf: store.url), previousBytes)
        XCTAssertEqual(try store.load()?.board, ChessGame().board)

        // A later legal move saves both moves, rather than just the last delta.
        XCTAssertTrue(try game.move(ChessMove(from: 12, to: 28), savingWith: store.save))
        let restored = try XCTUnwrap(store.load())
        XCTAssertEqual(restored.board, game.board)
        XCTAssertEqual(restored.turn, .white)
        XCTAssertEqual(restored.enPassant, game.enPassant)
        XCTAssertEqual(restored.castlingRights, game.castlingRights)
        XCTAssertEqual(restored.legalMoves(), game.legalMoves())
        XCTAssertEqual(restored.board[36], ChessPiece(side: .white, kind: .pawn))
        XCTAssertEqual(restored.board[28], ChessPiece(side: .black, kind: .pawn))
    }

    func testIllegalMoveDoesNotAttemptSaving() throws {
        var game = ChessGame()
        try store.save(game)
        let previousBytes = try Data(contentsOf: store.url)
        XCTAssertFalse(try game.move(ChessMove(from: 52, to: 28), savingWith: { _ in
            XCTFail("An illegal move must not attempt a save")
        }))
        XCTAssertEqual(game.board, ChessGame().board)
        XCTAssertEqual(game.turn, .white)
        XCTAssertEqual(try Data(contentsOf: store.url), previousBytes)
    }

}

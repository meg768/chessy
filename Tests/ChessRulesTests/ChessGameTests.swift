import XCTest
@testable import ChessRules

final class ChessGameTests: XCTestCase {
    private func square(_ name: String) -> Int {
        let chars = Array(name)
        return (8 - Int(String(chars[1]))!) * 8 + Int(chars[0].asciiValue! - Character("a").asciiValue!)
    }

    private func position(_ pieces: [(String, ChessSide, PieceKind)], turn: ChessSide = .white,
                          rights: Set<CastleRight> = [], ep: String? = nil) -> ChessGame {
        var board: [ChessPiece?] = Array(repeating: nil, count: 64)
        for (name, side, kind) in pieces { board[square(name)] = ChessPiece(side: side, kind: kind) }
        return ChessGame(board: board, turn: turn, castlingRights: rights, enPassant: ep.map(square))
    }

    private func play(_ game: inout ChessGame, _ from: String, _ to: String,
                      promotion: PieceKind? = nil, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(game.move(ChessMove(from: square(from), to: square(to), promotion: promotion)), file: file, line: line)
    }

    private func allows(_ game: ChessGame, _ from: String, _ to: String) -> Bool {
        game.legalMoves(from: square(from)).contains { $0.to == square(to) }
    }

    func testInitialPositionTurnsAndIllegalMoveAreAtomic() {
        var game = ChessGame()
        XCTAssertEqual(game.board.compactMap { $0 }.count, 32)
        XCTAssertEqual(game.legalMoves().count, 20)
        let before = game.board
        XCTAssertFalse(game.move(ChessMove(from: square("e7"), to: square("e5"))))
        XCTAssertFalse(game.move(ChessMove(from: square("e2"), to: square("e5"))))
        XCTAssertFalse(game.move(ChessMove(from: -1, to: 64)))
        XCTAssertEqual(game.board, before)
        XCTAssertEqual(game.turn, .white)
        play(&game, "e2", "e4")
        XCTAssertEqual(game.turn, .black)
        XCTAssertFalse(allows(game, "d2", "d4"))
        play(&game, "e7", "e5")
    }

    func testPawnMovementBlockingAndCaptures() {
        var game = position([("a1", .white, .king), ("h8", .black, .king),
                             ("d2", .white, .pawn), ("e3", .black, .knight), ("c3", .white, .knight)])
        XCTAssertTrue(allows(game, "d2", "d4"))
        XCTAssertFalse(allows(game, "d2", "c3"))
        XCTAssertFalse(allows(game, "d2", "c2"))
        play(&game, "d2", "e3")
        XCTAssertEqual(game.board[square("e3")], ChessPiece(side: .white, kind: .pawn))
        let blocked = position([("a1", .white, .king), ("h8", .black, .king),
                                ("d2", .white, .pawn), ("d3", .black, .bishop)])
        XCTAssertFalse(allows(blocked, "d2", "d3"))
        XCTAssertFalse(allows(blocked, "d2", "d4"))
        XCTAssertFalse(allows(blocked, "d2", "e3"))
        let black = position([("a1", .white, .king), ("h8", .black, .king), ("e7", .black, .pawn)], turn: .black)
        XCTAssertTrue(allows(black, "e7", "e5"))
        XCTAssertFalse(allows(black, "e7", "e8"))
    }

    func testKnightJumpsButCannotCaptureOwnPiece() {
        let game = position([("a1", .white, .king), ("h8", .black, .king), ("d4", .white, .knight),
                             ("d5", .white, .pawn), ("f5", .black, .rook), ("f3", .white, .rook)])
        XCTAssertTrue(allows(game, "d4", "f5"))
        XCTAssertTrue(allows(game, "d4", "e6"))
        XCTAssertFalse(allows(game, "d4", "f3"))
        XCTAssertFalse(allows(game, "d4", "d6"))
    }

    func testSlidingPiecesAndBlockedPaths() {
        for kind in [PieceKind.bishop, .rook, .queen] {
            let game = position([("a1", .white, .king), ("h8", .black, .king), ("d4", .white, kind),
                                 ("d6", .black, .pawn), ("f6", .black, .pawn),
                                 ("b4", .white, .pawn), ("b2", .white, .pawn)])
            if kind != .bishop {
                XCTAssertTrue(allows(game, "d4", "d6"))
                XCTAssertFalse(allows(game, "d4", "d7"))
                XCTAssertFalse(allows(game, "d4", "b4"))
                XCTAssertFalse(allows(game, "d4", "a4"))
            } else { XCTAssertFalse(allows(game, "d4", "d5")) }
            if kind != .rook {
                XCTAssertTrue(allows(game, "d4", "f6"))
                XCTAssertFalse(allows(game, "d4", "g7"))
                XCTAssertFalse(allows(game, "d4", "b2"))
                XCTAssertFalse(allows(game, "d4", "a1"))
            } else { XCTAssertFalse(allows(game, "d4", "e5")) }
            XCTAssertFalse(allows(game, "d4", "e6"))
        }
    }

    func testKingSafetyPinsAndAdjacentKings() {
        let pinned = position([("e1", .white, .king), ("e2", .white, .rook),
                               ("e8", .black, .rook), ("a8", .black, .king)])
        XCTAssertFalse(allows(pinned, "e2", "d2"))
        XCTAssertTrue(allows(pinned, "e2", "e8"))
        let check = position([("e1", .white, .king), ("e8", .black, .rook), ("a8", .black, .king)])
        XCTAssertEqual(check.status, .check)
        XCTAssertFalse(allows(check, "e1", "e2"))
        XCTAssertTrue(allows(check, "e1", "d1"))
        let kings = position([("e1", .white, .king), ("e3", .black, .king)])
        XCTAssertFalse(allows(kings, "e1", "e2"))
        XCTAssertFalse(allows(kings, "e1", "e3"))
        let pawn = position([("e1", .white, .king), ("h8", .black, .king), ("d3", .black, .pawn)])
        XCTAssertFalse(allows(pawn, "e1", "e2"))
    }

    func testCastlingBothWingsAndColors() {
        for side in ChessSide.allCases {
            for kingSide in [true, false] {
                let rank = side == .white ? "1" : "8"
                var game = position([("e" + rank, side, .king), ("a" + rank, side, .rook),
                                     ("h" + rank, side, .rook), (side == .white ? "e8" : "e1", side.opponent, .king)],
                                    turn: side, rights: Set(CastleRight.allCases))
                play(&game, "e" + rank, (kingSide ? "g" : "c") + rank)
                XCTAssertEqual(game.board[square((kingSide ? "f" : "d") + rank)], ChessPiece(side: side, kind: .rook))
                XCTAssertNil(game.board[square((kingSide ? "h" : "a") + rank)])
            }
        }
    }

    func testCastlingRestrictionsAndLostRights() {
        let base: [(String, ChessSide, PieceKind)] = [("e1", .white, .king), ("h1", .white, .rook), ("a8", .black, .king)]
        XCTAssertFalse(allows(position(base), "e1", "g1"))
        for extra in [[("f1", ChessSide.white, PieceKind.bishop)], [("f8", .black, .rook)],
                      [("g8", .black, .rook)], [("e8", .black, .rook)], [("g2", .black, .pawn)]] {
            XCTAssertFalse(allows(position(base + extra, rights: [.whiteKing]), "e1", "g1"))
        }
        XCTAssertFalse(allows(position([("e1", .white, .king), ("a8", .black, .king)], rights: [.whiteKing]), "e1", "g1"))
        var rookMoved = position(base, rights: [.whiteKing])
        play(&rookMoved, "h1", "h2"); play(&rookMoved, "a8", "a7"); play(&rookMoved, "h2", "h1")
        XCTAssertFalse(rookMoved.castlingRights.contains(.whiteKing))
        var kingMoved = position(base, rights: [.whiteKing])
        play(&kingMoved, "e1", "e2"); play(&kingMoved, "a8", "a7"); play(&kingMoved, "e2", "e1")
        XCTAssertFalse(kingMoved.castlingRights.contains(.whiteKing))
        var captured = position(base + [("h8", .black, .rook)], turn: .black, rights: [.whiteKing])
        play(&captured, "h8", "h1")
        XCTAssertFalse(captured.castlingRights.contains(.whiteKing))
        let queenBlocked = position([("e1", .white, .king), ("a1", .white, .rook),
                                     ("b1", .white, .knight), ("h8", .black, .king)], rights: [.whiteQueen])
        XCTAssertFalse(allows(queenBlocked, "e1", "c1"))
    }

    func testEnPassantImmediateCaptureAndExpiry() {
        var game = position([("a1", .white, .king), ("h8", .black, .king),
                             ("e5", .white, .pawn), ("d7", .black, .pawn)], turn: .black)
        play(&game, "d7", "d5")
        var expired = game
        play(&expired, "a1", "a2"); play(&expired, "h8", "h7")
        XCTAssertFalse(allows(expired, "e5", "d6"))
        play(&game, "e5", "d6")
        XCTAssertNil(game.board[square("d5")])
        XCTAssertEqual(game.board[square("d6")], ChessPiece(side: .white, kind: .pawn))
        var black = position([("a1", .white, .king), ("h8", .black, .king),
                              ("d2", .white, .pawn), ("e4", .black, .pawn)])
        play(&black, "d2", "d4"); play(&black, "e4", "d3")
        XCTAssertNil(black.board[square("d4")])
    }

    func testEnPassantCannotExposeKing() {
        let game = position([("h5", .white, .king), ("g5", .white, .pawn), ("f5", .black, .pawn),
                             ("a5", .black, .rook), ("a8", .black, .king)], ep: "f6")
        XCTAssertFalse(allows(game, "g5", "f6"))
    }

    func testEveryPromotionAndPromotionCaptureForBothSides() {
        for side in ChessSide.allCases {
            for kind in PieceKind.promotions {
                let source = side == .white ? "b7" : "b2"
                let target = side == .white ? "b8" : "b1"
                var game = position([("h1", .white, .king), ("h8", .black, .king), (source, side, .pawn)], turn: side)
                XCTAssertFalse(game.move(ChessMove(from: square(source), to: square(target))))
                play(&game, source, target, promotion: kind)
                XCTAssertEqual(game.board[square(target)], ChessPiece(side: side, kind: kind))
            }
        }
        var capture = position([("h1", .white, .king), ("h8", .black, .king),
                                ("b7", .white, .pawn), ("a8", .black, .rook)])
        play(&capture, "b7", "a8", promotion: .knight)
        XCTAssertEqual(capture.board[square("a8")]?.kind, .knight)
    }

    func testCheckmateAndNoFurtherMoves() {
        var game = ChessGame()
        play(&game, "f2", "f3"); play(&game, "e7", "e5")
        play(&game, "g2", "g4"); play(&game, "d8", "h4")
        XCTAssertEqual(game.status, .checkmate)
        XCTAssertTrue(game.legalMoves().isEmpty)
        let board = game.board
        XCTAssertFalse(game.move(ChessMove(from: square("a2"), to: square("a3"))))
        XCTAssertEqual(board, game.board)
    }

    func testStalemateAndNoFurtherMoves() {
        var game = position([("h8", .black, .king), ("f7", .white, .king), ("g6", .white, .queen)], turn: .black)
        XCTAssertEqual(game.status, .stalemate)
        XCTAssertFalse(game.isInCheck(.black))
        XCTAssertFalse(game.move(ChessMove(from: square("h8"), to: square("h7"))))
    }

    func testOpeningMoveTreeThroughThreePlies() {
        func count(_ game: ChessGame, depth: Int) -> Int {
            if depth == 0 { return 1 }
            return game.legalMoves().reduce(0) { sum, move in
                var next = game
                XCTAssertTrue(next.move(move))
                return sum + count(next, depth: depth - 1)
            }
        }
        XCTAssertEqual(count(ChessGame(), depth: 2), 400)
        XCTAssertEqual(count(ChessGame(), depth: 3), 8902)
    }

    func testKingCannotCaptureProtectedPieceOrEnterPinnedAttack() {
        let defended = position([("e1", .white, .king), ("e2", .black, .rook),
                                  ("h5", .black, .bishop), ("a8", .black, .king)])
        XCTAssertFalse(allows(defended, "e1", "e2"))
        let pinnedAttack = position([("e4", .white, .king), ("g1", .white, .rook),
                                     ("g7", .black, .knight), ("g8", .black, .king)])
        XCTAssertFalse(allows(pinnedAttack, "e4", "f5"))
    }

    func testCastlingMayUseAnAttackedRookAndQueenSideOuterSquare() {
        let game = position([("e1", .white, .king), ("a1", .white, .rook), ("h1", .white, .rook),
                             ("a8", .black, .king), ("b8", .black, .rook), ("h8", .black, .rook)],
                            rights: [.whiteKing, .whiteQueen])
        XCTAssertTrue(allows(game, "e1", "g1"))
        XCTAssertTrue(allows(game, "e1", "c1"))
    }

    func testPromotionCannotBeUsedOnAnOrdinaryMove() {
        var game = ChessGame()
        XCTAssertFalse(game.move(ChessMove(from: square("e2"), to: square("e4"), promotion: .queen)))
        XCTAssertEqual(game.turn, .white)
    }

}

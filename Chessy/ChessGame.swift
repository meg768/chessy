// Board indices run from a8 (0) to h1 (63).
enum ChessSide: String, CaseIterable {
    case white, black
    var opponent: Self { self == .white ? .black : .white }
}

enum PieceKind: String, CaseIterable {
    case king, queen, rook, bishop, knight, pawn
    static let promotions: [Self] = [.queen, .rook, .bishop, .knight]
}

struct ChessPiece: Equatable {
    let side: ChessSide
    let kind: PieceKind
    var name: String { "\(side.rawValue) \(kind.rawValue)" }
    var imageName: String { "\(side.rawValue)-\(kind.rawValue)" }
}

struct ChessMove: Equatable {
    let from: Int
    let to: Int
    var promotion: PieceKind? = nil
}

enum CastleRight: CaseIterable {
    case whiteKing, whiteQueen, blackKing, blackQueen
}

enum GameStatus: Equatable {
    case playing, check, checkmate, stalemate
    var isFinished: Bool { self == .checkmate || self == .stalemate }
}

struct ChessGame {
    private(set) var board: [ChessPiece?]
    private(set) var turn: ChessSide
    private(set) var castlingRights: Set<CastleRight>
    private(set) var enPassant: Int?

    init() {
        board = Array(repeating: nil, count: 64)
        turn = .white
        castlingRights = Set(CastleRight.allCases)
        let rank: [PieceKind] = [.rook, .knight, .bishop, .queen, .king, .bishop, .knight, .rook]
        for file in 0..<8 {
            board[file] = ChessPiece(side: .black, kind: rank[file])
            board[file + 8] = ChessPiece(side: .black, kind: .pawn)
            board[file + 48] = ChessPiece(side: .white, kind: .pawn)
            board[file + 56] = ChessPiece(side: .white, kind: rank[file])
        }
    }

    // Internal position initializer for focused rules tests. Not a position editor.
    init(board: [ChessPiece?], turn: ChessSide = .white,
         castlingRights: Set<CastleRight> = [], enPassant: Int? = nil) {
        precondition(board.count == 64)
        self.board = board
        self.turn = turn
        self.castlingRights = castlingRights
        self.enPassant = enPassant
    }

    var status: GameStatus {
        let check = isInCheck(turn)
        if legalMoves().isEmpty { return check ? .checkmate : .stalemate }
        return check ? .check : .playing
    }

    func legalMoves() -> [ChessMove] {
        board.indices.flatMap { legalMoves(from: $0) }
    }

    func legalMoves(from source: Int) -> [ChessMove] {
        guard board.indices.contains(source), let piece = board[source], piece.side == turn else { return [] }
        return board.indices.flatMap { destination -> [ChessMove] in
            guard isPseudoLegal(from: source, to: destination, piece: piece) else { return [] }
            let promotions: [PieceKind?] = piece.kind == .pawn && [0, 7].contains(destination / 8)
                ? PieceKind.promotions.map(Optional.some) : [nil]
            return promotions.compactMap { promotion in
                let move = ChessMove(from: source, to: destination, promotion: promotion)
                var next = self
                next.apply(move)
                return next.isInCheck(piece.side) ? nil : move
            }
        }
    }

    @discardableResult
    mutating func move(_ move: ChessMove) -> Bool {
        guard legalMoves(from: move.from).contains(move) else { return false }
        apply(move)
        return true
    }

    func isInCheck(_ side: ChessSide) -> Bool {
        guard let king = board.firstIndex(of: ChessPiece(side: side, kind: .king)) else { return true }
        return isAttacked(king, by: side.opponent)
    }

    // Attacks are geometric: even pinned pieces protect squares against a king.
    private func isAttacked(_ target: Int, by side: ChessSide) -> Bool {
        for source in board.indices {
            guard let piece = board[source], piece.side == side else { continue }
            let dr = target / 8 - source / 8
            let dc = target % 8 - source % 8
            switch piece.kind {
            case .pawn:
                if dr == (side == .white ? -1 : 1) && abs(dc) == 1 { return true }
            case .knight:
                if (abs(dr) == 2 && abs(dc) == 1) || (abs(dr) == 1 && abs(dc) == 2) { return true }
            case .king:
                if max(abs(dr), abs(dc)) == 1 { return true }
            case .bishop, .rook, .queen:
                if slides(piece.kind, dr: dr, dc: dc) && pathIsClear(from: source, to: target) { return true }
            }
        }
        return false
    }

    private func slides(_ kind: PieceKind, dr: Int, dc: Int) -> Bool {
        guard dr != 0 || dc != 0 else { return false }
        let diagonal = abs(dr) == abs(dc)
        let straight = dr == 0 || dc == 0
        return (kind == .bishop && diagonal) || (kind == .rook && straight)
            || (kind == .queen && (diagonal || straight))
    }

    private func pathIsClear(from: Int, to: Int) -> Bool {
        let dr = (to / 8 - from / 8).signum()
        let dc = (to % 8 - from % 8).signum()
        var row = from / 8 + dr
        var file = from % 8 + dc
        while row * 8 + file != to {
            if board[row * 8 + file] != nil { return false }
            row += dr
            file += dc
        }
        return true
    }

    private func isPseudoLegal(from: Int, to: Int, piece: ChessPiece) -> Bool {
        guard from != to, board[to]?.side != piece.side, board[to]?.kind != .king else { return false }
        let dr = to / 8 - from / 8
        let dc = to % 8 - from % 8
        switch piece.kind {
        case .pawn:
            let step = piece.side == .white ? -1 : 1
            let start = piece.side == .white ? 6 : 1
            if dc == 0 && board[to] == nil {
                return dr == step || (dr == step * 2 && from / 8 == start && board[from + step * 8] == nil)
            }
            if abs(dc) == 1 && dr == step {
                if board[to] != nil { return true }
                return to == enPassant && board[to - step * 8] == ChessPiece(side: piece.side.opponent, kind: .pawn)
            }
            return false
        case .knight:
            return (abs(dr) == 2 && abs(dc) == 1) || (abs(dr) == 1 && abs(dc) == 2)
        case .bishop, .rook, .queen:
            return slides(piece.kind, dr: dr, dc: dc) && pathIsClear(from: from, to: to)
        case .king:
            if max(abs(dr), abs(dc)) == 1 { return true }
            return canCastle(from: from, to: to, side: piece.side)
        }
    }

    private func canCastle(from: Int, to: Int, side: ChessSide) -> Bool {
        let home = side == .white ? 60 : 4
        guard from == home, [home - 2, home + 2].contains(to), !isInCheck(side) else { return false }
        let kingSide = to > from
        let right: CastleRight = side == .white
            ? (kingSide ? .whiteKing : .whiteQueen) : (kingSide ? .blackKing : .blackQueen)
        let rook = kingSide ? home + 3 : home - 4
        let transit = kingSide ? home + 1 : home - 1
        guard castlingRights.contains(right), board[rook] == ChessPiece(side: side, kind: .rook),
              pathIsClear(from: home, to: rook) else { return false }
        return !isAttacked(transit, by: side.opponent) && !isAttacked(to, by: side.opponent)
    }

    private mutating func apply(_ move: ChessMove) {
        guard let piece = board[move.from] else { return }
        if piece.kind == .king {
            castlingRights.subtract(piece.side == .white ? [.whiteKing, .whiteQueen] : [.blackKing, .blackQueen])
        }
        // A rook moving from or being captured on its original square loses its right.
        for (square, right) in [(0, CastleRight.blackQueen), (7, .blackKing), (56, .whiteQueen), (63, .whiteKing)] {
            if move.from == square || move.to == square { castlingRights.remove(right) }
        }
        if piece.kind == .pawn && move.to == enPassant && board[move.to] == nil {
            board[move.to + (piece.side == .white ? 8 : -8)] = nil
        }
        if piece.kind == .king && abs(move.to - move.from) == 2 {
            let rookFrom = move.to > move.from ? move.from + 3 : move.from - 4
            let rookTo = (move.from + move.to) / 2
            board[rookTo] = board[rookFrom]
            board[rookFrom] = nil
        }
        board[move.from] = nil
        board[move.to] = ChessPiece(side: piece.side, kind: move.promotion ?? piece.kind)
        enPassant = piece.kind == .pawn && abs(move.to - move.from) == 16 ? (move.from + move.to) / 2 : nil
        turn = turn.opponent
    }
}

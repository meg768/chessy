import SwiftUI

struct ChessboardView: View {
    @State private var game = ChessGame()
    @State private var selectedSquare: Int?
    @State private var feedback: String?
    @State private var promotionMoves: [ChessMove] = []

    private var selectedMoves: [ChessMove] {
        selectedSquare.map { game.legalMoves(from: $0) } ?? []
    }

    var body: some View {
        let status = game.status
        let destinations = Set(selectedMoves.map(\.to))
        VStack(spacing: 12) {
            Text(feedback ?? selectedSquare.map { "Move from \(coordinate($0)) — choose a destination" }
                 ?? (status.isFinished ? "Game over" : "Select a \(game.turn.rawValue) piece, then its destination"))
                .font(.callout)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("boardInstructions")

            GeometryReader { geometry in
                let side = min(geometry.size.width, geometry.size.height)
                let squareSize = side / 8

                VStack(spacing: 0) {
                    ForEach(0..<8, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(0..<8, id: \.self) { column in
                                square(row: row, column: column, size: squareSize, destinations: destinations)
                            }
                        }
                    }
                }
                .frame(width: side, height: side)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .disabled(status.isFinished)

            Text(statusText(status))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(minWidth: 560, minHeight: 620)
        .sheet(isPresented: Binding(get: { !promotionMoves.isEmpty }, set: { if !$0 { promotionMoves = [] } })) {
            VStack(spacing: 20) {
                Text("Promote pawn").font(.headline)
                HStack {
                    ForEach(PieceKind.promotions, id: \.self) { kind in
                        Button(kind.rawValue.capitalized) {
                            if let move = promotionMoves.first(where: { $0.promotion == kind }) {
                                finish(move)
                            }
                            promotionMoves = []
                        }
                    }
                }
                Button("Cancel", role: .cancel) { promotionMoves = [] }
            }
            .padding(24)
        }
    }

    private func square(row: Int, column: Int, size: CGFloat, destinations: Set<Int>) -> some View {
        let index = row * 8 + column
        let selected = selectedSquare == index
        return Button {
            select(index)
        } label: {
            ZStack {
                if let piece = game.board[index] {
                    Image(piece.imageName)
                        .resizable()
                        .scaledToFit()
                        .padding(size * 0.06)
                }
            }
                .frame(width: size, height: size)
                .background((row + column).isMultiple(of: 2)
                            ? Color(red: 0.91, green: 0.87, blue: 0.77)
                            : Color(red: 0.43, green: 0.56, blue: 0.70))
                .overlay {
                    if destinations.contains(index) {
                        Circle()
                            .fill(Color.black.opacity(0.35))
                            .frame(width: size * 0.2, height: size * 0.2)
                            .allowsHitTesting(false)
                    }
                    if selected {
                        Rectangle()
                            .strokeBorder(Color.black, lineWidth: 3)
                            .padding(3)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(coordinate(index)), \(game.board[index]?.name ?? "empty")")
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier(coordinate(index))
        .help(selected ? "Click again to cancel selection" : coordinate(index))
    }

    private func select(_ index: Int) {
        guard !game.status.isFinished else { return }
        feedback = nil
        if selectedSquare == index {
            selectedSquare = nil
        } else if game.board[index]?.side == game.turn {
            selectedSquare = index
        } else if let source = selectedSquare {
            let candidates = game.legalMoves(from: source).filter { $0.to == index }
            if candidates.contains(where: { $0.promotion != nil }) {
                promotionMoves = candidates
            } else if let move = candidates.first {
                finish(move)
            } else {
                feedback = "Illegal move — choose a highlighted destination."
            }
        } else {
            feedback = "It is \(game.turn.rawValue)'s turn. Select one of their pieces."
        }
    }

    private func finish(_ move: ChessMove) {
        if game.move(move) {
            selectedSquare = nil
            feedback = nil
        }
    }

    private func statusText(_ status: GameStatus) -> String {
        switch status {
        case .playing: "\(game.turn.rawValue.capitalized) to move"
        case .check: "\(game.turn.rawValue.capitalized) is in check"
        case .checkmate: "Checkmate — \(game.turn.opponent.rawValue.capitalized) wins"
        case .stalemate: "Stalemate — draw"
        }
    }

    private func coordinate(_ index: Int) -> String {
        "\(Array("abcdefgh")[index % 8])\(8 - index / 8)"
    }

}

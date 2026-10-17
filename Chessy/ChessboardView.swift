import SwiftUI

struct ChessboardView: View {
    @State private var pieces = Self.startingPosition
    @State private var selectedSquare: Int?

    private static let startingPosition: [String?] = {
        let backRank = ["♜", "♞", "♝", "♛", "♚", "♝", "♞", "♜"]
        let whiteRank = ["♖", "♘", "♗", "♕", "♔", "♗", "♘", "♖"]
        return backRank.map(Optional.some)
            + Array(repeating: "♟", count: 8)
            + Array(repeating: nil, count: 32)
            + Array(repeating: "♙", count: 8)
            + whiteRank.map(Optional.some)
    }()

    var body: some View {
        VStack(spacing: 12) {
            Text(selectedSquare.map { "Move from \(coordinate($0)) — choose a destination" }
                 ?? "Select a piece, then its destination")
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
                                square(row: row, column: column, size: squareSize)
                            }
                        }
                    }
                }
                .frame(width: side, height: side)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            Text("Free movement · Chess rules are not enforced")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(minWidth: 560, minHeight: 620)
    }

    private func square(row: Int, column: Int, size: CGFloat) -> some View {
        let index = row * 8 + column
        let selected = selectedSquare == index
        return Button {
            select(index)
        } label: {
            ZStack {
                if pieces[index] != nil {
                    Image(pieceName(at: index).replacingOccurrences(of: " ", with: "-"))
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
                    if selected {
                        Rectangle()
                            .strokeBorder(Color.black, lineWidth: 3)
                            .padding(3)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(coordinate(index)), \(pieceName(at: index))")
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier(coordinate(index))
        .help(selected ? "Click again to cancel selection" : coordinate(index))
    }

    private func select(_ index: Int) {
        if let source = selectedSquare {
            if source != index {
                pieces[index] = pieces[source]
                pieces[source] = nil
            }
            selectedSquare = nil
        } else if pieces[index] != nil {
            selectedSquare = index
        }
    }

    private func coordinate(_ index: Int) -> String {
        "\(Array("abcdefgh")[index % 8])\(8 - index / 8)"
    }

    private func pieceName(at index: Int) -> String {
        switch pieces[index] {
        case "♜": "black rook"
        case "♞": "black knight"
        case "♝": "black bishop"
        case "♛": "black queen"
        case "♚": "black king"
        case "♟": "black pawn"
        case "♖": "white rook"
        case "♘": "white knight"
        case "♗": "white bishop"
        case "♕": "white queen"
        case "♔": "white king"
        case "♙": "white pawn"
        default: "empty"
        }
    }
}

# Chessy

A minimal native macOS chessboard built with SwiftUI. Requires macOS 14 or later.

## Use

White starts. Click a piece of the side to move, then a highlighted destination. Click the selected square again to cancel, or another friendly piece to change selection. Illegal destinations leave the board unchanged and display feedback. The board starts in the standard arrangement and resizes with the window.

The self-contained rules model enforces alternating turns, piece movement and captures, king safety, castling, en passant, and promotion with a choice of queen, rook, bishop, or knight. Check, checkmate, and stalemate are displayed; checkmate and stalemate stop further moves. Canceling promotion leaves the original position unchanged.

No AI, clocks, move history, or external dependencies are included. Draws by repetition, the 50/75-move rules, agreement, and dead positions/insufficient material are not adjudicated. Use File → New Game (⌘N), then confirm, to replace the saved game with a new one. This is a local two-player board, not a tournament adjudicator.

## Automatic saving

One game is saved locally as versioned JSON in the app's Application Support
folder (`Chessy/game.json`, inside the app container when sandboxed). Every
completed legal move is written atomically before the event finishes. This
includes the final move of a completed game. Launching restores the board,
side to move, castling rights, and en passant target; game status is recomputed.
There is no cloud sync, game library, or move-history storage.

Selecting a piece, illegal clicks, and an unconfirmed promotion do not save a
new position. Closing during promotion restores the position before that move.
New Game requires confirmation and saves the initial position before replacing
the current board. Cancel leaves both board and file unchanged. If that save
fails, the current game stays open.

A missing save starts a fresh game. Unreadable, malformed, or unsupported-version
saves show a warning and start a fresh board; the original file is retained
until a completed move or confirmed New Game replaces it. A move whose save
fails remains playable in memory, with a visible warning that it may be lost
on quit. The next successful save clears the warning. This is a single local
snapshot, without backups or multi-instance conflict handling.

## Build

Open `chessy.xcodeproj` in Xcode and run the shared **Chessy** scheme, or run:

```sh
xcodebuild -project chessy.xcodeproj -scheme Chessy \
  -configuration Debug -destination 'platform=macOS' \
  -derivedDataPath /tmp/chessy-build build
```

Local builds use ad-hoc signing. App Store distribution is outside this initial implementation.

## Verification

Build the macOS app with the command above. Run the independent rules tests with Apple's Swift Package Manager (no package dependencies):

```sh
swift test
```

The Xcode app and test package compile the same model and GameStore sources. Tests cover each piece, blocked paths and captures, turns, king safety and pins, castling restrictions and lost rights, en passant and its expiry, all promotion choices, checkmate, stalemate, and the opening move tree through three plies (400 and 8,902 positions).

Storage tests additionally cover missing/corrupt/version-mismatched saves, restored turn and special-move rights, promotion, completed games, replacing a save with a new game, and write failures using isolated temporary files.

Verified with Xcode 26.5: app builds and all 24 tests passed. Manually verified e2–e4 surviving quit/relaunch with Black to move, and New Game cancellation/confirmation. In the running app, manually checked illegal-move feedback, turn enforcement, destination highlights, cancellation, Fool's Mate with disabled squares, and promotion cancellation followed by choosing a knight.

Movement rules were checked against [FIDE Laws of Chess, Article 3](https://handbook.fide.com/chapter/E012023).

## Piece artwork

The app bundles the standard Cburnett chess-piece set from Wikimedia Commons.
All twelve original SVGs are included unchanged in `Chessy/Assets.xcassets`;
Xcode preserves their vector representation for crisp Retina scaling. There
are no runtime downloads or added rendering dependencies. The board opens in
an 800 × 860 point content area and can shrink to 560 × 620 points.

Copyright © Cburnett and contributors, including Antonsusi and TomFryers.
Each file page offers multiple licenses; this project uses the **3-clause BSD**
option. The complete notice is in `Chessy/PieceArtwork-LICENSE.txt` and is also
copied into the app bundle. Sources (license checked 2026-10-18):

| Piece | Original source and licensing |
| --- | --- |
| white king | [Chess_klt45.svg](https://commons.wikimedia.org/wiki/File:Chess_klt45.svg) |
| black king | [Chess_kdt45.svg](https://commons.wikimedia.org/wiki/File:Chess_kdt45.svg) |
| white queen | [Chess_qlt45.svg](https://commons.wikimedia.org/wiki/File:Chess_qlt45.svg) |
| black queen | [Chess_qdt45.svg](https://commons.wikimedia.org/wiki/File:Chess_qdt45.svg) |
| white rook | [Chess_rlt45.svg](https://commons.wikimedia.org/wiki/File:Chess_rlt45.svg) |
| black rook | [Chess_rdt45.svg](https://commons.wikimedia.org/wiki/File:Chess_rdt45.svg) |
| white bishop | [Chess_blt45.svg](https://commons.wikimedia.org/wiki/File:Chess_blt45.svg) |
| black bishop | [Chess_bdt45.svg](https://commons.wikimedia.org/wiki/File:Chess_bdt45.svg) |
| white knight | [Chess_nlt45.svg](https://commons.wikimedia.org/wiki/File:Chess_nlt45.svg) |
| black knight | [Chess_ndt45.svg](https://commons.wikimedia.org/wiki/File:Chess_ndt45.svg) |
| white pawn | [Chess_plt45.svg](https://commons.wikimedia.org/wiki/File:Chess_plt45.svg) |
| black pawn | [Chess_pdt45.svg](https://commons.wikimedia.org/wiki/File:Chess_pdt45.svg) |

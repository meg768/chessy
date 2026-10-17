# Chessy

A minimal native macOS chessboard built with SwiftUI. Requires macOS 14 or later.

## Use

Click a piece, then click its destination. Click the selected square again to cancel. The board starts with all 32 pieces in the standard arrangement and resizes with the window.

Movement is unrestricted: there are no turns, legal-move checks, check/checkmate, castling, en passant, or promotion. Moving onto an occupied square replaces its piece. Positions are not saved; relaunching restores the initial position. No engine, networking, or external dependencies are included.

## Build

Open `chessy.xcodeproj` in Xcode and run the shared **Chessy** scheme, or run:

```sh
xcodebuild -project chessy.xcodeproj -scheme Chessy \
  -configuration Debug -destination 'platform=macOS' \
  -derivedDataPath /tmp/chessy-build build
```

Local builds use ad-hoc signing. App Store distribution is outside this initial implementation.

## Verification

Built successfully with Xcode 26.5. Manually verified the initial arrangement, selection, cancellation, an e2-to-e4 move, and the board at the minimum window size.

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

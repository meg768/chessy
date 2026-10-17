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

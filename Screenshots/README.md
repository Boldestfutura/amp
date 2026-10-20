# Screenshots

Real screenshots must be captured on a Mac with Xcode 26+ and the iOS 26 SDK, because
Liquid Glass only renders on iOS 26.

## Option A — fastlane snapshot (recommended)

From the repo root on your Mac:

```sh
brew install xcodegen
xcodegen generate
bundle install
bundle exec fastlane screenshots
```

Output lands in `Screenshots/output/`.

## Option B — Xcode UI test capture

1. `xcodegen generate && open Amp.xcodeproj`
2. Run the `AmpUITests` target on an iPhone 17 Pro simulator and an iPad Pro simulator.
3. Use Xcode's "Capture Screenshots" or the simulator's `File > Save Screen`.

## Suggested shot list

| # | Screen | Device |
| --- | --- | --- |
| 1 | Login (PIN code) | iPhone |
| 2 | Artists list | iPhone |
| 3 | Album grid | iPhone |
| 4 | Track list | iPhone |
| 5 | Now Playing (full) | iPhone |
| 6 | iPad split view (library + detail) | iPad |

Add the resulting PNGs to this folder and reference them in the root `README.md`.

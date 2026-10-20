# AGENTS.md — PlexGlass

Handoff notes for AI coding agents (opencode, Claude Code, etc.) working in this repo.
Read this before making changes.

## What this is

PlexGlass is a **from-scratch**, native **iOS 26 / iPadOS 26** music client for a user's
own Plex Media Server, written in **SwiftUI** using Apple's native **Liquid Glass** APIs.

**Hard boundary:** do NOT reverse-engineer, decompile, or clone **Plexamp** (or any other
proprietary app). Use only the public Plex API and Apple's documented frameworks. Cloning a
closed-source app's UI/behavior is not in scope regardless of the tooling available.

## Current version: 0.1.0-beta

Everything is **pre-1.0**. Keep `MARKETING_VERSION` in the `0.x` range during beta. Bump
`CURRENT_PROJECT_VERSION` (build number) for each change.

## Requirements

| Tool | Version |
| --- | --- |
| Xcode | 26.0+ (Liquid Glass needs it) |
| iOS SDK | 26.0+ |
| Swift | 6.0 |
| Deployment target | iOS 26.0 |
| XcodeGen | latest (`brew install xcodegen`) |

There is **no fallback** for pre-iOS 26 in this beta. Liquid Glass is iOS 26+ only.

## Project layout

```
project.yml                     # XcodeGen spec — the source of truth for targets/settings
PlexGlass/
  App/PlexGlassApp.swift        # @main, AppModel (owns client/session/player)
  Models/
    PlexModels.swift            # PlexServer, PlexResource, pin types
    PlexMedia.swift             # Artist/Album/Track/Media/Part + media container
    PlayerModel.swift           # AVAudioPlayer playback, queue, repeat/shuffle
    SessionStore.swift          # auth state + Keychain + UserDefaults persistence
  Networking/PlexClient.swift   # Plex HTTP client (plex.tv + server library calls)
  LiquidGlass/GlassComponents.swift  # GlassCard, GlassPill, GlassTransportButton
  Views/
    RootView.swift              # auth gate
    LoginView.swift             # Plex PIN sign-in
    Library/                    # LibraryRootView, AlbumListView, TrackListView
    NowPlaying/                 # NowPlayingBar (mini), NowPlayingView (full sheet)
    Shared/ArtworkView.swift    # async artwork loader/transcoder
  Resources/DemoData.swift      # deterministic data for previews + screenshots
PlexGlassUITests/               # snapshot UI tests (fastlane)
fastlane/Fastfile               # `fastlane screenshots` lane
Screenshots/                    # real captures go here (Mac only)
```

## Build & run (on a Mac)

```sh
brew install xcodegen
xcodegen generate
open PlexGlass.xcodeproj
```

Set your signing team in Xcode, then run on an iOS 26 simulator/device.

Regenerate the project after editing `project.yml` (the `.xcodeproj` is gitignored and
generated).

## Conventions

- **Swift 6**, strict concurrency. UI types are `@MainActor`; use `@Observable` (not
  `ObservableObject`) for models. Views take dependencies via `.environment(...)`.
- **Liquid Glass only via native APIs.** Use `.glassEffect(_:in:)`, `GlassEffectContainer`,
  `.glassEffectID(_:in:)`, `.glassEffectUnion(id:namespace:)`, `.buttonStyle(.glass)` /
  `.glassProminent`. Do **not** hand-roll blur/material to imitate glass.
- Keep glass effects grouped in a `GlassEffectContainer` when adjacent (perf + morphing).
- Prefer system containers (tab bars, nav bars, sheets) for standard chrome; add custom
  glass only where the system doesn't cover the interaction.
- **Universal**: iPhone = `NavigationStack`; iPad (`horizontalSizeClass == .regular`) =
  `NavigationSplitView`. Test both.
- No inline comments unless they explain a non-obvious decision. No dead code.
- Secrets/tokens: Keychain only. Never commit tokens.

## What's done (0.1.0)

- Plex PIN/OAuth sign-in (`plex.tv/link`), server discovery, Keychain token persistence.
- Library browse: artists → albums → tracks (Plex JSON API).
- Playback: `AVAudioPlayer`, queue, next/previous, repeat (off/all/one), shuffle, seek.
- Liquid Glass mini-player and full Now Playing sheet with `GlassEffectContainer` morph.
- Demo mode (`-UITestDemoMode 1`) + fastlane snapshot UI tests.

## Next steps (suggested)

1. **ATS exception** for plain-HTTP local Plex servers: add `NSAppTransportSecurity` with a
   network exception (or `NSAllowsLocalNetworking`) so it can reach e.g.
   `http://192.168.1.243:32400`. Without this, manual/local connections fail on device.
2. **Manual "add server" flow** — the `showManual` button in `LoginView` is stubbed
   (`manualToken` declared but unused). Implement host/port/scheme/token entry as a fallback
   when auto-discovery finds no server.
3. **Direct-play quality**: `AVAudioPlayer` downloads the whole file. Consider `AVPlayer`
   with the transcoder/stream URL for streaming and large files.
4. **Search**, **offline downloads**, **scrobbling**, **gapless**, **CarPlay**.
5. **iPad polish**: real multi-column detail, keyboard shortcuts.
6. Wire `fastlane screenshots` and commit real captures into `Screenshots/` + root README.

## Reference: Liquid Glass APIs (iOS 26)

- `.glassEffect(_ glass: Glass, in shape: some Shape)` — default `.regular`, `Capsule`.
- `Glass.regular` / `.clear` / `.identity`; `.tint(Color)`; `.interactive()`.
- `GlassEffectContainer(spacing:)` — group + morph.
- `.glassEffectID(_:in:)` + `@Namespace` — morph identity across states.
- `.glassEffectUnion(id:namespace:)` — merge adjacent shapes.
- `.buttonStyle(.glass)` / `.glassProminent`.
- Docs: https://developer.apple.com/documentation/swiftui/applying-liquid-glass-to-custom-views

## Verifying changes

There is no CI here yet. On a Mac, the minimum check is a successful build:

```sh
xcodegen generate
xcodebuild -project PlexGlass.xcodeproj -scheme PlexGlass \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Update this file when you add commands or change conventions.

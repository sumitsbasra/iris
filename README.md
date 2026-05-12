# Iris

Personal AI assistant for iPhone. Less noise. More life.

## Docs

- [`CLAUDE.md`](CLAUDE.md) — Claude Code project bible (start here)
- [`docs/PRODUCT.md`](docs/PRODUCT.md) — vision, v1 scope, interaction design
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — system design, CloudKit schema, data flow
- [`docs/DECISIONS.md`](docs/DECISIONS.md) — architectural decision log

## Structure (current — Phase 1)

```
iris-ios/     iOS app (SwiftUI, iOS 26+)
docs/         Architecture, product, decisions
```

## Structure (target — Phase 3)

```
iris-ios/     iOS app (SwiftUI, iOS 26+)
iris-mac/     macOS companion (SwiftUI, macOS 15+)
shared/       Swift packages shared between targets
  IrisCore/   CloudKit models, shared types
  IrisAI/     Anthropic Managed Agents client, memory
  IrisGateway/iMessage gateway protocol
docs/         Architecture, product, decisions
```

## Requirements

- Xcode 26+
- iOS 26+ device or simulator (Apple Foundation Models)
- macOS 15+ for Mac companion
- Anthropic API key (Managed Agents access)
- iCloud account (CloudKit)

## Setup (Phase 1 — iOS only)

1. Clone repo
2. Open `iris-ios/Iris.xcodeproj` in Xcode
3. Add `ANTHROPIC_API_KEY` to Xcode scheme environment variables
4. Sign with your Apple Developer account
5. Enable CloudKit capability, container `iCloud.studio.ssb.iris`
6. Run on device or simulator (iOS 26+)

## Claude Code sessions

Always start by reading `CLAUDE.md`. It contains constraints and rules that apply to every session.

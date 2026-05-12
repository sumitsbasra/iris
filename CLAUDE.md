# Iris — Claude Code Project Bible

## What this is

Iris is a personal AI assistant for iPhone that proactively surfaces what matters in your life — missed messages, calendar conflicts, health nudges, local suggestions — and delivers them via iMessage/SMS. The iOS app is a thin shell (onboarding, dashboard, memory viewer, connections). All interaction happens through text messages from Iris.

The Mac companion app runs locally to enable true iMessage delivery via the Messages.app gateway.

## Build sequencing — read this first

Iris is built in three phases. Do not jump ahead.

**Phase 1 (current): iOS app only**
The Xcode project is a single iOS app target. No Mac target yet. No shared Swift packages yet. Get the iOS app working: onboarding, CloudKit schema, HealthKit, EventKit, permissions, dashboard, memory viewer.

**Phase 2: Extract shared packages**
Once the CloudKit schema is stable, extract `IrisCore` (models) and `IrisAI` (Anthropic client) into Swift packages. Do this only when the iOS data model is settled — not before.

**Phase 3: Add Mac companion target**
Add the macOS target to the Xcode project. It reads from the same CloudKit container. At this point the Mac target gets `IrisGateway` (osascript, SQLite watching) and the AI orchestration layer.

**If Claude Code tries to scaffold Mac targets or shared packages before being explicitly asked: stop and check with the user.**

## Monorepo structure (current state — Phase 1)

```
/iris-ios          iOS app (SwiftUI, iOS 26+) ← build this first
/docs              Architecture, product, decisions
CLAUDE.md          This file
```

## Monorepo structure (target state — Phase 3)

```
/iris-ios          iOS app (SwiftUI, iOS 26+)
/iris-mac          macOS companion app (SwiftUI, macOS 15+)
/shared            Swift packages shared between targets
  /IrisCore        CloudKit models, data types, shared logic
  /IrisAI          Anthropic API client, Managed Agents, memory
  /IrisGateway     iMessage gateway protocol (used by Mac target)
/docs              Architecture, product, decisions
CLAUDE.md          This file
```

## Tech stack

| Layer | Technology |
|---|---|
| iOS UI | SwiftUI, iOS 26+ |
| Mac UI | SwiftUI, macOS 15+ |
| AI orchestration | Anthropic Managed Agents API (claude-sonnet-4-6) |
| Lightweight tasks | Apple Foundation Models (on-device) |
| Memory / Dreaming | Anthropic Managed Agents memory + dreaming |
| Persistence | CloudKit (private database) |
| iMessage gateway | Mac companion → osascript → Messages.app |
| Health data | HealthKit |
| Calendar | EventKit |
| Notifications | UNUserNotificationCenter |

## Bundle IDs

- iOS: `studio.ssb.iris`
- Mac: `studio.ssb.iris.mac`
- Shared framework prefix: `studio.ssb.iris`

## Critical constraints — read before every session

**Never build UI for the conversation layer.** Iris's interaction model is iMessage/SMS. There is no in-app chat interface. Do not add one.

**CloudKit is the only database.** No SQLite, no local Core Data, no third-party backend. All user data lives in CloudKit private container `iCloud.studio.ssb.iris`.

**Managed Agents from day one.** All Claude API calls go through the Managed Agents runtime. Do not use the standard Messages API directly for agent logic. Use the beta header `anthropic-beta: managed-agents-2026-04-01`.

**iOS 26 minimum.** This unlocks Apple Foundation Models framework. Do not add fallbacks for older iOS versions.

**Privacy first.** Never log user data, message content, or health metrics to console in non-debug builds. Use `#if DEBUG` guards on any data logging.

**Mac companion is required for messaging.** Without the Mac companion, Iris cannot send messages. Onboarding should make this clear and guide the user to set it up.

## Model usage rules

| Task | Model |
|---|---|
| Proactive briefing generation | claude-sonnet-4-6 via Managed Agents |
| Memory extraction + ranking | claude-sonnet-4-6 via Managed Agents (dreaming) |
| Message classification (urgent?) | Apple Foundation Models on-device |
| Notification summary | Apple Foundation Models on-device |
| Complex multi-source reasoning | claude-sonnet-4-6 via Managed Agents |
| Simple string formatting | Haiku 4.5 (cost optimisation) |

Use Haiku for anything that doesn't require context or reasoning. Use Sonnet for anything that touches user memory or requires multi-source synthesis. Never use Opus unless explicitly instructed.

## CloudKit schema

See `docs/ARCHITECTURE.md` for full schema. Key record types:

- `UserProfile` — name, preferences, onboarding state
- `Memory` — fact text, confidence score (0.0-1.0), category, last updated
- `Connection` — connected data source, permission state, last synced
- `BriefingLog` — sent briefings, timestamp, delivery method
- `NudgeLog` — proactive nudges, user response (if any)

## iMessage gateway protocol

The iOS app and Mac companion communicate via CloudKit. When Iris needs to send a message:

1. iOS/backend writes a `PendingMessage` record to CloudKit
2. Mac companion polls CloudKit (or receives push) and picks it up
3. Mac executes via osascript to Messages.app
4. Mac writes delivery confirmation back to CloudKit

Do not use any other IPC mechanism. CloudKit is the message bus.

## Managed Agents session lifecycle

- One persistent agent session per user
- Session maintains conversation history and memory across interactions
- Dreaming runs on a schedule (nightly) to extract patterns and update memory rankings
- Sessions are stateful — do not create new sessions per message

## What to reuse from the existing Iris Mac app

The existing Iris Mac app (separate repo, ask user for path) likely contains:
- SQLite chat.db watching logic — reuse in `IrisGateway`
- osascript message sending — reuse in `IrisGateway`
- Multi-model orchestration patterns — reference for `IrisAI` package
- Memory data structures — adapt for CloudKit

Ask the user to point Claude Code at the existing repo before starting `IrisGateway` work.

## What NOT to build in v1

- Web dashboard
- Android support  
- Mac Catalyst (use proper macOS target)
- In-app chat UI
- Social/sharing features
- Team or multi-user support
- Anything requiring a Railway/external server (Mac handles orchestration)

## Session startup checklist

Before starting any session:
1. Read this file
2. Read `docs/ARCHITECTURE.md`
3. Read `docs/PRODUCT.md`
4. Check `docs/DECISIONS.md` for any recent architectural decisions
5. Ask the user what they're working on today before writing any code

# Iris — Decision Log

A running log of architectural and product decisions, with reasoning. Update this when something significant is decided or changed.

---

## 2025-05-11

### iOS-first, Mac as optional capability layer
**Decision:** Build Iris as an iOS app first. Mac companion adds iMessage capability but is not required.

**Reasoning:** The personal AI assistant use case lives on your phone, not your Mac. HealthKit, iMessage (for receiving), location, and daily life context are all mobile-first. The Mac is an upgrade, not a dependency.

**Alternative considered:** Mac-first (OpenClaw-style menubar app). Rejected because it limits the user base to people with always-on Macs and doesn't serve the mobile-first interaction model.

---

### Mac companion hosts AI orchestration, not a cloud server
**Decision:** All Anthropic Managed Agents calls happen from the Mac companion, not a Railway/Fly.io server.

**Reasoning:** Privacy-first positioning. Data stays on user's devices. No server costs for the developer. Aligns with "your AI running on your hardware" narrative. Mac is always-on for target users.

**Alternative considered:** Railway server for AI orchestration. Rejected because it introduces a third-party server into the data flow, adds cost, and weakens privacy story.

**Risk:** If Mac is off, proactive features stop. Mitigated by: scheduled briefings can be queued in CloudKit and delivered when Mac comes back online.

---

### Anthropic Managed Agents from day one
**Decision:** Use Managed Agents API (`managed-agents-2026-04-01`) from the start, not standard Messages API.

**Reasoning:** Managed Agents gives dreaming (memory refinement), persistent session state, and built-in memory management for free. Starting with it means no migration later. The $0.08/session-hour cost is negligible at personal scale — estimated $3-5/user/month total.

**Alternative considered:** Standard Claude API with custom memory layer. Rejected because it duplicates work Anthropic has already done and misses dreaming.

---

### CloudKit as sole database
**Decision:** All persistence goes through CloudKit private container `iCloud.studio.ssb.iris`.

**Reasoning:** Already used for Challenges app (familiar). Free at personal scale. End-to-end encrypted. Works across iOS and macOS natively. No third-party backend required.

**Limitation:** CloudKit cannot run server-side logic. Trigger evaluation and scheduling must run on the Mac companion, not a cloud function.

**Alternative considered:** Supabase. Rejected because it introduces a third-party server and the privacy story weakens.

---

### iMessage via osascript on Mac companion
**Decision:** Send iMessages using AppleScript via Mac companion's Messages.app, not LoopMessage or similar third-party APIs.

**Reasoning:** Third-party iMessage APIs operate in violation of Apple's ToS and face account bans. Lindy documented exactly this failure. osascript with the user's own Apple ID is stable, private, and not subject to spam detection at personal scale.

**Risk:** Requires a Mac to be on. Mitigated by CloudKit message queuing — messages are held and delivered when Mac comes back online.

**Alternative considered:** LoopMessage API. Rejected — Apple stated non-compliant apps would be terminated June 2026.

---

### No in-app chat UI
**Decision:** Iris has no chat interface inside the iOS app. All conversation happens via iMessage/SMS.

**Reasoning:** iMessage is where users already live. Adding an in-app chat creates friction and a second place to check. The iOS app is a dashboard and configuration layer, not a conversation surface.

**This is a hard constraint.** Do not add a chat view, even as a fallback.

---

### iOS 26 minimum deployment target
**Decision:** iOS 26+ only.

**Reasoning:** Unlocks Apple Foundation Models framework for on-device lightweight AI tasks (message classification, notification summarisation). iOS 26 also brings improved HealthKit APIs and Background Assets.

**Trade-off:** Limits install base to recent devices. Acceptable — target user is on current hardware.

---

### Model routing strategy
**Decision:** Apple Foundation Models for on-device lightweight tasks, claude-sonnet-4-6 for reasoning, Haiku 4.5 for high-volume low-complexity tasks.

**Reasoning:** Cost optimisation while maintaining quality where it matters. On-device models are free and private. Sonnet is the right capability level for multi-source synthesis. Haiku for formatting/routing.

**Rule:** Never use Opus without explicit instruction. The cost differential is not justified for Iris's use cases.

---

### Monorepo with two Xcode targets
**Decision:** Single Xcode project with iOS app target + macOS app target. Shared Swift packages in `/shared`.

**Reasoning:** Avoids duplicate CloudKit models, shared AI client code, shared data types. Easier to keep in sync. Single repo for Claude Code context.

**Structure:**
- `iris-ios/` — iOS SwiftUI app
- `iris-mac/` — macOS SwiftUI companion
- `shared/IrisCore` — CloudKit models, shared types
- `shared/IrisAI` — Anthropic client, memory management
- `shared/IrisGateway` — iMessage protocol (used by Mac target only)

---

### No SMS fallback — Mac companion required for messaging
**Decision:** Removed Twilio SMS fallback. Mac companion is required for Iris to send messages.

**Reasoning:** Keeping the architecture simple. Twilio adds cost, complexity, and a third-party dependency. The target user has a Mac. If the Mac is off, messages queue in CloudKit and deliver when it comes back online. This is acceptable behaviour.

**Alternative considered:** Twilio SMS fallback for users without a Mac. Rejected — adds complexity without meaningful benefit for v1 target user.

---



### [Decision title]
**Decision:** [What was decided]

**Reasoning:** [Why]

**Alternative considered:** [What else was on the table and why it was rejected]

**Risk:** [Downsides or unknowns, and how they're mitigated]

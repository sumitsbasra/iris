# Iris — Architecture

## System overview

```
┌─────────────────────────────────────────────────────┐
│                   User's iPhone                      │
│                                                      │
│  ┌──────────────┐      ┌────────────────────────┐   │
│  │  Iris iOS    │      │   Apple Foundation     │   │
│  │  (SwiftUI)   │      │   Models (on-device)   │   │
│  │              │      │   - classify messages  │   │
│  │  - Onboarding│      │   - summarise notifs   │   │
│  │  - Dashboard │      └────────────────────────┘   │
│  │  - Memory    │                                    │
│  │  - Settings  │      ┌────────────────────────┐   │
│  └──────┬───────┘      │   HealthKit / EventKit │   │
│         │              │   Contacts / Location  │   │
│         ▼              └────────────────────────┘   │
│  ┌──────────────┐                                    │
│  │  CloudKit    │ ◄── private container              │
│  │  (iCloud)    │     iCloud.studio.ssb.iris         │
│  └──────┬───────┘                                    │
└─────────┼───────────────────────────────────────────┘
          │ CloudKit sync
┌─────────┼───────────────────────────────────────────┐
│         ▼           User's Mac (optional)            │
│  ┌──────────────┐                                    │
│  │  Iris Mac    │                                    │
│  │  companion   │                                    │
│  │              │                                    │
│  │  - AI brain  ├──► Anthropic Managed Agents API   │
│  │  - Scheduler │         (claude-sonnet-4-6)        │
│  │  - Gateway   │                                    │
│  └──────┬───────┘                                    │
│         │ osascript                                  │
│         ▼                                            │
│  ┌──────────────┐                                    │
│  │  Messages.app│──► iMessage (blue bubble)          │
│  └──────────────┘                                    │
└─────────────────────────────────────────────────────┘

```

## Where the brain lives

The Mac companion is the AI orchestration layer. It:
- Holds the Managed Agents session for the user
- Runs the proactive trigger scheduler
- Reads from CloudKit (health data synced from iPhone, calendar, pending tasks)
- Calls Anthropic Managed Agents to generate briefings and nudges
- Sends output via Messages.app (iMessage)
- Writes results back to CloudKit (BriefingLog, NudgeLog, updated Memory)

The iOS app is a configuration and transparency layer. It does not call the Anthropic API directly.

## Why the Mac holds the brain

- Always-on background processing without iOS battery constraints
- Full Messages.app access for true iMessage (blue bubbles)
- No server costs — user's own hardware
- Consistent with Iris's privacy-first positioning (data stays on your devices)
- Mac companion is optional — Twilio SMS fallback maintains core functionality

## CloudKit schema

### UserProfile
```
recordType: UserProfile
fields:
  userID: String (Apple ID hash, not PII)
  displayName: String
  phoneNumber: String (for SMS delivery)
  onboardingComplete: Bool
  briefingTime: String ("07:30")
  timezone: String
  deliveryMethod: String ("imessage" | "sms")
  macCompanionLinked: Bool
  createdAt: Date
  updatedAt: Date
```

### Memory
```
recordType: Memory
fields:
  text: String ("Training for NYC Marathon, Nov 1, sub-4hr goal")
  category: String ("goal" | "fact" | "preference" | "pattern")
  confidence: Double (0.0 - 1.0)
  source: String ("onboarding" | "conversation" | "dreaming" | "inferred")
  lastReinforced: Date
  reinforcementCount: Int
  active: Bool
  createdAt: Date
  updatedAt: Date
```

### Connection
```
recordType: Connection
fields:
  sourceType: String ("calendar" | "health" | "messages" | "reminders" | "contacts" | "photos" | "music" | "homekit" | "wallet")
  enabled: Bool
  permissionGranted: Bool
  lastSynced: Date
  metadata: String (JSON — e.g. which calendars selected)
```

### PendingMessage
```
recordType: PendingMessage
fields:
  recipientPhone: String
  body: String
  messageType: String ("briefing" | "nudge" | "reply")
  priority: Int (0 = normal, 1 = urgent)
  scheduledFor: Date
  status: String ("pending" | "delivered" | "failed")
  createdAt: Date
  deliveredAt: Date (optional)
```

### BriefingLog
```
recordType: BriefingLog
fields:
  content: String (full briefing text)
  deliveryMethod: String
  deliveredAt: Date
  userResponded: Bool
  responseText: String (optional)
```

### NudgeLog
```
recordType: NudgeLog
fields:
  triggerType: String ("calendar" | "health" | "location" | "message" | "pattern")
  content: String
  deliveredAt: Date
  userResponse: String (optional — "nah", "yes", no response)
  responseAt: Date (optional)
```

## Managed Agents session design

### Session initialisation
One session per user, created on first Mac companion launch. Session ID stored in CloudKit UserProfile.

```swift
// IrisAI package — AgentSession.swift
struct AgentSession {
    let sessionID: String
    let userID: String
    var memoryStoreID: String
}
```

### System prompt structure
The agent system prompt is built dynamically from CloudKit Memory records, ranked by confidence × recency. Injected at session start and refreshed daily.

```
You are Iris, a personal assistant for [name].

WHAT YOU KNOW ABOUT THIS PERSON:
[Memory records ranked by confidence, highest first]
- [memory.text] (confidence: [score])

CONNECTED DATA SOURCES:
[Active connections list]

YOUR JOB:
- Generate proactive briefings at [briefingTime] each morning
- Surface nudges when triggers fire (calendar, health, messages)
- Keep responses short — this is iMessage, not email
- Learn from how the user responds ("nah" = don't send this type again)

TONE: Calm, direct, friendly. Like a smart friend who has your calendar open.
Never robotic. Never sycophantic.
```

### Dreaming schedule
Runs nightly at 3am local time via Mac companion scheduler.

Dreaming reviews:
- NudgeLog responses from the past 7 days
- New memories added via conversation
- Patterns in user behaviour (response times, ignored nudges)

Dreaming outputs:
- Updated confidence scores on existing Memory records
- New Memory records for inferred patterns
- Deprecated memories marked `active: false`

## Proactive trigger system

### Scheduled triggers (always run)
| Trigger | Time | Requires |
|---|---|---|
| Morning briefing | User's set time (default 7:30am) | Calendar, any one connection |
| Evening preview | 8pm | Calendar |

### Event-driven triggers (fire when condition met)
| Trigger | Condition | Data source |
|---|---|---|
| Unanswered message | Important contact, no reply 24h+ | Messages (Mac) |
| Calendar gap | >2hr free block appears | EventKit |
| Run window | HRV good + calendar clear + weather ok | HealthKit + EventKit |
| Pre-meeting | 45min before meeting, no prep noted | EventKit |
| Nutrition gap | No food log by 1pm | HealthKit |
| Sleep nudge | Calendar clear next morning + late hour | EventKit + time |

### Trigger evaluation loop (Mac companion)
```
Every 15 minutes:
  1. Read latest data from CloudKit
  2. Evaluate each trigger condition
  3. If trigger fires:
     a. Check NudgeLog — did we send this type recently?
     b. Check user's response history for this trigger type
     c. If appropriate, call Managed Agent to generate nudge
     d. Write PendingMessage to CloudKit
     e. Mac gateway picks up and sends via Messages.app
```

## iMessage gateway (Mac companion)

### Sending
```swift
// IrisGateway package — MessageSender.swift
func sendIMessage(to phoneNumber: String, body: String) async throws {
    let script = """
    tell application "Messages"
        set targetBuddy to buddy "\(phoneNumber)" of service "SMS"
        send "\(body)" to targetBuddy
    end tell
    """
    // Execute via Process + /usr/bin/osascript
}
```

### Receiving (incoming replies)
Watch `~/Library/Messages/chat.db` WAL file for new entries matching user's own phone number conversation. Parse new messages and relay to Managed Agent session for processing.

```swift
// IrisGateway package — MessageWatcher.swift
// Uses kqueue or FSEvents to watch chat.db-wal
// On new write: query chat.db for latest message in Iris conversation
// If new message from user: relay to AgentSession
```

## iOS app structure

```
iris-ios/
  App/
    IrisApp.swift
    AppDelegate.swift
  Onboarding/
    WelcomeView.swift
    ConversationOnboardingView.swift   ← the chat-style onboarding
    PermissionsView.swift
    MemoryReviewView.swift
  Dashboard/
    DashboardView.swift
    TodayView.swift
    MemoryView.swift
    ConnectionsView.swift
  Settings/
    SettingsView.swift
    MacCompanionSetupView.swift
  Permissions/
    HealthKitManager.swift
    EventKitManager.swift
    ContactsManager.swift
```

## Mac companion structure

```
iris-mac/
  App/
    IrisMacApp.swift
    AppDelegate.swift
  MenuBar/
    MenuBarView.swift              ← minimal status item
  Agent/
    AgentSessionManager.swift      ← manages Managed Agents session
    BriefingGenerator.swift
    TriggerEvaluator.swift
    DreamingScheduler.swift
  Gateway/
    MessageSender.swift            ← osascript sending
    MessageWatcher.swift           ← chat.db watching
  CloudKit/
    CloudKitSync.swift             ← reads PendingMessage, writes logs
```

## Shared packages

```
shared/
  IrisCore/
    Models/                        ← CloudKit record types as Swift structs
    CloudKitManager.swift          ← shared read/write logic
  IrisAI/
    AnthropicClient.swift          ← Managed Agents API wrapper
    MemoryManager.swift            ← memory ranking + injection
    SystemPromptBuilder.swift      ← dynamic prompt construction
```

## Privacy and data handling

- All user data stays in CloudKit private database — Apple can't read it
- Anthropic API calls include only synthesised context, never raw message content
- Health data is summarised before being sent to Anthropic (e.g. "HRV good today", not raw values)
- No analytics, no crash reporting that includes user data
- Mac companion never sends chat.db content to any server — only extracted metadata

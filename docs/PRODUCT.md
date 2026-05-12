# Iris — Product

## What Iris is

Iris is a personal AI assistant that understands your life and reaches out when it has something worth saying.

It connects to your calendar, health data, messages, and more — then uses that context to surface what matters before you think to ask. A friend who has your whole life open and knows when to text.

**Poppy shows you your life. Iris understands it.**

## What makes Iris different

### Context AND permissions
Most assistants ask for permissions (what can I see?) but skip context (who is this person, what do they care about?). Iris builds a living model of the user — goals, patterns, preferences — and gets smarter with every interaction.

### Adaptive memory
Iris learns from how you respond. "Nah" to a concert suggestion on a Tuesday teaches Iris you prefer quiet weeknights. Ignored nudges get deprioritised. Every response is a signal.

### iMessage-native
No new interface to learn. Iris texts you like a person. The iOS app is for configuration and transparency — not for conversation.

### Privacy-first
Your data stays on your devices. CloudKit private database. AI reasoning happens on your Mac, not a third-party server. Anthropic never sees your raw data — only synthesised context.

### Apple-native moat
Deep HealthKit, EventKit, Contacts, and HomeKit integration. Built in Swift. Runs on your hardware. This is not a web wrapper.

## Target user (v1)

iPhone user on iOS 26+, ideally with a Mac they leave on regularly. Busy, context-switching a lot. Wants fewer apps, not more. Values privacy. Already trusts the Apple ecosystem.

Primary persona: Sumit. Design Program Manager, marathon training, YouTube channel, multiple ongoing projects. Doesn't want to open another app — wants Iris to handle the ambient overhead of life.

## v1 scope

### In scope
- Conversational onboarding (5-7 exchanges, no form)
- Calendar integration (EventKit)
- Health integration (HealthKit — HRV, sleep, fitness, nutrition)
- Reminders integration
- Contacts integration (birthdays, important people)
- Morning briefing (daily, scheduled)
- Evening preview (daily, scheduled)
- Event-driven nudges (see trigger list in ARCHITECTURE.md)
- iMessage delivery via Mac companion (required)
- Dashboard: Today / Memory / Connected tabs
- Memory viewer with confidence levels
- Mac companion menubar app
- Dreaming (nightly memory refinement)
- Free trial + subscription paywall

### Not in scope for v1
- In-app chat UI
- Email integration
- WhatsApp integration
- Web dashboard
- Android
- Team / shared accounts
- Siri integration
- Widgets (ship in v1.1)
- Apple Watch app (ship in v1.1)
- Mac Catalyst

## Onboarding philosophy

Iris speaks first. It asks one open question. The user's answer drives everything — permissions requested, memory seeded, first briefing shaped.

Five principles:
1. Iris introduces itself and asks one question — never a form
2. Permissions follow context — requested because of what you said, not upfront
3. Complete in 5-7 exchanges — Iris learns the rest over time
4. Memory review before launch — user sees and corrects what Iris knows
5. First briefing within 60 seconds of completing onboarding

Core onboarding questions (in natural conversation, not a list):
1. What's been taking up most of your headspace lately?
2. What are you working toward right now? (goal extraction)
3. What do you wish you didn't have to think about? (automation targets)

Everything else — job, location, schedule patterns — Iris infers from data sources over time.

## Interaction design

### Briefing format
Short. iMessage-native. No markdown, no bullet points. Reads like a text from a smart friend.

Good:
> Morning. Design review at 10 — you haven't shared the deck yet. Your HRV looks good so the 8-miler tonight should be solid. Maya messaged 2 days ago, worth a reply today.

Bad:
> **Good morning! Here is your daily briefing:**
> • 📅 Design review at 10:00 AM
> • 🏃 8 mile easy run scheduled
> • 📬 Unread message from Maya

### Nudge format
Even shorter. One thing. Actionable or dismissible with a one-word reply.

> Your evening's clear and you've got a long run tomorrow — good night to be in bed by 10. Want me to set a reminder?

### User reply handling
Iris handles:
- "yes" / "yeah" / "sure" → confirm action
- "nah" / "no" / "skip" → dismiss + note preference
- "remind me at X" → reschedule
- "tell me more" → expand
- Free text questions → answer using context

## Monetisation

### Free trial
7 days, full access. No credit card required at signup.

### Subscription
$9.99/month or $79.99/year (~33% saving).

Covers: Anthropic API costs (~$3-5/user/month at Sonnet rates), CloudKit costs (negligible).

Target margin: ~50% at $9.99/month.

### What's free forever
- Onboarding
- Memory viewer
- Connection management
- One briefing per day (limited)

## Success metrics (v1)

- Day 7 retention > 60%
- Briefings opened (iMessage read receipt) > 80%
- Nudges responded to (any response) > 40%
- "Nah" rate on nudges < 30% (signal of relevance)
- Subscription conversion from trial > 20%

## Competitive positioning

| | Iris | Poppy | Lindy |
|---|---|---|---|
| Platform | iOS + Mac | iOS + Mac | Web + iMessage |
| Interaction | iMessage | iMessage | iMessage |
| Memory | Adaptive, ranked | Basic | Moderate |
| Health integration | Deep (HealthKit) | Basic | None |
| Privacy | On-device + CloudKit | Cloud | Cloud |
| Target user | Personal | Personal | Professional |
| Price | $9.99/mo | Unknown | $49.99/mo |

Iris's moat: depth of Apple ecosystem integration + adaptive memory + privacy positioning. Not trying to be Lindy (work tool). Not trying to be Poppy (surface-level). Iris knows you.

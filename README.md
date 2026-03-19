# MeetMind

**AI-Powered Meeting Intelligence & Smart Todo App**

MeetMind is a personal productivity iOS app that records your meetings, generates AI-powered summaries, tracks action items, and manages voice-first todos — all without a bot joining your call.

Built natively for iPhone and Apple Watch with SwiftUI.

---

## Features

### Meeting Recording
- **One-tap recording** — tap the big red button, start recording instantly
- **Bot-free** — records device microphone, no bot joins your Zoom/Meet/Teams call
- **Background recording** — switch apps freely during calls, recording continues
- **3-hour limit** with warning at 2h 45m
- **In-meeting notes** — Granola-style notepad to jot thoughts during the call, AI enhances them

### AI Meeting Intelligence
- **Groq Whisper** transcription (whisper-large-v3-turbo, 216x real-time)
- **Groq Llama 3.3 70B** meeting brief generation
- **Genspark-level summaries** with: Executive Summary, Strategic Direction, Key Discussion Points, Technical Details, Blockers, Risks, Decisions, Action Items
- **Key quotes extraction** with speaker attribution
- **Client/company auto-detection** from transcript context
- **Meeting templates** — 1:1, Sales Call, Interview, Standup, Discovery, Brainstorm
- **Follow-up email generation** — one-click professional email from meeting brief
- **Meeting Recipes** — 6 built-in AI prompt templates (Coach me, Prep me, Write a brief, etc.)

### Smart Todo System
- **Voice todos** — speak your task, AI extracts title + due date + priority
- **Natural language dates** — "Send report by Friday" auto-detects the date
- **Recurring tasks** — daily, weekdays, weekly, monthly
- **Inline voice recording** — record directly from the floating action bar, no extra screens
- **Auto-create from meetings** — action items where `isMine=true` become todos automatically
- **Todo notes** — tap any task to add detailed notes

### AI Chat
- **Ask about meetings** — "What action items are on me?" "What did the customer ask?"
- **Search across all meetings** — "How many tasks are related to Databricks?"
- **Per-meeting chat** — ask questions about a specific meeting's content
- **Todo-aware** — AI knows your tasks, clients, and priorities

### Organization
- **Client folders** — auto-detected from meetings, color-coded
- **People view** — track everyone you've met, meeting history per person
- **Company view** — organize by company, all participants and meetings
- **Global search** — full-text across meetings, transcripts, action items, people
- **Action item tracker** — cross-meeting view with filters (mine/others, pending/done)

### iOS Widgets
- **Quick Record** (small) — one-tap to start recording from Home Screen
- **Quick Todo** (small) — voice or text todo capture
- **Today's Tasks** (medium/large) — see pending tasks, meeting count, stats
- **Lock Screen** — circular mic icon for instant recording access

### Apple Watch
- Recording view with waveform + timer
- Todo list with completion
- Battery warning during recording
- WatchConnectivity for audio transfer

### Design
- **Modern Dark Cinema** theme — deep purple (#6C5CE7), glassmorphism, spring animations
- **Full dark mode** support — adaptive colors following system theme
- **Haptic feedback** on all interactions
- **Shimmer loading** placeholders while AI processes

---

## Tech Stack

| Component | Technology |
|-----------|-----------|
| **UI** | SwiftUI (iOS 17+) |
| **Data** | Core Data (CloudKit-ready) |
| **AI Transcription** | Groq Whisper API (whisper-large-v3-turbo) |
| **AI Intelligence** | Groq Llama 3.3 70B (chat completions) |
| **Audio** | AVFoundation (M4A, 44.1kHz, mono) |
| **Widgets** | WidgetKit + App Intents |
| **Watch** | WatchConnectivity |
| **Storage** | Keychain (API key), UserDefaults, Documents dir |
| **Background** | BGTaskScheduler, audio background mode |

---

## Setup

### Prerequisites
- Xcode 15+
- iOS 17+ device or simulator
- Groq API key (free tier: 7,200s audio/day)

### Quick Start

1. Clone the repo:
```bash
git clone https://github.com/gauravmodi09/MeetMind.git
cd MeetMind
```

2. Add your Groq API key to `MeetMind/Resources/Secrets.plist`:
```xml
<key>GROQ_API_KEY</key>
<string>your-groq-api-key-here</string>
```

3. Open in Xcode:
```bash
open MeetMind.xcodeproj
```

4. Select your device/simulator → **Cmd+R** to build and run

### Get a Groq API Key
1. Go to [console.groq.com](https://console.groq.com/keys)
2. Create an account (free)
3. Generate an API key
4. Free tier includes: 7,200 seconds of audio transcription per day (~120 hours)

---

## Project Structure

```
MeetMind/
├── App/                    # App entry point, tab navigation
├── Data/                   # Core Data models, persistence
├── DesignSystem/           # Colors, typography, components (Modern Dark Cinema)
├── Features/
│   ├── Meetings/           # Recording, briefs, detail view, templates
│   ├── Todos/              # Voice/text capture, today/upcoming/all views
│   ├── Library/            # Client folders, search, dictionary
│   ├── Chat/               # AI chat with meeting context
│   ├── People/             # People & company tracking
│   ├── Recipes/            # Meeting AI recipes
│   ├── ActionItems/        # Cross-meeting action item tracker
│   ├── Search/             # Global search
│   ├── Settings/           # API key, prompts, storage, export
│   └── Onboarding/         # Demo meeting view
├── Services/               # Groq API, recording, pipeline, sync
├── Widgets/                # Widget data models, app intents
├── WatchApp/               # Apple Watch views
└── Resources/              # Info.plist, assets, app icon
```

---

## AI Pipeline

```
Record Audio → Compress (if >24MB) → Groq Whisper → Transcript
                                                         ↓
                                              Groq Llama 3.3 70B
                                                         ↓
                                    Rich Meeting Brief (plain text, no markdown)
                                    + Structured JSON (decisions, actions, topics)
                                                         ↓
                                    Auto-create todos from action items
                                    Auto-detect client/company
                                    Store in Core Data
```

---

## Competitive Advantage

| Feature | MeetMind | Granola ($14/mo) | Otter ($17/mo) | Fireflies ($18/mo) |
|---------|:---:|:---:|:---:|:---:|
| Bot-free recording | ✓ | ✓ | ✗ | ✗ |
| iPhone native | ✓ | Web-first | ✓ | ✓ |
| Apple Watch | ✓ | ✗ | ✗ | ✗ |
| iOS widgets | ✓ | ✗ | ✗ | ✗ |
| Smart todos | ✓ | ✗ | ✗ | ✗ |
| Voice todo capture | ✓ | ✗ | ✗ | ✗ |
| Meeting recipes | ✓ | ✓ | ✗ | ✗ |
| Free personal use | ✓ | 25 free | $17/mo | $18/mo |

---

## Groq Free Tier Limits

| Resource | Daily Limit | Typical Usage |
|----------|:---:|:---:|
| Audio transcription | 7,200 seconds (~120 hours) | ~8 meetings/day |
| Chat completions | 14,400 requests | ~100 briefs/day |
| Rate limit | 30 requests/min | Sufficient for personal use |

**Cost: $0/month** within free tier for typical 5-8 meetings per day.

---

## License

Private repository. All rights reserved.

---

*Built with SwiftUI, Groq AI, and a lot of coffee.*

# MeetMind

**AI-Powered Meeting Intelligence & Smart Todo App for iOS, macOS & Apple Watch**

MeetMind is a personal productivity app that records your meetings, generates AI-powered summaries, tracks action items, and manages voice-first todos — all without a bot joining your call.

Built natively with SwiftUI for iPhone, Mac, and Apple Watch.

---

## Problem Statement

Professionals who spend significant time in meetings face two recurring pain points:

1. **Meeting chaos** — conversations go unrecorded, notes are scattered across tools, and action items fall through the cracks. By the time you sit down to write follow-up notes, half the details are gone.

2. **Todo fragmentation** — tasks captured in the moment lack structure, context, and follow-through. Voice memos sit unprocessed, sticky notes get lost, and nothing connects back to the meeting where the task originated.

Existing solutions either require bots to join your call (Otter, Fireflies), are web-first and desktop-only (Granola), or cost $14–18/month. None offer a truly mobile-native, bot-free experience with smart todo management built in.

**MeetMind solves both problems in one app** — record from your phone's microphone, get AI-generated briefs in seconds, and have action items automatically flow into your task list.

---

## Key Features

### Meeting Recording & Intelligence
- **One-tap recording** — tap the mic button, start recording instantly
- **Bot-free** — records via device microphone; no bot joins your Zoom, Meet, or Teams call
- **Background recording** — switch apps freely during calls, recording continues
- **In-meeting notepad** — Granola-style scratchpad to jot rough notes during the call; AI enhances them post-meeting
- **Groq Whisper transcription** — whisper-large-v3-turbo, 216x real-time speed
- **AI meeting briefs** — Llama 3.3 70B generates structured summaries with executive summary, key discussion points, decisions, blockers, risks, and action items
- **Key quotes extraction** with speaker attribution
- **Meeting templates** — General, 1:1, Sales Call, Interview, Standup, Discovery, Brainstorm
- **Follow-up email generation** — one-click professional email drafted from meeting brief
- **Meeting Recipes** — 6 built-in AI prompt templates (Coach me, Prep me, Write a brief, etc.)
- **3-hour recording limit** with warning at 2h 45m
- **Auto-compression** — files over 24 MB are automatically compressed; large files are chunked for the API

### Smart Todo System
- **Voice todos** — speak your task, AI extracts title + due date + priority automatically
- **Natural language dates** — "Send report by Friday" detects the date
- **Recurring tasks** — daily, weekdays, weekly, monthly
- **Inline voice capture** — record directly from the floating action bar
- **Auto-create from meetings** — action items marked as yours become todos automatically
- **Todo notes** — tap any task to add detailed notes
- **Calendar history** — track completed tasks over time
- **Today view** — focused daily task list with streaks

### AI Chat
- **Ask about meetings** — "What action items are on me?" "What did the customer ask?"
- **Cross-meeting search** — "How many tasks are related to Databricks?"
- **Per-meeting chat** — ask questions about a specific meeting's content
- **Context-aware** — AI knows your tasks, clients, and priorities

### Organization & Search
- **Client folders** — auto-detected from meeting transcripts, color-coded
- **People view** — everyone you've met with, meeting history per person
- **Company view** — organize by company with all participants and meetings
- **Global search** — full-text across meetings, transcripts, action items, and people
- **Action item tracker** — cross-meeting view with filters (mine/others, pending/done)
- **Spaces** — custom workspaces to group related meetings

### macOS Desktop App
- **Three-panel layout** — icon rail (dark sidebar) + meeting list + detail panel
- **Menu bar companion** — quick-record and recent meetings from the menu bar
- **System audio capture** — record system audio via ScreenCaptureKit (macOS)
- **Meeting app detection** — auto-detects Zoom, Teams, Meet, Slack, Webex, FaceTime
- **Native macOS design** — not an iPad app running on Mac; purpose-built for desktop

### iOS Widgets
- **Quick Record** (small) — one-tap recording from Home Screen
- **Quick Todo** (small) — voice or text todo capture
- **Today's Tasks** (medium/large) — pending tasks, meeting count, stats
- **Lock Screen** — circular mic icon for instant recording access

### Apple Watch
- **Recording view** with waveform visualization and timer
- **Todo list** with tap-to-complete
- **WatchConnectivity** for syncing with iPhone

### Authentication
- **Google Sign-In** via Firebase Authentication
- **Profile setup** with name, role, and preferences

---

## Tech Stack

| Component | Technology |
|-----------|-----------|
| **UI** | SwiftUI (iOS 17+ / macOS 14+) |
| **Data** | Core Data (CloudKit-ready) |
| **AI Transcription** | Groq Whisper API (whisper-large-v3-turbo) |
| **AI Intelligence** | Groq Llama 3.3 70B (chat completions) |
| **Audio** | AVFoundation (M4A, 44.1kHz, mono, 128kbps) |
| **macOS Audio** | ScreenCaptureKit (system audio capture) |
| **Auth** | Firebase Auth + Google Sign-In |
| **Widgets** | WidgetKit + App Intents |
| **Watch** | WatchConnectivity |
| **Storage** | Keychain (API key), UserDefaults, Documents dir |
| **Background** | BGTaskScheduler, audio background mode |

---

## AI Pipeline

```
Record Audio → Compress/Chunk (if >24MB) → Groq Whisper → Transcript
                                                              ↓
                                                   Groq Llama 3.3 70B
                                                              ↓
                                       Rich Meeting Brief (structured, no markdown)
                                       + JSON (decisions, actions, topics, quotes)
                                                              ↓
                                       Auto-create todos from action items
                                       Auto-detect client/company
                                       Store in Core Data
```

---

## Project Structure

```
MeetMind/
├── App/                        # App entry point, tab navigation
├── Core/                       # Shared components
├── Data/                       # Core Data models, persistence
├── DesignSystem/               # Colors (MMColors), typography, reusable components
├── Features/
│   ├── Meetings/               # Recording, briefs, detail view, templates, coaching
│   ├── Todos/                  # Voice/text capture, today view, calendar history
│   ├── Notes/                  # Quick notes with voice dictation
│   ├── Library/                # Client folders, insights, dictionary
│   ├── Chat/                   # AI chat with meeting context
│   ├── People/                 # People & company tracking
│   ├── Recipes/                # Meeting AI recipes (coach, prep, brief, etc.)
│   ├── ActionItems/            # Cross-meeting action item tracker
│   ├── Search/                 # Global search
│   ├── Settings/               # API key, prompt editor, storage, export, stats
│   ├── Auth/                   # Sign-in, profile setup
│   └── Spaces/                 # Custom workspaces
├── MacApp/                     # macOS-specific app
│   ├── MeetMindMacApp.swift    # macOS entry point with menu bar extra
│   ├── MacMainView.swift       # Three-panel layout
│   ├── MenuBarView.swift       # Menu bar companion
│   ├── SystemAudioCapture.swift # ScreenCaptureKit integration
│   ├── MeetingAppDetector.swift # Auto-detect Zoom/Teams/Meet
│   └── Views/                  # Mac-specific views (list, detail, todos, etc.)
├── Services/                   # Business logic
│   ├── GroqService.swift       # Groq API (Whisper + Llama)
│   ├── MeetingPipeline.swift   # End-to-end recording → brief pipeline
│   ├── AudioRecordingService.swift
│   ├── MeetingService.swift    # Meeting CRUD + processing
│   ├── TodoService.swift       # Todo management
│   ├── VoiceDictationService.swift
│   ├── CalendarService.swift   # EventKit integration
│   ├── AuthService.swift       # Firebase auth
│   └── ...                     # Analytics, export, sentiment, coaching, etc.
├── Widgets/                    # Widget data models, app intents
├── WatchApp/                   # Apple Watch views + connectivity
└── Resources/                  # Info.plist, assets, entitlements
```

---

## Setup

### Prerequisites
- Xcode 15+
- iOS 17+ device or simulator / macOS 14+
- Groq API key (free tier available)

### Quick Start

1. **Clone the repo:**
```bash
git clone https://github.com/gauravmodi09/MeetMind.git
cd MeetMind
```

2. **Add your Groq API key** — create `MeetMind/Resources/Secrets.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>GROQ_API_KEY</key>
    <string>your-groq-api-key-here</string>
</dict>
</plist>
```

3. **Open in Xcode:**
```bash
open MeetMind.xcodeproj
```

4. **Run:**
   - **iOS:** Select an iPhone simulator or device → `Cmd+R`
   - **macOS:** Select "My Mac" as destination → `Cmd+R`

### Get a Groq API Key
1. Go to [console.groq.com](https://console.groq.com/keys)
2. Create a free account
3. Generate an API key
4. Free tier: 7,200 seconds of audio/day (~120 hours), 14,400 chat requests/day

---

## Platform Support

| Platform | Status | Min Version |
|----------|--------|-------------|
| **iPhone** | Full support | iOS 17.0 |
| **iPad** | Full support | iPadOS 17.0 |
| **Mac** | Native app (not Catalyst) | macOS 14.0 |
| **Apple Watch** | Companion app | watchOS 10.0 |

---

## Competitive Advantage

| Feature | MeetMind | Granola ($14/mo) | Otter ($17/mo) | Fireflies ($18/mo) |
|---------|:---:|:---:|:---:|:---:|
| Bot-free recording | ✓ | ✓ | ✗ | ✗ |
| iPhone native | ✓ | Web-first | ✓ | ✓ |
| macOS native app | ✓ | ✓ | Web | Web |
| Apple Watch | ✓ | ✗ | ✗ | ✗ |
| iOS widgets | ✓ | ✗ | ✗ | ✗ |
| Smart todos | ✓ | ✗ | ✗ | ✗ |
| Voice todo capture | ✓ | ✗ | ✗ | ✗ |
| In-meeting notepad | ✓ | ✓ | ✗ | ✗ |
| Meeting recipes | ✓ | ✓ | ✗ | ✗ |
| System audio (Mac) | ✓ | ✓ | ✗ | ✗ |
| Menu bar companion | ✓ | ✓ | ✗ | ✗ |
| Free personal use | ✓ | 25 free | $17/mo | $18/mo |

---

## Groq Free Tier

| Resource | Daily Limit | Typical Usage |
|----------|:-----------:|:-------------:|
| Audio transcription | 7,200 seconds (~2 hours) | ~8 meetings/day |
| Chat completions | 14,400 requests | ~100 briefs/day |
| Rate limit | 30 requests/min | Sufficient for personal use |

**Cost: $0/month** within free tier for typical daily usage.

---

## License

Private repository. All rights reserved.

---

*Built with SwiftUI, Groq AI, and a lot of coffee.*

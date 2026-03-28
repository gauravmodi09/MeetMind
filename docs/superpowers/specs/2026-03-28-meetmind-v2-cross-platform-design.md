# MeetMind v2.0 — Cross-Platform Meeting Intelligence

**Date:** 2026-03-28
**Status:** Draft
**Platforms:** iPhone (P1), MacBook (P2), Windows (P3), Android (P4)

---

## Problem Statement

MeetMind currently works only when meetings happen near the iPhone microphone. When meetings happen on a laptop (Teams, Google Meet, Zoom), the audio is isolated — especially with earphones. Users must use laptop speakers and manually start iPhone recording, which is unreliable and awkward.

## Solution Overview

Transform MeetMind from a single-device iOS app into a cross-platform meeting intelligence suite. The core recording engine expands to macOS (system audio capture) and Windows (WASAPI), with all devices synced via a shared account and cloud backend. The iPhone app also gets major feature upgrades: AI notepad, voice-to-type, calendar integration, and a Granola-style chat interface.

---

## Phase 1: Onboarding + Authentication (iPhone)

### Google Sign-In
- **SDK:** Google Sign-In for iOS via SPM + Firebase Auth
- **Flow:** App launch → sign-in screen → Google OAuth → Firebase user created
- **Session:** Firebase Auth state listener auto-persists across launches. Tokens stored in Keychain via Firebase SDK.
- **"Continue without account":** Local-only mode, no sync. Upgrade to account later without data loss.

### User Profiling (Onboarding)
After sign-in, a 3-step onboarding:
1. **Microphone permission** — explanation screen ("MeetMind records meetings through your device microphone"), then system prompt
2. **Who are you?** — Role picker (Consulting, Engineering, Sales, Product, Executive, Other) + free-text description. Stored as `userProfile` in UserDefaults + Firebase user document.
3. **Your tools** — Which meeting apps? (Teams, Meet, Zoom, Slack). Meeting frequency (Daily, 3-5/week, 1-2/week).

AI uses this profile context in all prompts: "The user is a [role] who primarily uses [tools] and has [frequency] meetings."

### Data Model Changes
- `UserProfile`: role, description, meetingTools, meetingFrequency, onboardingComplete
- Firebase user document: uid, email, displayName, photoURL, profile, createdAt

### Tasks
- MM-109: Firebase Auth + Google Sign-In SDK
- MM-110: Auth UI
- MM-111: Session management
- MM-112: Onboarding flow
- MM-113: Profile settings

---

## Phase 2: AI Notepad (iPhone)

### In-Meeting Note-Taking
When recording starts, a tabbed interface appears:
- **Tab 1: Recording** — existing waveform + timer + Granola-style in-meeting notes
- **Tab 2: Notepad** — rich text editor for structured note-taking

The notepad is a lightweight editor with:
- Basic formatting: bold, bullet list, heading (H2/H3)
- Auto-save every 5 seconds to Core Data
- Keyboard-optimized: toolbar above keyboard, no distractions
- Pre-populated from template if user selected one

### AI Enhancement (Post-Meeting)
After recording ends and transcript is generated:
1. Send user's raw notes + full transcript to Groq Llama
2. AI merges them: expands bullet points with meeting context, adds missed details, structures with headings
3. **Visual distinction:** User's original text in **black**, AI-generated content in **gray** (Granola-style)
4. User can edit freely — modified AI text turns black
5. "Re-enhance" button to regenerate AI content

### Transcript-Only Mode
- After successful transcription, **delete the audio file** from disk
- Settings toggle: "Keep audio files" (default: OFF)
- Reduces storage from ~50-100MB/meeting to ~50KB (transcript + notes only)
- Show storage savings in Settings: "Saved X MB by not storing audio"

### Note Templates
Pre-built templates that structure the notepad:
| Template | Sections |
|----------|----------|
| 1:1 | Updates, Blockers, Action Items, Follow-up |
| Standup | Yesterday, Today, Blockers |
| Sales | Needs, Pain Points, Budget, Next Steps |
| Interview | Questions, Impressions, Technical Score, Culture Fit |
| Discovery | Goals, Challenges, Current Tools, Budget, Timeline |
| Brainstorm | Ideas, Pros/Cons, Decisions, Next Steps |
| Custom | User-defined sections |

### Transcript Citations
- Magnifying glass icon next to AI-enhanced text
- Tap to see exact transcript segment supporting each point
- Timestamp + highlighted text from transcript
- Builds trust in AI output

### Tasks
- MM-114: Notepad UI
- MM-115: AI enhancement
- MM-116: Transcript-only mode
- MM-117: Note templates
- MM-118: Transcript citations

---

## Phase 3: Voice-to-Type (iPhone)

### Technology Choice
**Primary:** Apple SpeechAnalyzer (iOS 26+)
- On-device, private, optimized for meetings/conversations
- Volatile results (fast preview) + final results (accurate)
- Automatic language detection
- Falls back to `SFSpeechRecognizer` on iOS 17-25

**Post-processing:** Groq Llama for AI cleanup
- Remove filler words (um, uh, like, you know)
- Fix grammar and punctuation
- Smart formatting (paragraphs, lists)

### Integration Points
1. **AI Notepad** — mic button in toolbar, dictate notes hands-free
2. **Todo input** — mic button in todo text field
3. **Search** — voice search across meetings

### UX
- Tap mic button → pulsing waveform indicator
- Text appears in real-time (volatile results)
- Brief "Cleaning up..." animation after dictation ends
- Cleaned text replaces raw with subtle highlight
- "Undo cleanup" option to revert to raw

### Tasks
- MM-119: SpeechAnalyzer integration
- MM-120: AI text cleanup
- MM-121: Inline in todo + search

---

## Phase 4: Calendar Integration (iPhone)

### Google Calendar API
- Add `calendar.readonly` scope to Google Sign-In
- Fetch upcoming meetings (next 24h) on app launch + background refresh
- Store locally for offline: event title, time, duration, participants, meeting link

### Home Screen Integration
- "Upcoming" section showing next 3-5 calendar meetings
- Each card: title, time, participant avatars, "Start Recording" button
- Tapping "Start Recording" pre-fills: meeting title, client (from participants), template

### Pre-Meeting Context
- Before a meeting, show context card: "You last met with [person] on [date]"
- Key topics from past meetings with this contact
- Open action items assigned to/from this person
- Powered by Groq Llama summarizing meeting history

### Smart Recording Prompt
- Local notification when calendar meeting starts
- Configurable: 1 min before, at start, or disabled
- If app is open: banner with "Start Recording" button

### Tasks
- MM-122: Google Calendar API setup
- MM-123: Calendar UI on home screen
- MM-124: Pre-meeting context
- MM-125: Smart recording prompt

---

## Phase 5: Enhanced Chat UI (iPhone)

### "Ask Anything" Interface
Granola-style chat experience:
- Top of home screen: chat input bar ("Transcribe a meeting to start asking questions")
- Tabs: "My notes" | "All meetings"
- Full-screen chat view when typing
- AI searches across all transcripts + briefs via embedding search
- Conversational responses with inline citations linking to source meetings
- Model badge in chat input (e.g., "Llama 3.3 70B")

### Recipes
Saved prompt templates that run across meeting data:
- **Built-in:** List recent todos, Write weekly recap, Prep me for [person], Find blind spots, Streamline my calendar, Coach me
- **Custom:** Users create their own recipes
- **Invocation:** Type "/" in chat to see recipe picker
- **Display:** Recipe buttons grid below chat bar (like Granola's UI)
- Each recipe: icon (color-coded), title, description

### Spaces
Named collections for organizing meetings:
- Default: "My Notes" (all personal meetings)
- Custom: "Client A", "Hiring", "Product Roadmap"
- Sidebar navigation with space list
- Chat is scoped to selected space
- Move meetings between spaces
- Color-coded space icons

### Tasks
- MM-126: Chat UI
- MM-127: Recipes
- MM-128: Spaces
- MM-129: Model selection
- MM-130: Enhanced home screen

---

## Phase 6: macOS Desktop App

### Architecture
- **Shared code:** Core Data model, GroqService, MeetingPipeline, data models shared via Swift Package between iOS and macOS targets
- **macOS target:** macOS 14+ deployment, native SwiftUI
- **App type:** Menu bar app (always accessible) + main window (full UI)

### System Audio Capture (ScreenCaptureKit)
The core innovation for desktop:
- **API:** ScreenCaptureKit `SCStream` with audio-only configuration
- **Captures:** Both system audio output (what you hear) AND microphone input (what you say)
- **Permission:** "Screen & System Audio Recording" (macOS Privacy settings)
- **Earphone support:** Captures at OS level — works regardless of audio output device
- **Meeting app agnostic:** Works with Teams, Zoom, Meet, Slack, Webex, any audio source

### Menu Bar UI
- MeetMind mic icon in menu bar
- Popover: recording status, start/stop, current meeting, waveform
- Icon pulses purple when recording
- **Global hotkey:** CMD+Shift+R to toggle recording

### Main Window
- Sidebar: Spaces, upcoming meetings (calendar)
- Detail: Meeting library, briefs, AI notepad, chat
- Reuses SwiftUI views from iOS where possible
- macOS-native: toolbar, sidebar, NSSplitView

### Meeting App Detection
- NSWorkspace monitoring for Teams, Zoom, Meet, Slack
- Detect when a meeting is active (audio session, window title)
- Auto-prompt: "Meeting detected — Start recording?"
- Auto-stop when meeting ends
- Calendar event matching for context

### Tasks
- MM-131: Xcode project + shared code
- MM-132: ScreenCaptureKit audio capture
- MM-133: Menu bar UI
- MM-134: Full meeting window
- MM-135: Meeting app detection
- MM-136: Shared auth

---

## Phase 7: Cross-Platform Sync

### Firebase Firestore
- Collections: `users/{uid}/meetings`, `users/{uid}/todos`, `users/{uid}/clients`, `users/{uid}/spaces`
- Real-time listeners on both iOS and macOS
- Offline persistence enabled (Firestore cache)
- Conflict resolution: last-write-wins with `updatedAt` timestamp

### Migration Strategy
- Existing Core Data remains as local cache
- FirestoreDataService wraps Core Data + Firestore
- On first sync: upload all local Core Data to Firestore
- Subsequent: Firestore is source of truth, Core Data is cache

### Sync Behavior
- Meeting recorded on Mac → appears on iPhone within seconds
- Todo completed on iPhone → marked done on Mac
- Notes edited during meeting → synced in real-time
- Push notification to other device when new meeting processed

### Tasks
- MM-137: Firestore setup
- MM-138: Core Data migration
- MM-139: Real-time meeting sync
- MM-140: Todo and note sync

---

## Phase 8: Windows + Android (Lower Priority)

### Windows Desktop (Tauri)
- **Framework:** Tauri 2.0 (Rust backend + web frontend)
- **Audio:** WASAPI loopback capture (Windows equivalent of ScreenCaptureKit)
- **UI:** System tray icon + main window, web-based UI
- **Auth:** Firebase Auth (web SDK)
- **Sync:** Firestore (web SDK)

### Android
- **Framework:** Kotlin + Jetpack Compose
- **Audio:** Android AudioRecord API with AAC encoding
- **Voice-to-type:** Android SpeechRecognizer
- **Auth:** Firebase Auth (Android SDK)
- **Sync:** Firestore (Android SDK)
- **Design:** Material Design 3 with MeetMind purple theme

### Tasks
- MM-141 to MM-146

---

## Technical Architecture

```
                    ┌─────────────────┐
                    │   Firebase Auth  │
                    │  (Google Sign-In)│
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
        ┌─────┴─────┐ ┌─────┴─────┐ ┌─────┴─────┐
        │  iPhone    │ │  macOS    │ │ Windows   │
        │  (SwiftUI) │ │ (SwiftUI) │ │ (Tauri)   │
        └─────┬─────┘ └─────┬─────┘ └─────┬─────┘
              │              │              │
        ┌─────┴─────┐ ┌─────┴──────┐ ┌────┴──────┐
        │AVFoundation│ │ScreenCapKit│ │  WASAPI   │
        │   (mic)    │ │(sys audio) │ │(loopback) │
        └─────┬─────┘ └─────┬──────┘ └────┬──────┘
              │              │              │
              └──────────────┼──────────────┘
                             │
                    ┌────────┴────────┐
                    │   Groq API      │
                    │ Whisper + Llama │
                    └────────┬────────┘
                             │
                    ┌────────┴────────┐
                    │ Firebase        │
                    │ Firestore Sync  │
                    └─────────────────┘
```

## Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Desktop audio capture | ScreenCaptureKit (macOS) | Granola uses this. No bot, works with earphones, OS-level capture |
| Auth provider | Firebase + Google Sign-In | Cross-platform, free tier generous, handles sessions |
| Cloud sync | Firebase Firestore | Real-time listeners, offline support, works on all platforms |
| Voice-to-type | Apple SpeechAnalyzer | On-device, private, newest API optimized for meetings |
| Windows framework | Tauri | Lighter than Electron, Rust backend, native feel |
| Transcript storage | Delete audio after transcription | Massive storage savings, privacy-friendly |
| Note enhancement | Groq Llama 3.3 70B | Already in pipeline, two-pass: merge notes + structure |

## Risk Considerations

| Risk | Mitigation |
|------|-----------|
| ScreenCaptureKit permission UX (macOS) | Clear onboarding explaining why permission is needed |
| SpeechAnalyzer requires iOS 26+ | Fallback to SFSpeechRecognizer for iOS 17-25 |
| Firestore costs at scale | Compress transcripts, batch writes, monitor usage |
| Windows audio capture complexity | WASAPI is well-documented, Tauri has audio crate support |
| Cross-platform UI consistency | Shared design system, platform-native components |

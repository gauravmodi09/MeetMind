# MeetMind macOS Desktop App — Design Spec

## Goal

Redesign the MeetMind macOS app with a three-panel power-user layout (icon rail + list + detail), Speakly-inspired clean theme, full feature parity with iOS, and menu bar companion for quick recording.

## Architecture

Three-panel NavigationSplitView replacing the existing `MacMainView.swift`. Dark icon rail on the left, light gray list panel in the middle, white detail panel on the right. Menu bar extra provides quick-access recording without switching apps. Existing services (`MeetingService`, `AudioRecordingService`, `SystemAudioCapture`, `MeetingAppDetector`, `GroqService`, `MeetingPipeline`) are reused as-is.

## Layout Structure

### Icon Rail (56px wide, `#1a1a2e` dark background)

- **App icon** at top (MeetMind logo, `#6C5CE7` background, 32×32)
- **6 navigation items** below, each 36×36 with icon + tiny label:
  1. Meetings (📋) — list of all recordings with AI summaries
  2. Todos (✅) — action items extracted from meetings
  3. Notes (📝) — quick notes
  4. Library (📚) — meeting insights and analytics
  5. Chat (💬) — AI chat about meetings
  6. Settings (⚙️) — app configuration
- **Active state**: `rgba(108,92,231,0.25)` background, white text
- **Inactive state**: `rgba(255,255,255,0.06)` background, `rgba(255,255,255,0.4)` text
- Settings pinned to bottom with `margin-top: auto`

### List Panel (240px wide, `#f8f8fa` background)

- **Header**: Section title + action button (e.g., "+" for new recording)
- **Search bar**: Rounded input with magnifying glass placeholder
- **Date grouping**: "Today", "Yesterday", "This Week", etc. as section headers
- **Meeting rows**: White cards with rounded corners (10px), showing:
  - Title (13px, semibold)
  - Metadata line: time, duration, action item count (11px, gray)
  - Green dot for completed, amber for processing
- **Selected state**: 2px purple (`#6C5CE7`) border
- Content changes based on active icon rail section

### Detail Panel (flexible width, white background)

- **Header**: Meeting title (20px bold) + Export/Share buttons
- **Metadata**: Date, time, duration, template type, status indicator
- **Tab bar** (underline style, not pills):
  - Summary (default) — key points, decisions, action items preview
  - Transcript — full raw transcript, text selectable
  - Action Items — checkable list with owner and due date
  - Notes — editable notepad content
  - AI Chat — chat interface for asking questions about this meeting
- Active tab: purple text + 2px purple bottom border
- Content scrollable independently

## Recording Experience

### Recording View (replaces detail panel during recording)

- Centered layout with:
  - Large stop button (80px circle, red `#EF4444`)
  - Timer display (36px monospace font)
  - "● Recording — {meeting title}" status text in red
  - Audio source selector: toggle between "🖥 System Audio" and "🎙 Microphone"
    - System Audio uses `SystemAudioCapture.swift` (ScreenCaptureKit)
    - Microphone uses `AudioRecordingService.swift` (AVAudioRecorder)
  - When a meeting app is detected (via `MeetingAppDetector`), show app name: "Capturing: Zoom Meeting"
  - Waveform visualization showing real-time audio levels
  - Pause and "Stop & Process" buttons

### Auto-Detection

- `MeetingAppDetector` monitors for Zoom, Teams, Meet, Slack, Webex, FaceTime
- When detected: auto-suggest starting a recording (notification or menu bar alert)
- Default to System Audio when a meeting app is active, Mic otherwise

## Menu Bar Companion

### Menu Bar Extra (280px wide popover)

- **Header**: Purple gradient (`#6C5CE7` → `#a855f7`), "MeetMind" branding, status text
- **Quick actions**: Two buttons side by side:
  - "🎙 Record Mic" — purple background
  - "🖥 System Audio" — dark background
- **During recording**: Replace buttons with red stop button + timer
- **Recent meetings**: Last 3 meetings with title and relative time
- **Footer**: "Open MeetMind" link (purple) + "Quit" (gray)

## Sections Detail

### Meetings

- **List panel**: All meetings grouped by date, searchable
- **Detail panel**: Tabbed view (Summary, Transcript, Action Items, Notes, AI Chat)
- Maps to existing `MeetingService.shared.meetings`

### Todos

- **List panel**: All action items from all meetings, filterable by status (pending/completed)
- **Detail panel**: Todo details with source meeting link, owner, due date, completion toggle
- Maps to existing `TodoService.shared`

### Notes

- **List panel**: Quick notes list, searchable
- **Detail panel**: Rich text editor for note content
- Maps to existing quick notes functionality

### Library

- **List panel**: Categories — All Meetings, By Template, By Client, Insights
- **Detail panel**: Analytics dashboard or filtered meeting list
- Reuses existing meeting data with computed stats

### Chat

- **List panel**: Recent chat sessions (one per meeting)
- **Detail panel**: Chat interface — message bubbles, text input, send button
- Reuses existing `MeetingChatView` logic / `GroqService`

### Settings

- **No list panel** — detail panel takes full width (icon rail + detail only)
- Sections: Account, AI & Processing, Recording, Storage, About
- Maps to subset of iOS settings relevant to macOS

## Theme & Colors

| Element | Color |
|---------|-------|
| Icon rail background | `#1a1a2e` |
| List panel background | `#f8f8fa` |
| Detail panel background | `#ffffff` |
| Primary / accent | `#6C5CE7` (MMColors.primary) |
| Success / complete | `#10B981` |
| Recording / danger | `#EF4444` |
| Warning / processing | `#F59E0B` |
| Text primary | `#1a1a2e` |
| Text secondary | `#888888` |
| Text tertiary | `#999999` |
| Border / separator | `#e5e7eb` |
| Card background | `#ffffff` |
| Card selected border | `#6C5CE7` (2px) |

## Window Configuration

- Default size: 900×600
- Minimum size: 700×450
- Title bar: Standard macOS style (traffic lights)
- Resizable: Yes, all three panels adjust
- Icon rail: Fixed 56px
- List panel: 200–300px range
- Detail panel: Fills remaining space

## File Structure

### New/Modified Files

```
MeetMind/MacApp/
├── MeetMindMacApp.swift          — modify (add menu bar companion)
├── MacMainView.swift             — rewrite (three-panel layout)
├── MenuBarView.swift             — rewrite (new design)
├── Views/
│   ├── MacIconRail.swift         — new (icon rail navigation)
│   ├── MacListPanel.swift        — new (list panel with section switching)
│   ├── MacDetailPanel.swift      — new (detail view router)
│   ├── MacMeetingDetail.swift    — new (tabbed meeting detail)
│   ├── MacRecordingView.swift    — new (recording UI with source toggle)
│   ├── MacTodosView.swift        — new (todos list + detail)
│   ├── MacNotesView.swift        — new (notes list + detail)
│   ├── MacLibraryView.swift      — new (library/analytics)
│   ├── MacChatView.swift         — new (AI chat)
│   └── MacSettingsView.swift     — new (settings)
├── MeetingAppDetector.swift      — keep as-is
└── SystemAudioCapture.swift      — keep as-is
```

### Reused Services (no changes)

- `MeetingService.swift`
- `AudioRecordingService.swift`
- `MeetingPipeline.swift`
- `GroqService.swift`
- `TodoService.swift`
- `MeetMindModels.swift`
- `PersistenceController.swift`
- `MMColors.swift`

## Out of Scope

- Dark mode toggle (stick with light theme for now)
- Drag-and-drop audio file import
- Multi-window support
- Global keyboard shortcuts for recording
- Touch Bar support

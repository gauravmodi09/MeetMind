# MeetMind v1.0 — Design Spec

> **Date:** March 18, 2026
> **Goal:** Build the core meeting intelligence + smart todo iOS app with Apple Watch companion

## Architecture
- **Platform:** iOS 17+ (SwiftUI), watchOS 10+ (SwiftUI)
- **Data:** Core Data with CloudKit (iCloud sync)
- **AI:** Groq API — Whisper large-v3-turbo (transcription) + Llama 3.3 70B (intelligence)
- **Audio:** AVFoundation (M4A, 44.1kHz, mono)
- **Widgets:** WidgetKit + App Intents
- **Storage:** Local Documents dir, Keychain for API key

## Design System
- Primary: #6C5CE7 (purple)
- Success: #00CE9E (green)
- Recording: #FF4757 (red)
- Warning: #FFA502 (gold)
- Info: #2D98FF (blue)
- Background: #F8F7FC (light purple tint)
- Text: #1A1A2E (dark), #6B7280 (secondary)
- Font: SF Pro (system), DM Sans for marketing
- Dark mode from day 1

## Core Screens
1. **Meetings tab** — recording button + meeting list + processing status
2. **Todos tab** — voice/text capture + today/upcoming/all views
3. **Library tab** — by-client folder grid + search
4. **Settings tab** — API key, recording prefs, AI prompt, storage

## Key Flows
- Record → Compress → Whisper → Llama → Brief + Auto-todos
- Voice todo → Whisper → Llama date parse → Confirm → Save
- Copy brief → Clipboard (one tap, formatted for email)

*Spec approved by user. 67 tasks in tracker. Ready for implementation.*

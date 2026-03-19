📱

MEETMIND

AI-Powered Meeting Intelligence & Smart Todo App

BUSINESS REQUIREMENTS DOCUMENT (BRD)

1. Executive Summary

MeetMind is a personal productivity iOS application designed for professionals who spend significant time in meetings, client calls, and day-to-day coordination activities. Built natively for iPhone and Apple Watch, MeetMind solves two core problems that plague busy consultants, data engineers, and enterprise professionals:

Meeting chaos — conversations go unrecorded, notes are scattered, and action items fall through the cracks

Todo fragmentation — tasks captured in the moment lack structure, context, and follow-through

The app is inspired by the elegance and intelligence of Granola AI — the leading meeting notes app praised by thousands of professionals — and extends that concept into a personal, mobile-first, dual-purpose productivity suite.

At its technical heart, MeetMind uses the Groq API (Whisper Large v3 Turbo for transcription, Llama 3.3 70B for intelligence) — providing near-instantaneous audio processing and zero cost during development. The entire AI pipeline is API-key driven, meaning Gaurav can plug in his own Groq key and run the full stack for free within generous free-tier limits.

2. Problem Statement & Opportunity

2.1 The Core Problems

The following pain points have been identified for the primary user (Gaurav) and similar enterprise professionals:

2.2 Market Validation

Granola AI — the closest product reference — raised $43M at a $250M valuation in May 2025 and grew 10% week-over-week purely via word of mouth. Its App Store rating is exceptional. The demand for elegant, AI-powered meeting capture is proven. MeetMind differentiates by being:

Personal-first — built for one person's workflow, not a team product

Mobile-native — optimized for iPhone and Apple Watch recording

Client-aware — automatically organizes notes by detected customer/company name

Free to run — leveraging Groq's generous free API tier vs. Granola's $18/month

3. Product Vision & Goals

3.1 Vision Statement

3.2 Design Philosophy

The app takes deep inspiration from Granola AI's acclaimed UX approach:

Minimal surface area — one big button to start, everything else is automatic

Human notes + AI enhancement — you can jot a few words; AI fills in the structure

Post-meeting polish — notes get reformatted, enriched, and intelligently categorized after the call ends

Instant sharing — one tap to copy a clean, formatted summary for email or message

No bot intrusion — recording happens directly from device mic; no bot joins the call

3.3 Strategic Goals

4. Scope & Boundaries

4.1 In Scope — Version 1.0

iPhone app (iOS 17+) with native SwiftUI interface

Apple Watch companion app (watchOS 10+) with recording widget

iOS Home Screen and Lock Screen widgets for one-tap recording start/stop

Audio recording via AVFoundation with background recording support

Audio upload to Groq Whisper API for transcription

AI-powered meeting note structuring via Groq Llama 3.3 70B

Client/company name detection and automatic folder routing

Meeting library organized by date and client folder

One-tap copy-to-clipboard of formatted meeting brief

Voice-to-todo capture (via Groq Whisper + date parser)

Text-based todo entry with date tagging

Daily todo list view with completion tracking

iCloud sync across iPhone and Apple Watch

4.2 Out of Scope — Version 1.0

Android version

Web application

Calendar integration (planned v1.1)

Real-time transcription during call (post-call processing only in v1.0)

Team sharing / collaboration features

CRM integrations (HubSpot, Salesforce)

Video recording

Speaker diarization (who said what)

5. Functional Requirements

FR-01: Audio Recording Engine

5.1.1 iPhone Recording

The app shall use AVFoundation's AVAudioRecorder to capture microphone audio

Audio format: M4A (AAC codec), 44.1kHz, mono, high quality setting

The app shall request microphone permission on first launch with a clear explanation

Recording shall continue in the background when app is minimized (using BackgroundMode: audio in Info.plist)

The app shall handle interruptions gracefully (incoming call, Siri activation) — pause and resume recording

Maximum recording duration per session: 3 hours

Files are stored locally in the app's Documents directory until upload completes

5.1.2 Apple Watch Recording

A native watchOS app shall provide a simple Record / Stop interface

Watch shall use WKAudioRecorderPreset for microphone access

After recording stops, audio file is transferred to iPhone via WatchConnectivity framework

iPhone receives the file and queues it for transcription automatically

Watch UI shall show: recording waveform animation, elapsed time, and battery warning if < 10%

5.1.3 Widget Support

Lock Screen Widget: A compact widget showing a microphone icon and "Tap to Record" label — tapping opens MeetMind and auto-starts recording

Home Screen Widget (Small): Shows today's meeting count and a Record button

Home Screen Widget (Medium): Shows today's meeting count, last meeting title, and Record + Todo buttons

Widgets shall use WidgetKit with App Intents for deep-link recording start

FR-02: AI Transcription Pipeline

5.2.1 Transcription via Groq Whisper

After recording stops (or when a Watch audio file is received), the app shall:

Compress audio to M4A if larger than 24MB (Groq free tier limit: 25MB)

Upload audio file to Groq API endpoint: POST /openai/v1/audio/transcriptions

Model: whisper-large-v3-turbo (fastest, 216x real-time speed factor)

Request response format: verbose_json (includes word-level timestamps)

Parse transcript text from the JSON response

Store raw transcript alongside the recording metadata in local database (Core Data)

5.2.2 Meeting Intelligence via Groq Llama

After transcription, the app shall call Groq's chat completions API with a structured prompt to generate a polished meeting brief. The AI model shall extract and format:

The AI prompt shall include explicit instructions to:

Detect and highlight the primary client or company name for folder routing

Use professional, concise language suitable for direct email sharing

Flag any commitments made ("I will...", "We will...", "By next week...")

Mark unclear or inaudible sections with [unclear] rather than hallucinating content

FR-03: Meeting Library & Organization

5.3.1 Folder Structure

The library shall organize meetings in a two-dimensional structure:

5.3.2 Client Detection Logic

The Groq LLM response shall include a JSON field: "client_name" with the detected company/customer name

If no client is detected, meeting is filed under "General" folder

User can manually correct or reassign client name by long-pressing a meeting card

Client name correction triggers immediate re-filing to the correct folder

The app maintains a client dictionary (user-editable) for improved detection accuracy over time

5.3.3 Meeting Card Display

Each meeting in the library shall display a card showing:

Meeting title (AI-generated)

Client folder tag (color-coded badge)

Date and time recorded

Duration

Number of action items

Quick action buttons: Copy Brief | View Full | Share

FR-04: Meeting Brief — Copy & Share

5.4.1 Formatted Brief Output

The "Copy Brief" action shall copy a clean, formatted text block to clipboard, ready to paste into email, Slack, or WhatsApp. The format shall be:

5.4.2 Share Options

Copy to Clipboard (primary action — one tap)

Share Sheet — opens native iOS share sheet to send via Mail, Messages, WhatsApp, Slack, etc.

Export as plain text file (.txt)

FR-05: Smart Todo System

5.5.1 Voice Todo Capture

A prominent microphone button on the Todo tab allows voice input

The app records a short voice note (max 2 minutes) and sends it to Groq Whisper for transcription

The transcribed text is then parsed by Groq Llama for: task description, assignee (self by default), and target date

Example: "remind me to send the Databricks cost report to Maulik by Thursday" → Task: "Send Databricks cost report to Maulik" | Date: Thursday 20 March 2026

If no date is mentioned, task is assigned to "Today" by default

User can review and confirm the extracted task before saving

5.5.2 Text Todo Entry

A text input field allows typing todos directly

Date picker defaults to today; user can change to any future date

Optional priority flag: Low / Medium / High

Optional client tag to link a todo to a client folder

5.5.3 Todo List Views

Today View — all tasks due today, sorted by priority

Upcoming View — tasks for the next 7 days, grouped by day

All Tasks — full list with filter by client tag and date range

Swipe left to complete a task (green checkmark animation)

Swipe right to reschedule (date picker appears inline)

Completed tasks are moved to a "Done" section at the bottom, collapsed by default

5.5.4 Watch Todo Widget

Apple Watch complication shows today's pending task count

Tapping opens a scrollable todo list on the watch face

Tasks can be marked complete directly from the watch with a haptic confirmation

6. Non-Functional Requirements

7. Technical Architecture

7.1 Technology Stack

7.2 AI Pipeline Flow

7.3 Groq API Integration Details

Transcription Endpoint

URL: https://api.groq.com/openai/v1/audio/transcriptions

Method: POST multipart/form-data

Key parameters: model=whisper-large-v3-turbo, response_format=verbose_json, language=en

Rate limit (free tier): 7,200 seconds of audio per day (~120 hours) — more than sufficient for personal use

Chat Completions Endpoint

URL: https://api.groq.com/openai/v1/chat/completions

Method: POST application/json

Model: llama-3.3-70b-versatile

System prompt: Custom meeting analyst prompt (stored in app bundle, user-editable)

Response format: JSON schema with strict validation

Temperature: 0.2 (consistent, factual output)

Max tokens: 1500 (sufficient for full meeting brief)

API Key Management

User enters Groq API key in Settings screen on first launch

Key stored in iOS Keychain using kSecAttrService = "com.meetmind.groq"

Key never logged, transmitted, or stored in Core Data

App gracefully prompts for key re-entry if Keychain lookup fails

8. User Experience Design

8.1 Screen Architecture

8.2 Widget Specifications

8.3 Key UX Principles Adopted from Granola

One-tap start — recording begins the moment the widget is tapped, no menus or setup

Post-meeting enhancement — AI structures notes AFTER the call, not during, reducing any real-time latency impact

Your words first — user can add notes during recording (text field overlay); AI completes and enhances, never replaces

Instant readability — brief is formatted for zero editing before sharing

Progressive disclosure — brief view shows summary by default; full transcript available on expand

9. Requirements Traceability Matrix

10. Delivery Roadmap

Sprint 1 — Core Engine (Weeks 1–2)

Project setup: Xcode workspace, iOS + watchOS targets, Core Data model

Groq API key onboarding screen with Keychain storage

AVFoundation recording engine — record, pause, stop, save to disk

Groq Whisper integration — upload and transcribe

Groq Llama integration — parse transcript to structured meeting JSON

Basic meeting library — list view by date

Meeting brief screen — display formatted brief

Copy Brief to clipboard

Basic text todo entry + Today view

Sprint 2 — Platform Depth (Weeks 3–4)

Apple Watch app — recording UI, WatchConnectivity transfer

WidgetKit — Lock Screen widget + Home Screen small/medium

App Intents for widget-to-app deep linking

Client folder system — auto-create from Llama JSON output

By-client library view — folder grid

Voice todo capture — Groq Whisper + date parser

Share sheet integration for meeting brief

Offline queue — record without internet, transcribe when connected

Sprint 3 — Polish & Power Features (Weeks 5–6)

Onboarding flow — 3-screen tour + API key setup

Manual client name correction with re-filing

Client dictionary — user-editable for improved detection

Upcoming todo view — weekly calendar strip

Watch todo complication

Settings screen — recording quality, AI prompt style, auto-delete prefs

Performance optimization — transcription queue, background BGTask

App icon, launch screen, and final UI polish

Sprint 4 — Testing & App Store Prep (Week 7–8)

End-to-end testing on physical iPhone + Apple Watch

Edge case handling: large files, network failures, API rate limits

Accessibility audit — VoiceOver, dynamic type

App Store screenshots (6.7" + Apple Watch)

Privacy policy and App Store description

TestFlight beta deployment

App Store submission

11. Risk Register

12. Success Metrics & KPIs

Personal Usage Targets (Month 1)

Every client meeting recorded without manual setup: 100% capture rate

Brief ready and shareable within 20 seconds of hanging up

Zero meetings filed in wrong client folder without correction

All daily todos captured (voice or text) before 9am

No manual reformatting required before forwarding a meeting brief via email

Technical Benchmarks

Transcription accuracy: < 15% WER on clear audio in office environments

Brief generation time: < 20 seconds end-to-end (upload + transcribe + structure)

App crash rate: < 0.5% of recording sessions

Groq API cost: $0/month within free tier for typical 5–8 meetings/day

13. Appendix

A. Competitive Landscape

B. Groq API Quick Reference

Console: https://console.groq.com

Transcription: POST https://api.groq.com/openai/v1/audio/transcriptions

Chat: POST https://api.groq.com/openai/v1/chat/completions

Auth header: Authorization: Bearer {GROQ_API_KEY}

Whisper models: whisper-large-v3 (most accurate) | whisper-large-v3-turbo (fastest, recommended)

Chat model: llama-3.3-70b-versatile (best free-tier model for structured output)

Free tier: Audio — 7,200 sec/day; Chat — 30 req/min, 14,400 req/day

C. Core Data Schema (v1.0)

D. AI System Prompt Template

E. Glossary

MeetMind BRD v1.0 — Confidential | March 2026 | Built for Gaurav's Daily Workflow


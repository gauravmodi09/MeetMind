# MeetMind — Enhanced 3D Immersive Landing Page Brief

---

## ACT AS:
A world-class Awwwards-level Creative Developer and Brand Experience Director specializing in ultra-premium web design, Three.js 3D product interactions, GSAP scroll-driven storytelling, and cinematic brand experiences. You build experiences that win Site of the Day — not templates, not generic AI output, but handcrafted digital cinema.

## THE TASK:
Design and implement a **3D immersive scroll-driven walkthrough** of MeetMind — an AI-powered meeting intelligence app for iPhone, Mac, and Apple Watch. The experience should feel like the user is **walking through the app itself** — each scroll beat reveals a new app screen floating in 3D space, with the UI elements coming alive through animation, parallax, and cinematic lighting.

**Core mechanic:** As the user scrolls, they fly through a 3D particle universe. At each stop, a full-size app screen materializes in 3D perspective — tilted, lit, and animated — showing exactly what MeetMind does. Text copy appears beside each screen explaining the feature. The screens transition with depth, rotation, and crossfade effects, creating stickiness and curiosity.

**This is NOT a feature list. This is an experience.**

---

## VISUAL DIRECTION

### The Feeling:
- Like flying through a digital galaxy where each star is a piece of meeting intelligence
- Like Apple's iPhone product page meets Stripe's interactive demos meets a cinematic movie trailer
- Warm-dark luxury: not cold corporate, but confident and human

### Color Palette:
| Token | Value | Usage |
|-------|-------|-------|
| `--void` | `#050507` | Primary background, matches Three.js scene |
| `--void-alt` | `#0A0A10` | Glass card backgrounds |
| `--violet` | `#7C3AED` | Primary brand accent |
| `--teal` | `#14F0C5` | Success, AI intelligence |
| `--coral` | `#FF6B6B` | Recording, urgency |
| `--amber` | `#FBBF24` | Todos, productivity |
| `--white` | `#F8F8FC` | Headings |
| `--grey` | `#9CA3AF` | Body text |

### Typography:
| Role | Font | Weight | Usage |
|------|------|--------|-------|
| Display | Instrument Serif | 400 | Headlines, dramatic statements |
| Body | Space Grotesk | 300-600 | Copy, labels, UI text |
| Mono | JetBrains Mono | 400-500 | Stats, technical labels, badges |

### 3D & Lighting:
- Three.js particle universe (400 particles, additive blending)
- Particles shift color with scroll progress (violet → coral → teal → amber → violet)
- Soft ambient glow behind each app screen
- Film grain overlay for cinematic texture
- Perspective transforms on app screens: `perspective(1200px) rotateY(±8deg) rotateX(-3deg)`

---

## THE 3D APP SCREEN WALKTHROUGH

### Architecture:
Each "stop" on the scroll journey shows a **3D floating app screen** — a CSS-rendered phone/tablet frame with actual UI content inside. The screens are pinned during scroll, with content animating in/out as the user progresses.

### Screen Construction:
- **Phone frame:** CSS with realistic border-radius, notch, border glow
- **Screen content:** HTML/CSS recreating the actual MeetMind UI
- **3D transform:** Each screen enters from a different angle, creating depth
- **Ambient glow:** Colored gradient orb behind each screen matching the feature's accent color
- **Floating labels:** Small glass badges around the screen calling out specific UI elements

---

## SCROLL SECTIONS (4 Frames, ~850vh total)

### FRAME 1: THE VOID (0-20% scroll) — Hero + Problem
**Height:** 200vh (pinned for dramatic entrance)

**Visual:**
- Pure void. Particle universe drifting slowly in violet.
- No app screens yet — just text and atmosphere.
- Subtle radial gradient glow behind headline.
- Floating chaos elements: scattered SVG icons (calendar, sticky note, speech bubble, question mark) drifting apart — representing meeting chaos.

**Copy:**
```
[mono label] THE PROBLEM NOBODY SOLVES

[display-xl headline]
Your meetings
disappear the moment
they end.

[body]
Decisions evaporate. Action items scatter across five apps.
By tomorrow, you'll remember none of it.

[scroll cue]
Scroll to see what changes everything.
```

**On continued scroll (pain stats fade in):**
```
73% — of action items forgotten within 24 hours
31h — wasted per month in unproductive meetings
5+ — apps used to track one meeting's output
```

**Transition:** Chaos elements dissolve. Particles begin shifting from violet to teal. A glow appears center-screen.

---

### FRAME 2: THE PRODUCT (20-55% scroll) — App Screen Walkthrough
**Height:** 300vh (pinned, multiple sub-beats)

This is the centerpiece. A single phone floats center-screen, and as the user scrolls, the phone's screen content transitions through 5 key app states. Copy appears beside the phone (alternating left/right) describing each state.

**Sub-beat 2A: Pivot (20-25%)**
- Screen: Black/empty
- Copy (centered): *"What if one tap could capture everything?"*
- Particles shift to near-black, then teal begins to emerge

**Sub-beat 2B: Recording Screen (25-33%)**
- Phone materializes from below with ease-out
- Screen shows: Recording UI
  - Red pulsing "RECORDING" badge with dot
  - Timer: "14:32"
  - Live waveform visualization (12 animated bars)
  - Meeting type pills: General, Standup, Sales, Customer
  - Large red mic button with glow
  - Minimized transcript peek at bottom
- Copy (LEFT):
  ```
  [display] Tap. Record. Done.

  [body] No bot joins your Zoom, Meet, or Teams call.
  Just your microphone — recording in the background
  while you stay focused on the conversation.

  [teal accent] Background recording · 3hr limit · Real-time transcription
  ```
- Ambient glow: coral (recording energy)
- Floating labels around phone: "No bots" (top-right), "Background mode" (bottom-left)

**Sub-beat 2C: AI Processing → Meeting Brief (33-42%)**
- Phone screen crossfades to: Processing pipeline steps → then Brief
- Brief screen shows:
  - "AI MEETING BRIEF" header in teal
  - Meeting title: "Q1 Product Strategy Sync"
  - Date/duration badge
  - TLDR card (2 bullet points)
  - Summary section
  - Decisions card: "Ship mobile-first. Delay desktop 2 weeks."
  - Action Items card: "Sarah: Update roadmap · James: Finalize API"
  - Key Quotes card with speaker attribution
- Copy (RIGHT):
  ```
  [display] AI reads your meeting.
  You get the brief.

  [body] Summary, decisions, action items, key quotes,
  and participant detection — structured and organized
  in seconds. Not a transcript dump. A real brief.

  [amber accent] 7 meeting templates · Follow-up emails · Coaching reports
  ```
- Ambient glow: teal (intelligence)
- Floating labels: "Auto-generated" (top), "Shareable" (right)

**Sub-beat 2D: Smart Todos (42-50%)**
- Phone screen crossfades to: Todos view
- Todos screen shows:
  - Segmented control: TODAY / UPCOMING / ALL / HISTORY
  - Today's tasks list:
    - ☐ "Update roadmap with new timeline" — High · Due Mar 15
    - ☑ "Send proposal to Acme Corp" — Med · Done (strikethrough)
    - ☐ "Finalize API contract" — Normal · Due Mar 18
    - ☐ "Schedule follow-up with design" — Med · Due Mar 20
  - Floating action bar at bottom: "Voice" button (red) + "Add Task" button (purple)
  - Voice recording inline indicator (pulsing dot + timer)
- Copy (LEFT):
  ```
  [display] Say it. It's done.

  [body] "Send the proposal by Friday" becomes a todo
  with the right title, due date, and priority —
  automatically from your voice.

  Meeting action items flow into your task list.
  Nothing falls through the cracks.

  [violet accent] Voice capture · Natural language dates · Auto-priority
  ```
- Ambient glow: amber (productivity)
- Floating labels: "Voice-first" (bottom), "From meetings" (top-right)

**Sub-beat 2E: AI Chat (50-55%)**
- Phone screen crossfades to: Chat view
- Chat screen shows:
  - Header: AI chat icon + "Ask about your meetings"
  - Suggestion chips: "Action items on me?" / "Key decisions?" / "Tasks for Acme?"
  - Chat bubbles:
    - User: "What action items are on me from yesterday?"
    - AI: "You have 3 pending items: 1. Update roadmap (Due Mar 15)..."
  - Input bar with send button
- Copy (RIGHT):
  ```
  [display] Ask anything.
  Get answers instantly.

  [body] Search across all your meetings with natural language.
  "What did the customer ask?" "How many tasks this week?"
  AI knows your meetings, your tasks, your context.

  [teal accent] Cross-meeting search · Meeting recipes · Context-aware
  ```
- Ambient glow: violet (intelligence)

**Phone rotation:** Gentle Y-axis rotation throughout (0° → 12° → -8° → 5°), creating depth as screens transition.

---

### FRAME 3: THE ECOSYSTEM (55-80% scroll) — Features + Platforms
**Height:** 200vh

**Visual:**
- Phone exits (scales down and floats away)
- 6 feature cards materialize in a 3×2 grid, each with:
  - Glass background with colored glow on hover
  - Icon in colored circle
  - Title + 1-2 line description
  - Subtle 3D tilt on hover (CSS perspective transform)

**Feature Cards:**
1. 🎙️ **One-Tap Recording** — "No bots. No announcements. Just your microphone." (coral icon)
2. 📋 **AI Meeting Briefs** — "Structured summaries with decisions, quotes, and action items." (teal icon)
3. ✅ **Smart Todos** — "Voice-to-task with auto-priority and natural language dates." (violet icon)
4. 🌐 **Auto-Organization** — "Clients and companies detected from conversation context." (amber icon)
5. 💬 **AI Chat** — "Ask across all meetings. Get instant, contextual answers." (teal icon)
6. 🧪 **Meeting Recipes** — "Coach me, Prep me, Brief, Follow-up, Tasks, Sentiment." (violet icon)

**Below features — Device Showcase:**
Three device silhouettes floating together with subtle parallax:
- **iPhone** (center, slightly forward) — "Full experience"
- **Mac** (left, angled) — "Three-panel layout + menu bar companion"
- **Apple Watch** (right, smaller) — "Waveform recording + quick todos"

**Copy:**
```
[mono] WHAT YOU GET

[display-md]
Intelligence that
works while you talk.

[below devices]
iPhone. Mac. Apple Watch.
Your meetings follow you everywhere.
```

---

### FRAME 4: THE MOVE (80-100% scroll) — CTA
**Height:** 100vh

**Visual:**
- Particles settle to rich violet (brand home)
- Soft radial glow behind CTA
- Clean, spacious, confident

**Copy:**
```
[mono] READY?

[display-lg]
Stop losing your
meetings.

[body]
Start remembering everything. Record, summarize, and act —
from iPhone, Mac, and Apple Watch.

[form] Email input + "Join the Waitlist" button

[trust badges] Privacy-first · No bots ever · Apple native
```

---

## GOOGLE WHISK IMAGE PROMPTS

Generate these images in Google Whisk (https://labs.google/whisk) to use as background textures and accent visuals:

### Image 1: Meeting Chaos Abstract
```
Abstract dark illustration of meeting chaos. Scattered floating elements on deep purple-black background: speech bubbles, calendar pages, sticky notes, question marks, clock faces, all drifting apart in different directions. Geometric, flat-design style. Colors: muted coral red, amber, and purple on near-black (#050507) background. No text. Ethereal, slightly unsettling mood. Digital art, clean vector style, high contrast.
```

### Image 2: AI Intelligence Visualization
```
Abstract visualization of artificial intelligence processing data. Glowing teal and purple neural network nodes connected by luminous lines on deep black background. Central bright orb radiating organized data streams outward. Geometric, futuristic, clean. Colors: electric teal (#14F0C5), violet (#7C3AED) on void black (#050507). No text. Feels like organized intelligence emerging from chaos. Digital art, cinematic lighting.
```

### Image 3: Sound Wave Visualization
```
Elegant 3D audio waveform visualization floating in dark space. Smooth, organic wave ribbon made of purple and coral gradient light, undulating horizontally. Subtle particle sparkles around the wave. Deep black background with soft violet ambient glow. No text. Feels like captured sound made visible. Cinematic, premium, Apple-aesthetic. Digital art, photorealistic lighting.
```

### Image 4: Productivity Flow
```
Abstract illustration of organized productivity. Clean geometric cards and panels floating in structured alignment on dark background. Teal checkmarks, amber task indicators, purple connection lines between elements. Everything feels organized, flowing, connected. Colors: teal, amber, violet on near-black. No text. Feels like order from chaos. Modern, minimal, digital art style.
```

### Image 5: Apple Device Ecosystem
```
Three Apple devices floating in dark space: iPhone (center, slight angle), MacBook (behind-left), Apple Watch (right, smaller). All devices have dark screens with subtle purple-teal gradient glow on screens. Dramatic rim lighting on device edges. Deep black background with soft colored ambient light. No text on screens. Premium, cinematic, Apple product photography style. Photorealistic.
```

### Image 6: Hero Background Texture
```
Abstract gradient mesh background. Deep void black (#050507) transitioning to subtle dark violet (#0a0515) with barely visible geometric grid lines. Extremely subtle, atmospheric. Single soft radial glow of purple light in upper center. No elements, no icons, just pure atmospheric texture. Cinematic, moody, premium. 4K resolution, minimal, dark mode aesthetic.
```

---

## GOOGLE VEO / VEO FLOW VIDEO PROMPTS

Use these prompts in Google Veo (https://labs.google/veo) to create animated backgrounds:

### Video 1: Particle Universe Loop (Hero background)
```
Slow camera flythrough of a vast dark particle field in deep space. Tiny glowing purple and teal particles drift slowly, some closer and brighter, others distant and dim. Camera moves very slowly forward. Particles have soft glow and additive blending. Deep black void background. Cinematic, hypnotic, seamless loop. 10 seconds, 4K, 24fps. No sudden movements. Ambient, meditative mood.
```

### Video 2: Meeting Chaos → Order Transition
```
Abstract animation: scattered glowing geometric shapes (circles, squares, triangles) in coral and amber colors float chaotically on black background. Slowly, over 5 seconds, the shapes organize themselves into a clean grid formation, changing color from coral to teal as they align. Smooth, satisfying motion. Deep black background. Cinematic lighting. 8 seconds, 4K, seamless transition from chaos to order.
```

### Video 3: Audio Waveform Animation
```
Elegant audio waveform ribbon floating in dark space. The waveform pulses and undulates smoothly, made of glowing purple and coral gradient light. Subtle particles trail behind the wave peaks. Camera slowly orbits the waveform. Deep black background with soft ambient violet glow. Cinematic, premium feel. 6 seconds seamless loop, 4K.
```

### Video 4: Data Flow Visualization
```
Abstract data streams flowing from left to right on black background. Luminous teal and purple lines of light carrying small bright data points. Lines split, merge, and reorganize into structured patterns. Feels like raw information being processed into intelligence. Smooth, flowing motion. Deep black background. Cinematic, futuristic. 8 seconds loop, 4K.
```

### Video 5: Device Reveal
```
Slow cinematic reveal of a smartphone floating in dark space. The phone rotates very gently on its Y-axis, catching dramatic rim light on its edges. Subtle purple-teal ambient glow around the device. Screen shows abstract UI elements (not readable). Deep black background. Apple-level product cinematography feel. 6 seconds loop, 4K, premium lighting.
```

---

## HOW TO USE WHISK/VEO ASSETS IN THE LANDING PAGE

1. **Hero section background:** Use Image 6 (gradient mesh) as a CSS `background-image` behind the particle canvas, adds depth
2. **Pain section accent:** Use Image 1 (meeting chaos) as a semi-transparent overlay during Frame 1 scroll
3. **Recording section:** Use Video 3 (waveform) as a `<video>` element behind the phone during recording beat
4. **AI section accent:** Use Image 2 (AI visualization) as background during brief/AI chat beats
5. **Features section:** Use Image 4 (productivity flow) as subtle background texture
6. **Device showcase:** Use Image 5 (devices) as hero image or replace CSS device mockups entirely
7. **Background video:** Use Video 1 (particle universe) as `<video>` fallback for browsers where Three.js is slow

### Implementation:
```html
<!-- Background video (behind Three.js, fallback) -->
<video class="bg-video" autoplay muted loop playsinline>
  <source src="assets/videos/particle-universe.mp4" type="video/mp4">
</video>

<!-- Section accent image -->
<img class="section-accent" src="assets/images/ai-visualization.webp"
     alt="" loading="lazy" style="opacity:0.15; mix-blend-mode:screen" />
```

### File structure for assets:
```
assets/
  images/
    meeting-chaos.webp        ← Whisk Image 1
    ai-visualization.webp     ← Whisk Image 2
    sound-wave.webp           ← Whisk Image 3
    productivity-flow.webp    ← Whisk Image 4
    device-ecosystem.webp     ← Whisk Image 5
    hero-texture.webp         ← Whisk Image 6
  videos/
    particle-universe.mp4     ← Veo Video 1
    chaos-to-order.mp4        ← Veo Video 2
    waveform-loop.mp4         ← Veo Video 3
    data-flow.mp4             ← Veo Video 4
    device-reveal.mp4         ← Veo Video 5
```

---

## TECHNICAL SPEC

| Component | Technology |
|-----------|-----------|
| Structure | Single `index.html` |
| 3D | Three.js (CDN) — particles + geometric shapes |
| Scroll | GSAP ScrollTrigger (CDN) — pinned sections, scrub |
| Fonts | Google Fonts — Instrument Serif, Space Grotesk, JetBrains Mono |
| Form | Formspree (no backend) |
| Hosting | GitHub Pages |
| Images | WebP format, lazy-loaded |
| Videos | MP4, autoplay muted loop, lazy-loaded |

## PERFORMANCE

- Total page weight: <5MB (including videos)
- Lazy-load videos and images below fold
- `will-change: transform` on animated elements
- `prefers-reduced-motion`: disable Three.js, show static images
- Three.js render loop: pause when tab not visible
- Responsive: full 3D on desktop, simplified on mobile

---

*This brief defines the complete vision. Execute it as a single HTML file with embedded CSS and JS.*

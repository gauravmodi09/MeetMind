# MeetMind — Awwwards-Level Creative Brief

## ACT AS:
A world-class Awwwards-level Creative Developer and Brand Experience Director, specializing in ultra-premium web design, advanced scroll-based storytelling, Three.js 3D product interactions, and cinematic brand experiences for Apple-ecosystem productivity apps.

## THE TASK:
Design and implement a high-end, Apple-level scrollytelling landing page for MeetMind — an AI-powered meeting intelligence app for iPhone, Mac, and Apple Watch.

The experience should feel like a cinematic product reveal combined with an interactive capability showcase, driven entirely by scroll-based 3D animations, floating product renders, and premium typography/layout. The core mechanic: as the user scrolls, a 3D iPhone floats in space while MeetMind's capabilities unfold around it — meeting chaos dissolves into organized intelligence, with each scroll beat revealing a new layer of the product's power.

## TECH STACK INTENT:
- **3D Engine:** Three.js for particle universe, device renders, and floating UI elements
- **Scroll Engine:** GSAP ScrollTrigger for scroll-linked animations with `scrub: true`
- **Styling:** Single HTML file, CSS custom properties, no build step
- **Typography:** Premium font pairing (display serif + geometric grotesk + monospace)
- **Hosting:** GitHub Pages (static, no backend)

## VISUAL DIRECTION & BRAND AESTHETIC:

### Overall Vibe:
Apple-level, luxury tech, cinematic, ultra-clean, minimal, editorial, premium — but warmer than Sony. MeetMind is about human connection (meetings, conversations, people), so the aesthetic balances cold tech precision with warm, human-centered design.

### Seamless Blending:
The Three.js particle canvas fills the entire viewport as a fixed background. All content floats above it. The particles shift color with scroll progress, creating a living, breathing atmosphere that responds to the narrative.

### Color Palette — Premium Warm-Dark Mode:
- **Primary background:** deep void black `#050507`
- **Secondary background:** `#0A0A10` for glass panels and overlays
- **Headings:** `rgba(248,248,252,0.92)` with subtle depth
- **Body text:** `rgba(156,163,175,0.85)` for calm readability
- **Accent colors (MeetMind brand):**
  - Primary accent: electric violet `#7C3AED` (MeetMind purple)
  - Secondary accent: luminous teal `#14F0C5` (success/intelligence)
  - Recording accent: living coral `#FF6B6B` (recording state)
  - Warm accent: amber `#FBBF24` (productivity/todos)
- **Soft gradients:**
  - Hero: radial from `#050507` to deep desaturated violet `#0a0515`
  - Accent gradient: `#7C3AED` → `#14F0C5` for CTAs and key highlights
  - Danger-to-hope: `#FF6B6B` → `#7C3AED` for pain-to-solution transition

### Typography:
- **Display font:** Instrument Serif — elegant, editorial, warm personality
- **Body font:** Space Grotesk — geometric, modern, highly readable
- **Mono font:** JetBrains Mono — technical credibility, data/stats
- **Style:** tracking-tight, medium-to-bold weights, large scale, strong hierarchy
- **Headings:** bold, tight line-height, editorial feel — like Apple product pages
- **Body:** 16-20px, comfortable line-height, muted color, concise confident copy

### Overall Layout:
Full-bleed, edge-to-edge, generous negative space, no clutter, no decorative noise, restrained use of color, everything feels intentional and premium. Film grain overlay for cinematic texture.

## NAVBAR — STRUCTURE & BEHAVIOR:

Ultra-minimal top navigation bar, inspired by Apple's product pages.

- **Fixed/sticky** at top with translucent, blurred background (glassmorphism)
- **Left:** MeetMind wordmark in Instrument Serif
- **Center:** "Features", "How It Works", "Platforms"
- **Right:** "Join the Waitlist" CTA button with violet-to-teal gradient border
- **Height:** slim and compact
- **Background:** `rgba(5,5,7,0.8)` with `backdrop-filter: blur(20px)`
- **Hover states:** subtle opacity shift, no heavy decoration
- **Scroll behavior:** starts transparent, fades in after slight scroll

## CORE INTERACTION: SCROLL-LINKED 3D PRODUCT STORY

A Three.js particle universe fills the viewport as a fixed canvas. Above it, a CSS 3D iPhone device floats and transforms as the user scrolls. The phone's screen content transitions between app states (recording → AI processing → meeting brief → smart todos), while floating 3D elements (text labels, icons, connection lines) orbit around the device to illustrate each capability.

### 3D Background Elements (Key Gap to Fill):
Between the particle universe and the foreground content, add **mid-layer 3D floating elements** that explain the product:
- **Floating UI cards** — glass-morphic cards showing meeting briefs, todo items, and AI chat snippets that drift in parallax
- **3D geometric shapes** — subtle floating spheres, rings, and planes in brand colors that react to scroll position
- **Connection lines** — animated SVG paths connecting floating elements to show data flow (audio → transcript → brief → todos)
- **Glowing orbs** — soft light sources that illuminate the scene and shift color with the narrative
- **Abstract waveforms** — 3D audio waveform ribbons that float behind the phone during recording sections

## SCROLL LOGIC AND STORYTELLING BEATS:

### FRAME 1: THE COST — Hero + Pain (0-25% scroll)

**Visual:**
- MeetMind wordmark fades in with cinematic entrance
- Three.js particles in violet, slowly drifting
- 3D floating elements: scattered calendar icons, speech bubbles, sticky notes, question marks — all drifting apart (chaos visualization)
- Subtle ambient glow behind headline

**Copy (centered, bold, confident):**
- Large headline: *"Your meetings disappear the moment they end."*
- Subtitle: *"Decisions evaporate. Action items scatter. And by tomorrow, you'll remember none of it."*
- Pain stats fade in on scroll: "73% forgotten in 24h" / "31h wasted monthly" / "5+ apps for one meeting"

**Tone:** Short, confident, uncomfortable truth. Make the reader feel the problem.

### FRAME 2: THE SHIFT — Pivot + Product Reveal (25-55% scroll)

**Visual:**
- Particles shift from violet to teal (hope)
- Chaos elements dissolve/fade away
- 3D iPhone rises from below with dramatic entrance
- Phone shows recording screen with pulsing waveform
- Floating 3D elements around phone: audio wave ribbons, "Recording..." label, timer
- Phone rotates gently on Y-axis as user scrolls
- Screen transitions: Recording → AI Processing (brain icon, spinning) → Meeting Brief (cards stacking)

**Copy (left-aligned, emerging as user scrolls):**
- Pivot line: *"What if one tap could capture everything?"*
- Then: *"Tap. Record. No bots join your call."*
- Then: *"AI reads your entire meeting and gives you a structured brief in seconds."*
- Then: *"Summary. Decisions. Action items. Key quotes. All organized."*

**Feel:** Relief, revelation, "aha moment." The phone is the hero — everything orbits around it.

### FRAME 3: THE EXPERIENCE — Features + Platforms (55-80% scroll)

**Visual:**
- Particles shift to warm amber-violet
- 3D iPhone holds position, screen shows Smart Todos
- Feature cards float in from different directions (glass-morphic, hoverable)
- Device showcase: iPhone (center), Mac (left, larger), Watch (right, smaller) — all as 3D CSS elements with screen content
- Floating connection lines between devices showing sync

**Copy:**
- Section label: *"What You Get"*
- Headline: *"Intelligence that works while you talk."*
- 6 feature cards:
  1. **One-Tap Recording** — "No bots. No announcements. Just your microphone."
  2. **AI Meeting Briefs** — "Structured summaries with decisions, quotes, and action items."
  3. **Smart Todos** — "'Send the proposal by Friday' becomes a todo automatically."
  4. **Auto-Organization** — "Clients and companies detected from conversation context."
  5. **AI Chat** — "Ask questions across all your meetings. Get instant answers."
  6. **Meeting Recipes** — "Six AI templates: Coach, Prep, Brief, Follow-up, Tasks, Sentiment."
- Device showcase: "iPhone. Mac. Apple Watch. Your meetings follow you everywhere."

### FRAME 4: THE MOVE — CTA (80-100% scroll)

**Visual:**
- Particles settle to rich violet (brand home)
- All floating elements gently settle into rest
- Soft ambient glow behind CTA
- Clean, spacious layout

**Copy (centered, strong CTA):**
- Headline: *"Stop losing your meetings."*
- Subheadline: *"Start remembering everything."*
- Email input + "Join the Waitlist" button with gradient glow
- Trust badges: "Privacy-first" / "No bots ever" / "Apple native"

**Tone:** Confident, warm, inviting. Make joining feel inevitable.

## 3D BACKGROUND ELEMENTS — DETAILED SPEC:

### Floating Glass Cards (parallax mid-layer):
- Semi-transparent glass cards (`rgba(255,255,255,0.03)`, `border: 1px solid rgba(255,255,255,0.06)`)
- Contain snippets of meeting briefs, todo items, or AI responses
- Float at different depths (z-index layers with parallax scroll speeds)
- Gentle rotation and drift animation
- Blur slightly when not in their narrative section

### 3D Geometric Shapes (Three.js):
- Small glowing spheres (violet, teal) orbiting slowly
- Torus/ring shapes representing "cycles" and "flow"
- Icosahedron shapes for "intelligence" and "AI"
- All with soft emissive glow and transparency
- React to scroll: spread apart during "chaos," converge during "solution"

### Audio Waveform Ribbons (Three.js or SVG):
- 3D ribbon/tube geometry following a sine wave path
- Positioned behind the phone during recording sections
- Color: violet-to-coral gradient
- Animated: wave propagation along the ribbon

### Connection Lines (SVG overlay):
- Animated dashed lines connecting floating elements
- Draw-on animation triggered by scroll
- Color: teal with soft glow
- Connect: phone → brief card, phone → todo card, phone → AI chat

### Glowing Orbs (Three.js):
- 3-4 large, soft light sources
- Positioned behind key content sections
- Color shifts with scroll (coral → violet → teal → amber)
- Gaussian blur / bloom effect

## UI & VISUAL POLISH:

### Keywords:
Cinematic, photorealistic, hyper-detailed, ultra-premium, luxury tech, editorial, Apple-level, modern, minimalist, glassmorphism, gradient glows, smooth, buttery scroll, hardware-accelerated, immersive, interactive storytelling, scrollytelling, polished, Awwwards-level, warm-dark, human-centered.

### Stylistic Elements:
- Film grain overlay (SVG noise filter, `opacity: 0.035`)
- Soft ambient glows behind the product and key text blocks
- Subtle gradient borders around CTAs and feature cards
- `will-change: transform` on animated elements
- `prefers-reduced-motion` support for accessibility
- Responsive: desktop (full 3D), tablet (scaled), mobile (simplified 3D, stacked layout)

## PERFORMANCE:
- Three.js particle count: 400 (balanced for mobile)
- `requestAnimationFrame` render loop, paused when tab not visible
- Lazy-load non-critical assets
- Total page weight target: <3MB (excluding user-provided images)
- Font preloading for hero text

## FORMSPREE:
- Waitlist form posts to Formspree endpoint
- Success state: button changes to "You're in!" with checkmark
- Error state: graceful retry message

# MeetMind — App Store Screenshot Specifications

## Display Sizes

- **iPhone:** 6.7" (1290 x 2796 px) — iPhone 15 Pro Max / iPhone 16 Pro Max
- **Apple Watch:** Series 9/10 (396 x 484 px)

## Color Palette

| Role       | Hex     |
|------------|---------|
| Primary    | #6C5CE7 |
| Success    | #00CE9E |
| Recording  | #FF4757 |
| Background | #0F0F14 |
| Surface    | #1A1A24 |
| Text       | #FFFFFF |
| Muted      | #8E8E9A |

## Typography

- Headlines on screenshots: Space Grotesk Bold, 72pt
- Subtext: Inter Regular, 36pt
- All white on dark backgrounds unless otherwise noted

---

## iPhone Screenshots (6.7" — 1290 x 2796 px)

### Screenshot 1: Recording Screen

**Headline:** "Record any meeting with one tap"
**Layout:**
- Top third: headline text centered, white on dark gradient (#0F0F14 to #1A1A24)
- Center: iPhone frame showing the recording screen in dark theme
  - Large circular record button pulsing with #FF4757 glow
  - Audio waveform visualization across the middle of the screen, white bars with subtle #6C5CE7 tint
  - Timer display reading "00:24:17" in Space Grotesk Bold
  - Meeting title "Q1 Strategy Review" at top
  - Client folder tag "Acme Corp" with blue dot
- Bottom: subtle gradient fade to black
- Accent: soft red radial glow behind the waveform to suggest active recording

### Screenshot 2: Meeting Brief

**Headline:** "AI structures your notes instantly"
**Layout:**
- Top third: headline text centered
- Center: iPhone frame showing a completed meeting brief
  - Brief title: "Q1 Strategy Review — Summary"
  - Sections visible with clear hierarchy:
    - **Summary** (2-3 lines of body text, legible but not necessarily readable at screenshot scale)
    - **Key Decisions** (3 bullet points with checkmark icons in #00CE9E)
    - **Action Items** (3 items with assignee tags and due dates)
    - **Follow-ups** (2 items)
  - Each section has a subtle left border in #6C5CE7
  - Timestamp and duration badge at top: "Mar 12 - 47 min"
- Bottom: gradient fade
- Accent: subtle purple glow behind the brief card

### Screenshot 3: Client Folders

**Headline:** "Organized by client, automatically"
**Layout:**
- Top third: headline text centered
- Center: iPhone frame showing the client folders grid view
  - 2-column grid of folder cards with rounded corners
  - Each folder card shows:
    - Color dot (different per folder: blue, green, orange, purple, red, teal)
    - Client name in bold (e.g., "Acme Corp", "StartupX", "Design Co", "Internal", "Board", "Investors")
    - Meeting count subtitle (e.g., "12 meetings", "8 meetings")
    - Last meeting date in muted text
  - Cards have subtle surface background (#1A1A24) with soft shadows
  - One folder card slightly highlighted with #6C5CE7 border to draw attention
- Bottom: gradient fade
- Accent: colorful dots create visual variety against the dark background

### Screenshot 4: Smart Todos

**Headline:** "Voice todos with smart dates"
**Layout:**
- Top third: headline text centered
- Center: iPhone frame showing the Today todo view
  - "Today" header with date
  - 4-5 todo items with varying states:
    - One completed (strikethrough, #00CE9E checkmark)
    - Three active with due dates and source meeting tags
    - Example items: "Send revised proposal to Sarah — Due Today", "Review Q1 metrics deck — Due Tomorrow", "Schedule follow-up with design team — Due Friday"
  - Floating voice input button at bottom right, circular with microphone icon in #6C5CE7
  - A speech bubble animation near the mic button showing: "Call Sarah about the proposal by Friday"
  - Smart date parsing visualization: "by Friday" highlighted in #6C5CE7 with a small arrow pointing to the parsed date "Mar 21"
- Bottom: gradient fade
- Accent: voice input button has a subtle pulse ring animation (shown as concentric circles)

### Screenshot 5: Copy Brief

**Headline:** "Share-ready in one tap"
**Layout:**
- Top third: headline text centered
- Center: Layered composition showing:
  - Background layer: iPhone screen with a meeting brief and a prominent "Copy Brief" button with clipboard icon in #6C5CE7
  - Foreground layer (offset to the right and slightly overlapping): A mock email compose window or Slack message showing the pasted brief content, clean and formatted
  - Small "Copied!" toast notification in #00CE9E floating above the button
  - The pasted content preview should show the brief maintains its formatting — headers, bullets, and structure are preserved
- Bottom: gradient fade
- Accent: a subtle dotted line connecting the copy button to the pasted result to show the flow

### Screenshot 6: Apple Watch

**Headline:** "Record from your wrist"
**Layout:**
- Top third: headline text centered
- Center: Apple Watch frame (Series 9 size, angled slightly for depth) showing:
  - The MeetMind recording screen on the watch face
  - Large record/stop button taking up the bottom half
  - Timer "00:12:45" prominently displayed
  - Waveform visualization (simplified, 3-4 bars)
  - Meeting title "Team Standup" at top in small text
- The watch is rendered at approximately 2x its real size to fill the iPhone screenshot frame
- Background: dark with a subtle purple gradient halo behind the watch
- Bottom: gradient fade
- Accent: red recording indicator dot in the top-left of the watch face

---

## Apple Watch Screenshots (396 x 484 px)

### Watch Screenshot 1: Recording in Progress

**Layout:**
- Full watch screen, dark background (#0F0F14)
- Top: Meeting title "Team Standup" in small white text
- Center: Timer "00:12:45" in Space Grotesk Bold, large
- Middle: Simplified audio waveform — 5-7 vertical bars of varying height, white with subtle red tint
- Bottom: Large circular Stop button in #FF4757
- Top-left corner: small red recording dot (pulsing indicator)
- Overall feel: minimal, glanceable, focused on the essentials

### Watch Screenshot 2: Meeting List / Start Recording

**Layout:**
- Full watch screen, dark background (#0F0F14)
- Top: "MeetMind" app title in small muted text
- List view showing 2 recent meetings:
  - "Q1 Strategy Review" — "47 min - Mar 12" in muted text
  - "Team Standup" — "15 min - Mar 12" in muted text
- Bottom: Large circular Record button in #6C5CE7 with microphone icon
- Tapping the button starts a new recording
- Overall feel: simple list with prominent action button, easy to start recording with one tap

---

## General Design Notes

- All screenshots use the dark theme as the primary presentation
- Device frames should be minimal and modern (thin bezels, no home button)
- Headlines use a consistent position and size across all 6 iPhone screenshots for visual rhythm
- Background gradients are subtle — avoid harsh color transitions
- Keep text on the device screens realistic but not distracting — the headline does the storytelling
- Screenshots should be created at 1290 x 2796 px for iPhone and exported as PNG with no transparency
- Apple Watch screenshots should be created at 396 x 484 px
- Consider adding a very subtle noise/grain texture to backgrounds for depth (opacity 3-5%)

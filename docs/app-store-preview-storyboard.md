# App Store Preview Video — MileTrack
**Duration:** 30 seconds
**Format:** iPhone screen recording (portrait), exported at 1080x1920 or 886x1920 (6.5" display)
**Tone:** Clean, confident, minimal — no voiceover, text overlays carry the message
**Music:** Upbeat but understated — something like a soft synth loop with a light groove. Royalty-free suggestions: "Colorful Flowers" or "Electric Bounce" on Pixabay, or use GarageBand's "Bright Future" preset.

---

## Shot Breakdown

---

### Scene 1 — Hook (0:00–0:05)
**Duration:** 5 seconds
**What's shown:** The MileTrack app icon animates in from center on a clean white/dark background, then cuts to a large bold number counting up.

**Visual direction:**
- App icon drops in with a subtle bounce (simulate with a screen recording of the launch splash or just cut to it statically)
- Cut to a full-screen text card: large green number "**$2,800**" counting up (use a simple Keynote/After Effects animation, or just show the static card)
- Clean sans-serif font, green on white (light mode) or green on near-black (dark mode)

**Text overlay:**
```
Every mile you drive
could be a tax deduction.
```
(smaller subtext, centered below the number)

**Recording instructions:**
- You don't need to record the app for this scene — create it as a title card in Keynote or ScreenFlow
- Export as a 5-second video clip and splice it in during editing
- Alternatively: open the Onboarding screen to Page 1 ("Every Mile Is Money") and do a slow pan-zoom on the hero number/text

---

### Scene 2 — Auto-Detection (0:05–0:12)
**Duration:** 7 seconds
**What's shown:** The app running in the background. A trip notification or a new "Pending" card appears in the Inbox — showing that the app caught a drive automatically, without the user doing anything.

**Visual direction:**
- Start with the iPhone home screen (or a dark lock screen) to convey "app is closed / in background"
- Cut to MileTrack opening — the Inbox tab is visible with a new pending trip card sliding in at the top
- The card should show: date (today), a distance (e.g. "8.3 mi"), start time ("8:14 AM"), and status badge "Pending"
- Hold for 2–3 seconds so viewer can read it

**Text overlay (bottom third of screen):**
```
Detected automatically.
No buttons. No check-ins.
```

**Recording instructions:**
1. Open MileTrack in the Simulator (or on device)
2. Navigate to the Inbox tab
3. If you have a pending trip, great — record the screen with it visible
4. If not: temporarily add a mock `TripEntity` in preview data, or screenshot a real trip and use that card as a static image
5. Slowly scroll down one row to give it motion, then stop

---

### Scene 3 — Inbox Review (0:12–0:18)
**Duration:** 6 seconds
**What's shown:** User opens a pending trip, swipes or taps to confirm it as "Business", adds a category (e.g. "Client Visit").

**Visual direction:**
- Tap the pending trip card from Scene 2 — the detail/review sheet slides up
- Show the trip summary: map thumbnail (if available), distance, duration
- Tap the "Business" confirmation button — it animates to confirmed state (green checkmark or pill)
- Tap a category/purpose field and select "Client Visit" from a list (or type it)
- The card dismisses with a satisfying motion

**Text overlay:**
```
Review and confirm
in seconds.
```

**Recording instructions:**
1. Have a real or mock pending trip ready in the Inbox
2. Tap to open the detail view — record the full interaction
3. Move slowly and deliberately — no rushed taps
4. If the trip confirmation animation is snappy, let it land before moving on
5. Trim to ~6 seconds, keeping the most visually satisfying moment (the "confirmed" state)

---

### Scene 4 — Report Generation (0:18–0:24)
**Duration:** 6 seconds
**What's shown:** User navigates to the export/reports section, taps "Export PDF", and a polished PDF report slides into view.

**Visual direction:**
- Navigate to the Reports or Export screen
- Tap the "Export PDF" button — show a brief loading indicator if one exists
- The PDF preview slides in: it should show a table of trips, total miles, total deduction amount (e.g. "Total deduction: $1,204.60")
- Hold on the PDF for 2 seconds so the viewer can see it's a real, IRS-ready document

**Text overlay:**
```
IRS-ready report.
One tap.
```

**Recording instructions:**
1. Navigate to the export screen with at least 5–10 trips logged (use real data or demo data)
2. Record the tap on Export PDF and the resulting preview
3. If the PDF preview renders in a `QuickLookPreviewController` or share sheet — that's fine, show it
4. Zoom in slightly (via Simulator window zoom or post-production crop) so the PDF text is readable

---

### Scene 5 — Call to Action (0:24–0:30)
**Duration:** 6 seconds
**What's shown:** MileTrack app icon centered on a clean background, with the download CTA below it.

**Visual direction:**
- Fade from the PDF scene to a clean gradient background (use MileTrack's accent green or a neutral dark)
- App icon animates in at center (scale up from 80% with a bounce)
- Below the icon, two lines of text appear with a gentle fade-in

**Text overlay:**
```
MileTrack
Download Free on the App Store
```
(App Store badge optional — check Apple guidelines before adding)

**Recording instructions:**
- This is a title card — create it in Keynote, Canva, or ScreenFlow
- Use a real app icon asset (grab from `Assets.xcassets` in the Xcode project)
- Export as a 6-second clip and splice it at the end

---

## Editing Notes

### Recommended tool
**ScreenFlow** (Mac, ~$129) is the easiest all-in-one for recording the Simulator and adding text overlays. Alternatives: iMovie (free, basic), Final Cut Pro (powerful, pricier), or Canva Video (web-based, good for title cards).

### Post-production checklist
- [ ] Trim all clips to exact durations above
- [ ] Add smooth cuts or 0.2s cross-fades between scenes — avoid hard cuts
- [ ] Text overlays: use SF Pro Display or a clean sans-serif, white or dark depending on background
- [ ] Color-grade for consistency: slight warmth, high contrast — avoid washed-out look
- [ ] Export at 1080x1920 (or 886x1920 for 6.5" display) for App Store upload
- [ ] Keep total duration at or under 30 seconds (App Store hard limit)
- [ ] Mute all system sounds before recording (Simulator: Hardware > Mute)

### Simulator setup tips
- Use iPhone 15 Pro Max simulator for the largest canvas
- Set to Light Mode for maximum legibility in the video
- Increase text size slightly (Settings > Accessibility > Larger Text) so it reads on small screens
- Use "Slow Animations" (Debug > Slow Animations, or Cmd+T) to make UI transitions more cinematic — then speed up the clip in editing

### Apple App Store video requirements (as of 2025)
- Format: H.264 or HEVC
- Max file size: 500 MB
- Accepted resolutions: 886x1920, 1080x1920 (portrait); 1200x1600, 900x1200 (iPad)
- Duration: 15–30 seconds
- Audio: optional, but recommended — captions are not required for previews
- First frame is used as poster image if video autoplay is disabled

---

## Shot List Summary

| Scene | Time | Key Action | Text Overlay |
|-------|------|------------|--------------|
| 1. Hook | 0:00–0:05 | App icon + $2,800 counter | "Every mile you drive could be a tax deduction." |
| 2. Auto-detection | 0:05–0:12 | Pending trip appears in Inbox | "Detected automatically. No buttons. No check-ins." |
| 3. Inbox review | 0:12–0:18 | Confirm trip + add category | "Review and confirm in seconds." |
| 4. Report | 0:18–0:24 | Tap Export PDF → PDF slides in | "IRS-ready report. One tap." |
| 5. CTA | 0:24–0:30 | App icon + download text | "MileTrack — Download Free on the App Store" |

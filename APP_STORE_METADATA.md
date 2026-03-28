# MileTrack — App Store Metadata

## Already Set via API ✅
- Description
- Keywords: mileage,tracker,tax,deduction,IRS,business,miles,drive,log,expense,auto,GPS,freelance
- Promotional Text: "Auto-track every business mile. Export IRS-ready reports at tax time."
- Subtitle: "Auto Mileage & Tax Deductions"
- Review Notes

## Still Needed
- [ ] Screenshots (see spec below)
- [ ] App Icon (should be in the Xcode project already)
- [ ] Support URL (set in App Store Connect)
- [ ] Privacy Policy URL (set in App Store Connect — use plenitudo.ai/privacy or host the HTML)
- [ ] Category: Finance (primary), Business (secondary)
- [ ] Age Rating: 4+
- [ ] Build upload
- [ ] Subscription products created in App Store Connect

## Screenshot Spec

You need screenshots for **6.7" (iPhone 15 Pro Max)** and **6.5" (iPhone 11 Pro Max)** at minimum.

### Screens to Capture (in order)

1. **Home Dashboard** — shows status card (Auto Mode green), deduction hero with $ amount, today/week/month metrics
   - Best with: some sample trips already confirmed so the deduction shows a real number
   - Caption: "Track your deductions automatically"

2. **Inbox with Pending Trips** — show 2-3 trips in the inbox with swipe gesture partially visible
   - Caption: "Swipe to categorize — business, personal, or medical"

3. **Reports View** — show the charts (category bar chart + monthly miles chart) with some data
   - Caption: "Beautiful reports, ready for tax time"

4. **PDF Export Preview** — show the IRS-compliant PDF with trip log table
   - Caption: "Export IRS-ready mileage logs"

5. **Settings / Auto Mode** — show auto mode enabled with tracking health green
   - Caption: "Set it and forget it — auto-tracks every drive"

6. **Named Locations** — show Home and Work saved with addresses
   - Caption: "Smart location recognition"

### How to Capture

1. Run on iPhone 15 Pro Max simulator (6.7")
2. Add some sample trips first so the UI looks populated
3. Use Cmd+S in Simulator to save screenshots
4. Screenshots go to ~/Desktop by default

### Tips
- Use light mode (Apple prefers it for primary screenshots)
- Make sure the status bar shows a realistic time and full signal/battery
- No placeholder text — everything should look real

## Review Notes

```
TESTING NOTES
- Auto Mode enabled by default — grant "Always" location permission when prompted
- To test: take a short drive (>0.3 mi), trip appears in Inbox within 2 min of stopping
- Manual trip: tap floating + button on any tab
- Subscriptions: ai.plenitudo.MileTrack.pro.monthly ($5.99), ai.plenitudo.MileTrack.pro.annual ($39.99)
- No demo account required — app is free with optional Pro subscription

FEATURES (4 tabs: Home, Inbox, Reports, Settings)
1. Auto Mode: Settings > Auto Mode (ON) > drive > trip auto-detected
2. Inbox: Swipe right=confirm, left=dismiss. Tap circles to merge trips.
3. Reports: Charts + filters + CSV export (free) + PDF export (Pro)
4. Named Locations: Settings > Locations > save Home/Work for auto-snapping
5. Rules: Settings > Rules > auto-categorize by route (Pro)

PRIVACY: All data on-device + optional iCloud backup. No analytics, no ads, no accounts.
Contact: hello@plenitudo.ai
```

---

**Last Updated:** March 28, 2026

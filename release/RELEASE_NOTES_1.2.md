# Release Notes — Version 1.2

## App Store "What's New" (max 4000 chars)

**Smarter tracking, better reports, and a polished experience.**

- Faster trip detection — trips now detected within seconds of driving, not minutes
- Improved GPS accuracy — pre-detection miles are no longer lost
- CSV export redesigned for reimbursement — clean From/To columns, totals row, readable dates
- Reports page streamlined — trip details collapsed by default with pagination
- iPad support — optimized layouts across all screens
- Edit trip addresses — full street address now editable, not just city/state
- Inbox improvements — empty state now offers quick manual trip entry
- Settings reorganized — cleaner layout with consolidated sections
- iCloud sync reliability — improved backup and restore
- Bug fixes and performance improvements

## Internal Release Notes (for team)

### New Features
- CSV export: From/To combined columns, Mileage Amount/Total Reimbursement labels, totals row, Mileage_Report filename
- Reports: trip details collapsed by default, chevron toggle, paginated 20 at a time
- EditTripSheet: start/end addresses fully editable (were read-only)
- Inbox empty state: "Log a trip manually" CTA button
- Merged trip waypoints include full street address
- AppStore.sync() on launch for automatic subscription restore

### Bug Fixes
- iOS 26 crash: GlassCard glow shadow moved off .glassEffect surface (SDF crash)
- Salvaged trips now persist and geocode end coordinates
- Tracking pulse: redesigned as PulseRing overlay (no layout bounce)
- Trip detection: consecutive readings 3→2, distance filter 20→10m, pre-detection distance seeded
- ExpenseCalculator: class→struct (fixes malloc crash)

### UX Improvements
- Removed broken Expenses tab (app now 4 tabs)
- Settings: Mileage Rates moved to App section, Expenses section removed
- iPad: 600pt max content width on all screens/sheets/onboarding
- InboxView swipe animation uses actual screen width

### Security
- .completeFileProtection on all persistence stores
- PII redacted from production diagnostic logs
- CSV formula injection protection

### Infrastructure
- DiagnosticsLogger enabled in release builds
- 44 unit tests added (TripDecoding, ExportService, TripMerge, TripPersistence, ExpenseCalculator)
- Manrope font added to bundle

# MileTrack (iOS)

An iPhone app project scaffolded to follow the “meta” repository structure from `Cursor/Template/apple-app-meta-template` (docs, scripts, release, legal, support), plus a clean SwiftUI starter app.

## Repository structure

- `MileTrack/`: iOS app source (SwiftUI) starter code
- `MileTrackTests/`: Unit tests starter code
- `docs/`: developer documentation (Xcode setup, data, workflows)
- `scripts/`: project automation (icons, Xcode project management, maintenance)
- `release/`: App Store + TestFlight materials
- `legal/`: privacy policy and other legal docs
- `support_site/`: support content templates
- `modules/`: optional modules (e.g., HealthKit/Watch docs)
  
## Getting started

1. Create the Xcode project (once):
   - Xcode → New Project → iOS → App
   - Product Name: `MileTrack`
   - Interface: SwiftUI
   - Language: Swift
   - Save the project in this directory (`/Users/kennethnygren/Cursor/MileTrack`)
2. Ensure the starter files in `MileTrack/` are in the Xcode project (add them if needed).
3. Select the `MileTrack` scheme and run on an iPhone simulator.
4. Update bundle ID + signing:
   - In Xcode: Project settings → Signing & Capabilities → set your Team + Bundle Identifier.

## Template sync (optional)

This repo includes the template folder structure, but not the full upstream template content.
If you want to copy in the full template materials, use:

```bash
./scripts/template_sync.sh
```

After syncing, see `PLACEHOLDERS.md` and replace any `{{...}}` tokens.

## Code style

- Formatting: `swiftformat` (config: `.swiftformat`)
- Linting: `swiftlint` (config: `.swiftlint.yml`)


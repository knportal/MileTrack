# Create the Xcode project (MileTrack)

This repository starts with a clean folder layout and starter SwiftUI files. Create the actual Xcode project once, then keep adding new code under `MileTrack/`.

## Steps

1. Open Xcode.
2. File → New → Project → iOS → **App**
3. Configure:
   - Product Name: `MileTrack`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Tests: enabled (recommended)
4. Save the project into this repo root:
   - `/Users/kennethnygren/Cursor/MileTrack`

## Add the starter files

If Xcode created its own default `ContentView.swift` / `MileTrackApp.swift`, you can:

- keep Xcode’s versions and delete the duplicates, or
- replace Xcode’s versions with the repo’s versions under `MileTrack/`

Afterward, make sure these compile as part of the iOS app target:

- `MileTrack/MileTrackApp.swift`
- `MileTrack/ContentView.swift`
- `MileTrack/Core/MileStore.swift`
- `MileTrack/Models/MileEntry.swift`
- `MileTrack/Features/AddEntry/AddEntryView.swift`

## Quality tools (optional, recommended)

You already have `swiftlint` and `swiftformat` installed on this machine.
To enforce them in Xcode builds, add a **Run Script Phase** to the app target (before “Compile Sources”) and run:

- `swiftformat` on changed files (format)
- `swiftlint` (lint)

You can also run them manually from the repo root:

```bash
swiftformat .
swiftlint
```


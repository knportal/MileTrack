# Automatic File Addition Setup

This guide explains how to set up automatic addition of Swift files to the Xcode project.

## Option 1: Xcode Build Phase (Recommended)

This runs automatically before each build, ensuring files are always added.

### Setup Steps

1. Open `Plena.xcodeproj` in Xcode
2. Select the **Plena** target in the Project Navigator
3. Go to **Build Phases** tab
4. Click the **+** button at the top and select **New Run Script Phase**
5. Drag the new phase to be **before** the "Sources" phase (at the top)
6. Expand the new script phase
7. In the script box, paste:
   ```bash
   "${SRCROOT}/scripts/add_files_build_phase.sh"
   ```
8. Name the phase: "Ensure Files in Project"
9. Uncheck "For install builds only"
10. Repeat for the **Plena Watch App** target if desired

### How It Works

- Runs automatically before every build
- Silently adds any missing Swift files
- No user interaction required
- Works for all team members

## Option 2: File Watcher (Real-time)

Watches for new Swift files and adds them immediately when created.

### Setup Steps

1. Install `fswatch`:
   ```bash
   brew install fswatch
   ```

2. Start the watcher:
   ```bash
   ./scripts/watch_for_new_files.sh &
   ```

3. To run in background persistently, add to your shell profile:
   ```bash
   # Add to ~/.zshrc or ~/.bash_profile
   if [ -f "$HOME/Cursor/Plena/scripts/watch_for_new_files.sh" ]; then
       nohup "$HOME/Cursor/Plena/scripts/watch_for_new_files.sh" > /dev/null 2>&1 &
   fi
   ```

### How It Works

- Watches for new `.swift` files in project directories
- Automatically adds them when detected
- Runs in background
- Requires `fswatch` to be installed

## Option 3: Git Post-Commit Hook (Already Active)

Automatically runs after each commit to catch any missed files.

### Status

✅ **Already configured** - The post-commit hook is active and will:
- Check for missing files after each commit
- Automatically add them
- Show a message if files were added

### How It Works

- Runs automatically after `git commit`
- Catches files that weren't added before committing
- Shows notification if files were added
- No setup required (already configured)

## Option 4: Manual (On-Demand)

Run the script manually when needed:

```bash
python3 scripts/add_missing_files_to_project.py
```

## Recommended Setup

For best coverage, use **Option 1 (Xcode Build Phase)** + **Option 3 (Post-Commit Hook)**:

- **Build Phase**: Catches files before builds
- **Post-Commit Hook**: Catches files that slipped through

This provides two layers of protection with no manual intervention needed.

## Verification

To verify automatic addition is working:

1. Create a test Swift file:
   ```bash
   touch Plena/Views/TestAutoAdd.swift
   ```

2. Build the project in Xcode (if using Option 1)
   OR
   Commit the file (if using Option 3)

3. Check that the file appears in Xcode's Project Navigator

4. Delete the test file:
   ```bash
   rm Plena/Views/TestAutoAdd.swift
   ```

## Troubleshooting

### Build Phase Not Running

- Ensure the script phase is **before** the Sources phase
- Check that the script path is correct: `"${SRCROOT}/scripts/add_files_build_phase.sh"`
- Verify the script is executable: `chmod +x scripts/add_files_build_phase.sh`

### File Watcher Not Working

- Check if `fswatch` is installed: `which fswatch`
- Install if missing: `brew install fswatch`
- Check if the watcher is running: `ps aux | grep watch_for_new_files`

### Post-Commit Hook Not Running

- Verify the hook is executable: `chmod +x .git/hooks/post-commit`
- Test manually: `.git/hooks/post-commit`
- Check git config: `git config core.hooksPath` (should be empty or `.git/hooks`)





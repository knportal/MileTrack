# Quick Start: Automatic File Addition

## 🚀 Fastest Setup (Recommended)

**Add Xcode Build Phase** - This is the easiest and most reliable method:

1. Open `{{XCODE_PROJECT_NAME}}.xcodeproj` in Xcode
2. Select **{{IOS_APP_TARGET}}** target → **Build Phases** tab
3. Click **+** → **New Run Script Phase**
4. Drag it to the **top** (before Sources)
5. Paste this script:
   ```bash
   "${SRCROOT}/scripts/add_files_build_phase.sh"
   ```
6. Name it: **"Ensure Files in Project"**
7. Uncheck **"For install builds only"**
8. **Fix the warning**: Uncheck **"Based on dependency analysis"**
   (This is the recommended approach - see [Build Phase Setup Guide](../docs/development/BUILD_PHASE_SETUP.md) for alternatives)

✅ Done! Files will be added automatically before each build.

**Note**: If you see "stale file" errors, make sure you've unchecked "Based on dependency analysis" instead of using Output Files.

## 🎯 Alternative: Interactive Setup

Run the setup wizard:

```bash
./scripts/setup_automatic_addition.sh
```

## 📋 What's Already Active

- ✅ **Pre-commit hook** - Checks for missing files before commits
- ✅ **Post-commit hook** - Adds missing files after commits

## 🔍 Verify It Works

1. Create a test file: `touch {{IOS_APP_TARGET}}/Views/TestFile.swift`
2. Build in Xcode (if using build phase) OR commit the file
3. Check Xcode - the file should appear automatically
4. Delete test: `rm {{IOS_APP_TARGET}}/Views/TestFile.swift`

## 📚 Full Documentation

- [Automatic File Addition Setup Guide](../docs/xcode/AUTOMATIC_FILE_ADDITION_SETUP.md)
- [Xcode Project Management Guide](../docs/xcode/XCODE_PROJECT_MANAGEMENT.md)


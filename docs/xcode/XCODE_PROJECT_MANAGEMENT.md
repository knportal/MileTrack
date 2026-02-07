# Xcode Project Management

## Overview

To ensure all Swift files are automatically added to the Xcode project, we've set up automated tooling that:

1. **Detects missing files** - Scans for Swift files not in the project
2. **Automatically adds them** - Adds missing files to `project.pbxproj` with correct target membership
3. **Pre-commit checks** - Git hook prevents commits with missing files

## Quick Start

### After Creating New Swift Files

Run this command to automatically add any missing files:

```bash
python3 scripts/add_missing_files_to_project.py
```

The script will:
- Create a backup of `project.pbxproj`
- Add all missing Swift files
- Assign correct target membership (iOS, Watch, or both)
- Place files in the correct groups

### Check Without Making Changes

```bash
python3 scripts/add_missing_files_to_project.py --dry-run
```

## How It Works

### Target Assignment Rules

- **`Plena/`** files → iOS target only
- **`Plena Watch App/`** files → Watch target only
- **`PlenaShared/`** files → Both iOS and Watch targets (shared code)
- **`Tests/`** files → iOS target (if Tests group exists)

### What Gets Added

For each missing file, the script adds:

1. **PBXFileReference** - File reference entry
2. **PBXBuildFile** - Build file entries for each target
3. **Group membership** - Adds to appropriate group (Views, Components, Models, Services, ViewModels, etc.)
4. **Build phase** - Adds to Sources build phase for each target

## Pre-Commit Hook

A git pre-commit hook automatically checks for missing files. If found:

- Commit is blocked
- List of missing files is shown
- Instructions to fix are provided

To bypass (not recommended):
```bash
git commit --no-verify
```

## Manual Process (Alternative)

If you prefer to add files manually in Xcode:

1. Right-click the appropriate group in Project Navigator
2. Select "Add Files to Plena..."
3. Select the Swift file(s)
4. **Important**: Uncheck "Copy items if needed"
5. Ensure correct target membership is selected:
   - iOS files → Check "Plena" only
   - Watch files → Check "Plena Watch App" only
   - Shared files → Check both "Plena" and "Plena Watch App"

## Troubleshooting

### Script Can't Find Group

If the script skips a file with "Could not determine group":

1. Ensure the file is in the correct directory structure
2. Check if the group exists in Xcode (add it manually if needed)
3. The file will need to be added manually

### Restore from Backup

If the script makes incorrect changes:

```bash
cp Plena.xcodeproj/project.pbxproj.backup Plena.xcodeproj/project.pbxproj
```

### Tests Directory

If Test files are being skipped, the Tests group may not exist in the project. Add it manually in Xcode first, then re-run the script.

## Best Practices

1. ✅ **Run the script after creating new files** - Prevents missing file issues
2. ✅ **Let the pre-commit hook catch issues** - Don't bypass it
3. ✅ **Use shared code for common functionality** - Files in `PlenaShared/` automatically go to both targets
4. ✅ **Verify in Xcode after running script** - Open the project and confirm files appear correctly

## Scripts Reference

- **`scripts/add_missing_files_to_project.py`** - Main script to add missing files
- **`scripts/ensure_files_in_project.sh`** - Interactive wrapper script
- **`.git/hooks/pre-commit`** - Git hook that checks before commits
- **`scripts/README.md`** - Detailed script documentation





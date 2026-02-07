# Missing Files Checker

This project includes tools to detect Swift files that exist in the filesystem but aren't included in the Xcode project, which causes build errors.

## Quick Check

Run the check script to see which files are missing:

```bash
./check_missing_files.sh
```

For verbose output showing all missing files:

```bash
./check_missing_files.sh --verbose
```

## How It Works

The script:

1. Scans all Swift files in `Plena/`, `Plena Watch App/`, `PlenaShared/`, and `Tests/`
2. Checks if each file is referenced in `Plena.xcodeproj/project.pbxproj`
3. Reports any files that exist but aren't in the project

## Adding Missing Files

### Option 1: Manual (Recommended)

1. Open `Plena.xcodeproj` in Xcode
2. Right-click the appropriate group in Project Navigator:
   - Views → `Plena/Views/`
   - Components → `Plena/Views/Components/`
   - Models → `PlenaShared/Models/`
   - Services → `PlenaShared/Services/`
   - ViewModels → `PlenaShared/ViewModels/`
   - Tests → `Tests/`
3. Select "Add Files to Plena..."
4. Navigate to and select the missing files
5. **Important**: Uncheck "Copy items if needed"
6. Ensure correct target membership is selected (usually just "Plena" for iOS files)
7. Click "Add"

### Option 2: Automated (Advanced)

The `add_missing_files_to_project.py` script can help identify files, but automatic addition to `project.pbxproj` is complex and error-prone. Manual addition through Xcode is recommended.

## Pre-commit Hook

A Git pre-commit hook is installed that will check for missing files before each commit. If missing files are detected, the commit will be blocked.

To skip the check (not recommended):

```bash
git commit --no-verify
```

## Common Issues

### Files Keep Getting Removed

If files keep disappearing from the project:

1. Check if they're in `.gitignore` or `.cursorignore`
2. Verify file paths are correct
3. Check Xcode's "Show in Finder" to see what Xcode thinks is there

### Build Errors After Adding Files

After adding files manually:

1. Clean build folder (Cmd+Shift+K)
2. Close and reopen Xcode
3. Rebuild the project

## Integration with Cursor/Development Workflow

When creating new Swift files:

1. Create the file in the appropriate directory
2. Run `./check_missing_files.sh` to verify it's detected
3. Add it to Xcode project manually (see Option 1 above)
4. Verify it appears in the correct group and target

## Scripts

- `check_missing_files.sh` - Detects missing files
- `add_missing_files_to_project.py` - Helper script (identifies files, doesn't auto-add)



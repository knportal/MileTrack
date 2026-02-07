# Xcode Project Management Scripts

This directory contains scripts to help manage Swift files in the Xcode project.

## Quick Setup

Run the interactive setup script to configure automatic file addition:

```bash
./scripts/setup_automatic_addition.sh
```

This will guide you through setting up automatic addition via:
- Xcode Build Phase (recommended)
- File Watcher (real-time)
- Git Post-Commit Hook (already active)

## add_missing_files_to_project.py

Automatically adds missing Swift files to the Xcode project (`project.pbxproj`).

### Usage

```bash
# Check for missing files (dry run)
python3 scripts/add_missing_files_to_project.py --dry-run

# Actually add missing files
python3 scripts/add_missing_files_to_project.py

# Verbose output
python3 scripts/add_missing_files_to_project.py --verbose
```

### What it does

1. Scans for all `.swift` files in:
   - `{{IOS_APP_TARGET}}/`
   - `{{WATCH_APP_TARGET}}/`
   - `{{SHARED_TARGET}}/`
   - `Tests/`

2. Compares against files already in `project.pbxproj`

3. For each missing file:
   - Creates a `PBXFileReference` entry
   - Creates `PBXBuildFile` entries for appropriate targets (iOS, Watch, or both)
   - Adds the file to the correct group in the project structure
   - Adds the file to the appropriate build phases

4. Creates a backup of `project.pbxproj` before making changes

### Target Assignment

- Files in `{{IOS_APP_TARGET}}/` → iOS target only
- Files in `{{WATCH_APP_TARGET}}/` → Watch target only
- Files in `{{SHARED_TARGET}}/` → Both iOS and Watch targets
- Files in `Tests/` → iOS target (if Tests group exists in project)

### Notes

- The script automatically determines which targets a file should belong to based on its path
- Shared files (in `PlenaShared/`) are automatically added to both iOS and Watch targets
- A backup is created before any changes are made
- If the Tests group doesn't exist in the project, Test files will be skipped (add the Tests group in Xcode first)

## ensure_files_in_project.sh

Interactive script that checks for missing files and offers to add them.

```bash
./scripts/ensure_files_in_project.sh
```

## Pre-commit Hook

A git pre-commit hook (`.git/hooks/pre-commit`) automatically checks for missing files before each commit. If missing files are found, the commit is blocked with instructions on how to fix it.

To bypass the check (not recommended):
```bash
git commit --no-verify
```

## Best Practices

1. **After creating new Swift files**, run:
   ```bash
   python3 scripts/add_missing_files_to_project.py
   ```

2. **Before committing**, the pre-commit hook will automatically check for missing files

3. **If you manually add files in Xcode**, the script will detect they're already added and skip them

4. **For shared code** (in `{{SHARED_TARGET}}/`), the script automatically adds files to both iOS and Watch targets

## Troubleshooting

- If the script can't find a group for a file, it will skip it. You may need to:
  1. Ensure the file is in the correct directory structure
  2. Add the group manually in Xcode if it doesn't exist
  3. Check the script's group detection logic

- If the script makes incorrect changes, restore from backup:
  ```bash
  cp {{XCODE_PROJECT_NAME}}.xcodeproj/project.pbxproj.backup {{XCODE_PROJECT_NAME}}.xcodeproj/project.pbxproj
  ```


# App Store Icon Validation Errors - Fix Guide

## Issue Summary

Your App Store submission failed with **12 validation errors** related to app icons:

### Errors Found:

1. **iPhone App Icon** - Has alpha channel (transparency) ❌
2. **Watch App Icons** - 10 different icon sizes have alpha channels ❌
3. **Missing Watch Icon** - `108x108@2x.png` (Short Look 44mm) for Series 4 ❌

### Why This Happens

Apple requires all app icons to be **opaque** (no transparency). Icons with alpha channels are rejected because:

- App Store guidelines require solid backgrounds
- Icons need to render consistently across different contexts
- Transparent icons can cause visual issues on iOS/watchOS

## Solution

Run the automated fix script to:

1. Remove alpha channels from all icons (composite onto white background)
2. Create the missing 108x108@2x Watch icon
3. Update icon asset catalogs

### Step 1: Fix iPhone App Icons

```bash
cd {{PROJECT_ROOT}}
python3 scripts/icons/fix_app_store_icons.py "{{IOS_APP_TARGET}}/Assets.xcassets/AppIcon.appiconset"
```

### Step 2: Fix Watch App Icons (includes creating missing icon)

```bash
python3 scripts/icons/fix_app_store_icons.py "{{WATCH_APP_TARGET}}/Assets.xcassets/AppIcon.appiconset" watch
```

### Step 3: Verify in Xcode

1. Open your project in Xcode
2. Check `{{IOS_APP_TARGET}}/Assets.xcassets/AppIcon.appiconset` - all icons should have white backgrounds
3. Check `{{WATCH_APP_TARGET}}/Assets.xcassets/AppIcon.appiconset` - should include `icon_watch_216.png` (108x108@2x)

### Step 4: Clean Build and Resubmit

1. **Product** → **Clean Build Folder** (⇧⌘K)
2. **Product** → **Archive** (⌘B then Distribute)
3. Resubmit to App Store Connect

## What the Script Does

The `fix_app_store_icons.py` script:

1. **Removes Alpha Channels**: Composites all icons with transparency onto a white background
2. **Converts to RGB**: Ensures all icons are saved without alpha channels
3. **Creates Missing Icons**: Generates the 108x108@2x Watch icon from your 1024x1024 source
4. **Updates Contents.json**: Automatically adds the missing icon reference

## Manual Fix (Alternative)

If you prefer to fix icons manually:

### For Each Icon:

1. Open in Photoshop/Preview/etc.
2. Export as PNG without transparency
3. Ensure white background fills entire image
4. Save as RGB (not RGBA)

### For Missing 108x108 Icon:

1. Open your 1024x1024 Watch marketing icon
2. Resize to 216x216 pixels (108pt @2x scale)
3. Save as `icon_watch_216.png`
4. Add to `Plena Watch App/Assets.xcassets/AppIcon.appiconset/`
5. Update `Contents.json` to reference the new file

## Verification Checklist

Before resubmitting, verify:

- [ ] All iPhone app icons are opaque (no transparency)
- [ ] All Watch app icons are opaque (no transparency)
- [ ] `icon_watch_216.png` exists in Watch App icon set
- [ ] `Contents.json` references all icons correctly
- [ ] Project builds without warnings
- [ ] Archive creates successfully

## Technical Details

### Icon Requirements:

- **Format**: PNG
- **Color Mode**: RGB (not RGBA)
- **Alpha Channel**: Not allowed
- **Background**: Must be solid (typically white)

### Watch Icon Sizes Required:

- 48x48@2x (24pt) - Notification Center 38mm
- 55x55@2x (27.5pt) - Notification Center 42mm
- 58x58@2x (29pt) - Companion Settings
- 87x87@3x (29pt) - Companion Settings
- 80x80@2x (40pt) - App Launcher 38mm
- 88x88@2x (44pt) - App Launcher 40mm
- 100x100@2x (50pt) - App Launcher 44mm
- 172x172@2x (86pt) - Quick Look 38mm
- 196x196@2x (98pt) - Quick Look 42mm
- **216x216@2x (108pt) - Quick Look 44mm** ← MISSING (will be created)
- 1024x1024 - Marketing

## Common Issues

### "Icon still has transparency"

- Ensure you're using the fixed version (script overwrites originals)
- Try cleaning build folder and rebuilding

### "Missing icon still reported"

- Verify `Contents.json` has `"filename"` entry for 108x108
- Check that `icon_watch_216.png` exists in the directory
- Rebuild the project

### "Icons look wrong"

- The script uses white backgrounds - if your icons need different backgrounds, manually edit after running the script
- Original icons are NOT backed up - consider backing up before running if needed

## Support

If errors persist after running the script:

1. Check Xcode console for specific errors
2. Verify all icons are RGB (not RGBA) using Preview or `file` command
3. Ensure Contents.json is valid JSON
4. Clean derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData`

---

**Last Updated**: December 14, 2025
**Related Files**: `scripts/fix_app_store_icons.py`, `APP_STORE_NAME_OPTIONS.md`






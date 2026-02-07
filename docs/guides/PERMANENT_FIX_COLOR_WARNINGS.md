# Permanent Fix for PrimaryColor/SecondaryColor Warnings

## Problem
Xcode keeps generating warnings about PrimaryColor and SecondaryColor color assets that conflict with SwiftUI's built-in `Color.primary` and `Color.secondary`.

## Root Cause
These directories keep getting recreated, likely by:
1. Xcode's asset catalog editor
2. Some cached reference in Xcode
3. Asset catalog compilation process

## Permanent Solution

### Step 1: Remove Directories (Run this script)
```bash
./remove_color_assets.sh
```

### Step 2: Verify in Xcode
1. Open `Plena.xcodeproj` in Xcode
2. Navigate to `Plena/Assets.xcassets` in Project Navigator
3. **Manually check** if `PrimaryColor` or `SecondaryColor` appear in the asset list
4. If they appear, **right-click → Delete** them
5. Do the same for `Plena Watch App/Assets.xcassets`

### Step 3: Clean Build
1. Product → Clean Build Folder (Cmd+Shift+K)
2. Close Xcode
3. Delete DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData/Plena-*`
4. Reopen Xcode and rebuild

### Step 4: Prevent Recreation
If they keep coming back, they're likely being recreated by Xcode's asset catalog editor.
Check:
- Are you manually adding them in Xcode?
- Is there a template or migration that's adding them?
- Check Xcode's "Show in Finder" for the asset catalog to see what Xcode thinks is there

## Alternative: Exclude from Build
If they must exist for some reason, you can exclude them from the build:
1. Select the color asset in Xcode
2. In File Inspector, uncheck "Target Membership" for both targets
3. This prevents them from being compiled

## Verification
After fixing, check:
```bash
find Plena/Assets.xcassets Plena\ Watch\ App/Assets.xcassets -type d -name "*PrimaryColor*" -o -name "*SecondaryColor*" | grep -v "Text\|Plena"
```
Should return nothing.

## Current Status
- ✅ Directories removed
- ✅ No references in project.pbxproj
- ✅ DerivedData cleared
- ⚠️  If warnings persist, check Xcode's asset catalog editor manually

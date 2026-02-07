# Fix: Watch App Build Error - Missing SwiftData Models

## Problem

The Watch app can't find the SwiftData model classes because they're not added to the Watch app target.

## Solution: Add Files to Watch App Target

### Step 1: Locate the SwiftData Model File

1. In Xcode's **Project Navigator** (left sidebar)
2. Navigate to: **{{APP_NAME}}Shared** → **Models**
3. Find **`MeditationSessionData.swift`**

### Step 2: Add to Watch App Target

1. **Right-click** on `MeditationSessionData.swift`
2. Select **"Show File Inspector"** (or press **⌥⌘1** - Option + Command + 1)
3. In the right sidebar, find the **"Target Membership"** section
4. You'll see checkboxes for:
   - ☐ {{APP_NAME}} (iOS app)
   - ☐ {{APP_NAME}} Watch App (Watch app)
5. **Check the box** for **"{{APP_NAME}} Watch App"**
6. Also verify **"{{APP_NAME}}"** is checked (for iOS app)

### Step 3: Repeat for Other SwiftData Files

Do the same for these files (if they exist separately, or they're all in MeditationSessionData.swift):

- If `HeartRateSampleData`, `HRVSampleData`, etc. are in separate files, add them too
- If they're all in `MeditationSessionData.swift`, you only need to add that one file

### Step 4: Verify File is in Project

If you don't see `MeditationSessionData.swift` in the Project Navigator:

1. **Right-click** on the **"Models"** folder in **{{APP_NAME}}Shared**
2. Select **"Add Files to {{APP_NAME}}..."**
3. Navigate to: `{{APP_NAME}}Shared/Models/MeditationSessionData.swift`
4. In the dialog that appears:
   - ✅ Check **"Copy items if needed"** (probably unchecked is fine)
   - ✅ Under **"Add to targets"**, check:
     - **{{APP_NAME}}** (iOS app)
     - **{{APP_NAME}} Watch App** (Watch app)
5. Click **"Add"**

### Step 5: Build Again

1. Press **⌘B** (Command + B) to build
2. The errors should be resolved

## Alternative: Quick Fix via Project File

If the file isn't showing up, you can also:

1. Select the **blue "{{APP_NAME}}" project icon** in the navigator
2. Select **"{{APP_NAME}} Watch App"** target
3. Go to **"Build Phases"** tab
4. Expand **"Compile Sources"**
5. Click the **"+"** button
6. Search for `MeditationSessionData.swift`
7. Add it
8. Make sure it's checked for the Watch app target

## What to Check

After adding, verify:

- ✅ `MeditationSessionData.swift` appears in Project Navigator under {{APP_NAME}}Shared/Models
- ✅ File Inspector shows both targets checked ({{APP_NAME}} and {{APP_NAME}} Watch App)
- ✅ Build succeeds without "Cannot find in scope" errors

## If File Doesn't Exist

If `MeditationSessionData.swift` doesn't exist at all, it means the file wasn't created. The file should be at:

```
/Users/kennethnygren/Cursor/{{APP_NAME}}/{{APP_NAME}}Shared/Models/MeditationSessionData.swift
```

If it's missing, let me know and I can help recreate it.




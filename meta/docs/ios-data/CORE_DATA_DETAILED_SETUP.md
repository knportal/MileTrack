# Core Data Setup - Detailed Step-by-Step Guide

This guide provides detailed instructions for adding the Core Data model file to both iOS and watchOS targets.

## Prerequisites

- Xcode is open with the Plena project
- You have the `PlenaDataModel.xcdatamodeld` file (or need to create it)

---

## Step 1: Locate or Create the Core Data Model File

### Option A: If the file already exists

1. **Open Finder**
2. **Navigate to**: `/Users/kennethnygren/Cursor/Plena/PlenaShared/Models/`
3. **Look for**: `PlenaDataModel.xcdatamodeld` (it's a folder/package)
4. If it exists, proceed to Step 2
5. If it doesn't exist, go to Option B

### Option B: Create the Core Data Model File in Xcode

1. **In Xcode Project Navigator** (left sidebar):
   - Find and expand the **"PlenaShared"** folder
   - Find and expand the **"Models"** folder
   - If "Models" folder doesn't exist, right-click "PlenaShared" → "New Group" → name it "Models"

2. **Right-click on the "Models" folder** in Project Navigator
3. **Select**: "New File..." (or press ⌘N)
4. **In the template chooser**:
   - Scroll down to **"Core Data"** section
   - Select **"Data Model"**
   - Click **"Next"**
5. **Name the file**: `PlenaDataModel`
   - **Important**: Don't add `.xcdatamodeld` - Xcode adds it automatically
6. **Location**: Make sure it's saving to `PlenaShared/Models/`
7. **Click "Create"**

---

## Step 2: Add the Model File to Xcode Project

### Method 1: If file exists but isn't in Xcode

1. **In Xcode Project Navigator**:
   - Find the **"PlenaShared"** folder
   - Expand it to see **"Models"** folder

2. **Right-click on the "Models" folder** in Project Navigator
3. **Select**: "Add Files to 'Plena'..."
4. **In the file picker dialog**:
   - Navigate to: `PlenaShared/Models/`
   - Select **`PlenaDataModel.xcdatamodeld`**
   - **Important settings in the dialog**:
     - ✅ **Uncheck** "Copy items if needed" (file is already in the right place)
     - ✅ Under **"Add to targets"**, check **BOTH**:
       - ☑ **Plena** (iOS app)
       - ☑ **Plena Watch App** (watchOS app)
     - ✅ Make sure "Create groups" is selected (not "Create folder references")
5. **Click "Add"**

### Method 2: If you just created it in Xcode

The file should already be in the project, but you need to verify target membership (see Step 3).

---

## Step 3: Verify Target Membership for PlenaDataModel.xcdatamodeld

This is **critical** - the file must be in both targets.

1. **In Xcode Project Navigator**:
   - Find and **click on** `PlenaDataModel.xcdatamodeld`
   - It should be under `PlenaShared/Models/`

2. **Open the File Inspector**:
   - Click the **rightmost icon** in the right sidebar (looks like a document with lines)
   - Or press **⌥⌘1** (Option + Command + 1)
   - This opens the "File Inspector" panel

3. **Find "Target Membership" section**:
   - Scroll down in the File Inspector until you see **"Target Membership"**
   - You should see a list of checkboxes

4. **Verify both targets are checked**:
   - ☑ **Plena** (should be checked)
   - ☑ **Plena Watch App** (should be checked)

5. **If either is unchecked**:
   - **Click the checkbox** to check it
   - Xcode will automatically add the file to that target's build

6. **Visual confirmation**:
   - When a target is checked, you'll see a checkmark (✓)
   - Both should have checkmarks

---

## Step 4: Verify CoreDataStack.swift Target Membership

1. **In Xcode Project Navigator**:
   - Navigate to: `PlenaShared/Services/`
   - **Click on** `CoreDataStack.swift`

2. **Open File Inspector** (⌥⌘1 or right sidebar icon)

3. **Check "Target Membership"**:
   - ☑ **Plena** (should be checked)
   - ☑ **Plena Watch App** (should be checked)

4. **If not checked, check both boxes**

---

## Step 5: Verify CoreDataStorageService.swift Target Membership

1. **In Xcode Project Navigator**:
   - Navigate to: `PlenaShared/Services/`
   - **Click on** `CoreDataStorageService.swift`

2. **Open File Inspector** (⌥⌘1 or right sidebar icon)

3. **Check "Target Membership"**:
   - ☑ **Plena** (should be checked)
   - ☑ **Plena Watch App** (should be checked)

4. **If not checked, check both boxes**

---

## Step 6: Verify the Core Data Model Structure

1. **In Xcode Project Navigator**:
   - **Click on** `PlenaDataModel.xcdatamodeld` to open it
   - You should see the Core Data model editor

2. **Verify entities exist**:
   - In the left panel of the editor, you should see entities listed
   - Required entities:
     - ✅ `MeditationSessionEntity`
     - ✅ `HeartRateSampleEntity`
     - ✅ `HRVSampleEntity`
     - ✅ `RespiratoryRateSampleEntity`
     - ✅ `VO2MaxSampleEntity` (if VO2 Max is supported)
     - ✅ `TemperatureSampleEntity` (if Temperature is supported)
     - ✅ `StateOfMindLogEntity`

3. **If entities are missing**, you'll need to add them (see Core Data model documentation)

---

## Step 7: Set Codegen for Entities (if needed)

1. **In the Core Data model editor**:
   - **Click on** `PlenaDataModel.xcdatamodeld` in Project Navigator
   - The editor should open showing all entities

2. **For each entity**:
   - **Click on an entity** (e.g., `MeditationSessionEntity`)
   - **Open the Data Model Inspector** (right sidebar, or press ⌥⌘3)
   - Find **"Codegen"** dropdown
   - **Set it to**: **"Class Definition"**
   - This auto-generates the NSManagedObject subclasses

3. **Repeat for all entities**

---

## Step 8: Clean and Rebuild

1. **Clean Build Folder**:
   - Press **⌘ShiftK** (Command + Shift + K)
   - Or: Product → Clean Build Folder
   - Confirm if prompted

2. **Build the project**:
   - Press **⌘B** (Command + B)
   - Or: Product → Build

3. **Check for errors**:
   - Look at the Issue Navigator (left sidebar, triangle with exclamation mark)
   - If you see errors about missing Core Data entities, go back to Step 6

---

## Step 9: Verify It Works

1. **Run the iOS app**:
   - Select **"Plena"** scheme (top toolbar, next to the play button)
   - Press **⌘R** (Command + R)
   - App should launch without Core Data errors

2. **Run the Watch app**:
   - Select **"Plena Watch App"** scheme
   - Press **⌘R**
   - Watch app should launch without Core Data errors

3. **Check console output**:
   - If you see Core Data errors in the console, review the error message
   - The improved error handling will provide detailed diagnostics

---

## Troubleshooting

### Problem: "Cannot find 'PlenaDataModel' in scope"

**Solution**:
- The model file isn't added to the target
- Go back to Step 3 and verify target membership
- Make sure both "Plena" and "Plena Watch App" are checked

### Problem: "Core Data store failed to load"

**Solution**:
- Check the detailed error message in the console
- Common causes:
  1. Model file not in target → Fix: Step 3
  2. CloudKit container identifier mismatch → Check entitlements
  3. Missing entities → Go to Step 6

### Problem: File appears in Project Navigator but build fails

**Solution**:
- The file might be a "folder reference" instead of a "group"
- Remove it from project (right-click → Delete → "Remove Reference")
- Re-add it using Step 2, Method 1
- Make sure "Create groups" is selected (not "Create folder references")

### Problem: Watch app can't find Core Data entities

**Solution**:
- Verify `PlenaDataModel.xcdatamodeld` is in "Plena Watch App" target (Step 3)
- Verify `CoreDataStack.swift` is in "Plena Watch App" target (Step 4)
- Verify `CoreDataStorageService.swift` is in "Plena Watch App" target (Step 5)
- Clean and rebuild (Step 8)

---

## Quick Checklist

Before building, verify:

- [ ] `PlenaDataModel.xcdatamodeld` exists in `PlenaShared/Models/`
- [ ] `PlenaDataModel.xcdatamodeld` is in Project Navigator
- [ ] `PlenaDataModel.xcdatamodeld` has both targets checked (Step 3)
- [ ] `CoreDataStack.swift` has both targets checked (Step 4)
- [ ] `CoreDataStorageService.swift` has both targets checked (Step 5)
- [ ] Core Data model has required entities (Step 6)
- [ ] Codegen is set to "Class Definition" for entities (Step 7)
- [ ] Clean build performed (Step 8)

---

## Additional Resources

- Core Data Programming Guide: https://developer.apple.com/documentation/coredata
- Xcode Project File Management: https://developer.apple.com/documentation/xcode/organizing-your-source-files

---

## Summary

The key steps are:
1. **Add the model file** to the project
2. **Check both targets** in Target Membership
3. **Verify all Core Data files** are in both targets
4. **Clean and rebuild**

If you follow these steps carefully, Core Data should work for both iOS and watchOS apps.










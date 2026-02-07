# Add MeditationSessionData.swift to Xcode Project

## Problem

File exists but isn't properly added to Xcode project, so Target Membership doesn't show checkboxes.

## Solution: Add File to Project

### Step 1: Add File to Project

1. In Xcode's **Project Navigator** (left sidebar)
2. **Right-click** on the **"Models"** folder (inside PlenaShared)
3. Select **"Add Files to Plena..."**
4. Navigate to your project folder and find:
   - `PlenaShared/Models/MeditationSessionData.swift`
5. In the dialog that appears:
   - ✅ **Uncheck** "Copy items if needed" (file is already in the right place)
   - ✅ Under **"Add to targets"**, check **BOTH**:
     - ☑ **Plena** (iOS app)
     - ☑ **Plena Watch App** (Watch app)
   - ✅ Make sure **"Create groups"** is selected (not "Create folder references")
6. Click **"Add"**

### Step 2: Verify File Appears

1. The file should now appear in the Project Navigator under:
   - `PlenaShared` → `Models` → `MeditationSessionData.swift`
2. Select the file
3. Open **File Inspector** (⌥⌘1 or View → Inspectors → File)
4. In **"Target Membership"**, you should now see:
   - ☑ Plena
   - ☑ Plena Watch App
5. If not both checked, check them now

### Step 3: Build

1. Press **⌘B** to build
2. Errors should be resolved

## Alternative: If File Already Shows in Navigator

If the file already appears in the Project Navigator but Target Membership doesn't work:

1. **Remove** the file from project:
   - Right-click `MeditationSessionData.swift`
   - Select **"Delete"**
   - Choose **"Remove Reference"** (NOT "Move to Trash")
2. Then **re-add** it using Step 1 above

## If File Doesn't Appear in Add Files Dialog

If you can't find the file when browsing:

1. In Finder, navigate to: `/Users/kennethnygren/Cursor/Plena/PlenaShared/Models/`
2. Drag `MeditationSessionData.swift` from Finder into Xcode
3. Drop it into the **"Models"** folder in the Project Navigator
4. In the dialog:
   - ✅ Uncheck "Copy items if needed"
   - ✅ Check **BOTH** targets (Plena and Plena Watch App)
   - ✅ Select "Create groups"
5. Click **"Finish"**

## Verify It Worked

After adding:

- ✅ File appears in Project Navigator
- ✅ File Inspector shows checkboxes for both targets
- ✅ Both targets are checked
- ✅ Build succeeds (⌘B)




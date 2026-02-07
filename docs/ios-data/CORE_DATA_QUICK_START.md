# Core Data Quick Start Guide

## ✅ What's Been Done

1. ✅ Core Data model file created (`PlenaDataModel.xcdatamodeld`)
2. ✅ CoreDataStack created (manages persistent container)
3. ✅ CoreDataStorageService created (replaces SwiftDataStorageService)
4. ✅ All ViewModels updated to use Core Data
5. ✅ App entry points updated (removed SwiftData)
6. ✅ JSON migration logic updated

## 🔧 What You Need to Do in Xcode

### Critical Step: Add Core Data Model File

1. **In Xcode Project Navigator**, right-click on **"Models"** folder (in PlenaShared)
2. Select **"Add Files to Plena..."**
3. Navigate to: `PlenaShared/Models/`
4. Select **`PlenaDataModel.xcdatamodeld`**
5. In the dialog:
   - ✅ Uncheck "Copy items if needed"
   - ✅ Check **BOTH** targets:
     - ☑ Plena
     - ☑ Plena Watch App
6. Click **"Add"**

### Verify Files Are in Targets

Check these files have both targets checked:
- ✅ `CoreDataStack.swift`
- ✅ `CoreDataStorageService.swift`
- ✅ `PlenaDataModel.xcdatamodeld`

**How to check:**
- Select file → File Inspector (⌥⌘1)
- Under "Target Membership", both should be checked

### Set Codegen for Entities

1. Click on `PlenaDataModel.xcdatamodeld` in Project Navigator
2. You should see 5 entities listed
3. For each entity, in the **Data Model Inspector** (right sidebar):
   - Find **"Codegen"** dropdown
   - Set to **"Class Definition"**
   - This auto-generates NSManagedObject classes

## 🚀 Build and Run

1. **Clean build**: ⌘ShiftK
2. **Build**: ⌘B
3. **Run**: ⌘R

The app should now work with Core Data!

## 📋 What to Expect

- ✅ App launches without SwiftData errors
- ✅ Sessions can be created and saved
- ✅ Data persists after app restart
- ✅ JSON data automatically migrates on first launch
- ✅ Works on iOS 16.0+ devices

## 🎯 Next Steps

After confirming it works:
1. Test session creation
2. Verify data persistence
3. Test on Watch app
4. Import historical HealthKit data (when ready)

## ⚠️ If You See Errors

**"Cannot find type 'MeditationSessionEntity'"**
- Make sure `PlenaDataModel.xcdatamodeld` is added to the project
- Set Codegen to "Class Definition" for all entities
- Clean build (⌘ShiftK) and rebuild

**"Core Data store failed to load"**
- Check that model file is in both targets
- Verify model file name matches: `PlenaDataModel`

**Build errors about missing files**
- Check Target Membership for all Core Data files
- Both targets (Plena and Plena Watch App) must be checked





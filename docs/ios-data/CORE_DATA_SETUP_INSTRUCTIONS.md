# Core Data Setup Instructions

## Step 1: Add Core Data Model File to Xcode Project

The Core Data model file has been created at:
`PlenaShared/Models/PlenaDataModel.xcdatamodeld`

**You need to add it to Xcode:**

1. In Xcode, right-click on the **"Models"** folder (in PlenaShared)
2. Select **"Add Files to Plena..."**
3. Navigate to: `PlenaShared/Models/`
4. Select **`PlenaDataModel.xcdatamodeld`** (it's a folder, but Xcode will recognize it)
5. In the dialog:
   - ✅ Uncheck "Copy items if needed"
   - ✅ Under "Add to targets", check **BOTH**:
     - ☑ Plena
     - ☑ Plena Watch App
6. Click **"Add"**

## Step 2: Verify Model File in Xcode

After adding, you should see:
- `PlenaDataModel.xcdatamodeld` in Project Navigator
- When you click it, you should see 5 entities:
  - MeditationSessionEntity
  - HeartRateSampleEntity
  - HRVSampleEntity
  - RespiratoryRateSampleEntity
  - StateOfMindLogEntity

## Step 3: Set Codegen for Entities

1. Select `PlenaDataModel.xcdatamodeld` in Project Navigator
2. For each entity, in the Data Model Inspector (right sidebar):
   - Set **"Codegen"** to **"Class Definition"**
   - This auto-generates the NSManagedObject subclasses

## Step 4: Add Core Data Files to Targets

Make sure these files are added to both targets:

1. **CoreDataStack.swift** - Check both targets
2. **CoreDataStorageService.swift** - Check both targets
3. **PlenaDataModel.xcdatamodeld** - Check both targets

To verify:
- Select each file
- File Inspector → Target Membership
- Both "Plena" and "Plena Watch App" should be checked

## Step 5: Build and Test

1. **Clean build**: Press ⌘ShiftK
2. **Build**: Press ⌘B
3. **Run**: Press ⌘R

The app should now work with Core Data!

## What Changed

- ✅ Removed all SwiftData code
- ✅ Added Core Data model file
- ✅ Created CoreDataStack for persistent container
- ✅ Created CoreDataStorageService (replaces SwiftDataStorageService)
- ✅ Updated all ViewModels to use Core Data
- ✅ Automatic JSON migration on first launch

## Benefits

- ✅ Works on iOS 16.0+ (broader device support)
- ✅ More stable and proven
- ✅ Better performance
- ✅ More control over data model

## Next Steps

After setup:
1. Test session creation
2. Verify data persists after app restart
3. Test on Watch app
4. Import historical HealthKit data (when ready)





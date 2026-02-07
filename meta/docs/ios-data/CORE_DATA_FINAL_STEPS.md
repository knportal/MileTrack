# Core Data Setup - Final Steps

## ✅ What's Complete

- ✅ Core Data model file created and added to project
- ✅ All entities set to "Class Definition" (Codegen)
- ✅ CoreDataStack created
- ✅ CoreDataStorageService created
- ✅ All ViewModels updated
- ✅ App files updated (removed SwiftData)

## 🚀 Build and Test

### Step 1: Clean Build
1. Press **⌘ShiftK** (Command + Shift + K)
2. This clears any cached SwiftData files

### Step 2: Build
1. Press **⌘B** (Command + B)
2. Check for any errors

### Step 3: Run
1. Press **⌘R** (Command + R)
2. App should launch successfully!

## ✅ What to Expect

**On First Launch:**
- App launches without errors
- Console may show: "✅ Successfully migrated X sessions to Core Data" (if you had JSON data)
- No SwiftData errors

**Test Session Creation:**
1. Start a meditation session
2. Stop the session
3. Close and reopen the app
4. Session should still be there (data persisted!)

## 🔍 If You See Build Errors

### "Cannot find type 'MeditationSessionEntity'"
- **Solution**: Make sure `PlenaDataModel.xcdatamodeld` is added to both targets
- Verify Codegen is set to "Class Definition" for all entities
- Clean build (⌘ShiftK) and rebuild

### "Core Data store failed to load"
- **Solution**: Check model file name matches: `PlenaDataModel`
- Verify file is in both targets
- Delete app from device and reinstall

### "Use of unresolved identifier 'CoreDataStack'"
- **Solution**: Check `CoreDataStack.swift` is added to both targets
- File Inspector → Target Membership → Both checked

## 📋 Verify Everything Works

1. ✅ App launches
2. ✅ Can create meditation session
3. ✅ Session saves successfully
4. ✅ Data persists after app restart
5. ✅ Watch app works (if testing)

## 🎉 Success!

If the app runs without errors, Core Data migration is complete! You now have:
- ✅ Stable, proven data persistence
- ✅ Works on iOS 16.0+ devices
- ✅ Better performance
- ✅ All existing functionality preserved

## Next: Import Historical HealthKit Data

Once Core Data is working, you can use `HealthKitImportService` to import historical data. See `HEALTHKIT_IMPORT_USAGE.md` for details.





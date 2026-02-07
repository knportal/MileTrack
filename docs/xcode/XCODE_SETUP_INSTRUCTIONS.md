# Xcode Setup Instructions for SwiftData

## Step 1: Update Deployment Targets

1. Open `Plena.xcodeproj` in Xcode
2. Select the **Plena** project in the navigator
3. Select the **Plena** target (iOS app)
4. Go to **General** tab
5. Under **Deployment Info**, set:
   - **iOS**: `17.0`
6. Select the **Plena Watch App** target
7. Under **Deployment Info**, set:
   - **watchOS**: `10.0`

## Step 2: Enable CloudKit (Recommended)

CloudKit enables automatic data sync between iPhone and Watch.

1. Select the **Plena** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **CloudKit**
5. Xcode will automatically create a CloudKit container
6. Repeat for **Plena Watch App** target (use the same container)

### App Group Setup (Alternative/Additional)

If you prefer App Group file sharing instead of CloudKit:

1. Select the **Plena** target
2. Go to **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **App Groups**
5. Create a new group: `group.com.plena.meditation.app`
6. Repeat for **Plena Watch App** target (use the same group)
7. Update `PlenaWatchApp.swift` with your App Group identifier

## Step 3: Verify SwiftData Models

1. Build the project (⌘B)
2. Check for any compilation errors
3. The SwiftData models should compile without issues:
   - `MeditationSessionData`
   - `HeartRateSampleData`
   - `HRVSampleData`
   - `RespiratoryRateSampleData`
   - `StateOfMindLogData`

## Step 4: Test Migration

1. Run the app on a device
2. If you have existing JSON data, it will automatically migrate on first launch
3. Check console logs for migration status:
   - `✅ Successfully migrated X sessions to SwiftData`

## Step 5: Verify Data Persistence

1. Create a meditation session
2. Stop the session
3. Close and reopen the app
4. Verify the session is still present

## Troubleshooting

### "Could not create ModelContainer" Error

- Check that deployment targets are set correctly (iOS 17.0+, watchOS 10.0+)
- Verify all SwiftData models are properly imported
- Check that `@Model` macro is applied correctly

### CloudKit Sync Not Working

- Ensure CloudKit capability is enabled for both targets
- Check that both targets use the same CloudKit container
- Verify iCloud account is signed in on device
- Check device has internet connection

### Migration Not Running

- Check UserDefaults key: `hasMigratedToSwiftData`
- Verify JSON file exists at expected location
- Check console for migration error messages
- Migration only runs once - delete app and reinstall to test again

### Watch App Not Syncing

- Ensure both iPhone and Watch apps have CloudKit enabled
- Check that both use the same CloudKit container
- Verify Watch is paired and connected
- Wait a few minutes for initial sync

## Next Steps

- See `HEALTHKIT_IMPORT_USAGE.md` for importing historical data
- See `SWIFTDATA_SETUP_GUIDE.md` for advanced configuration
- See `DATA_PERSISTENCE_RECOMMENDATION.md` for architecture decisions




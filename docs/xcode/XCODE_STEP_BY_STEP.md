# Xcode Setup: Step-by-Step Guide

## Part 1: Update Deployment Targets

### Step 1.1: Open Your Project

1. Open `Plena.xcodeproj` in Xcode
2. Wait for the project to fully load

### Step 1.2: Update iOS Deployment Target

1. In the **Project Navigator** (left sidebar), click on the **blue "Plena" project icon** at the very top
2. In the main editor area, you'll see **"PROJECT"** and **"TARGETS"** sections
3. Under **"PROJECT"**, select **"Plena"** (the project, not the target)
4. Click on the **"Info"** tab at the top
5. Find **"iOS Deployment Target"** in the **"Deployment"** section
6. Change the value from `16.0` to **`17.0`**
7. Press Enter or click elsewhere to confirm

### Step 1.3: Update iOS Target Deployment Target

1. Still in the same view, look at the **"TARGETS"** section below
2. Select **"Plena"** (the iOS app target)
3. Click on the **"General"** tab
4. Scroll down to **"Deployment Info"** section
5. Find **"Minimum Deployments"** → **"iOS"**
6. Change from `16.0` to **`17.0`**

### Step 1.4: Update watchOS Deployment Target

1. Still in the **"TARGETS"** section
2. Select **"Plena Watch App"** (the watchOS app target)
3. Click on the **"General"** tab
4. Scroll down to **"Deployment Info"** section
5. Find **"Minimum Deployments"** → **"watchOS"**
6. Change from `9.0` to **`10.0`**

### Step 1.5: Verify Changes

1. Build the project: Press **⌘B** (Command + B)
2. Check for any errors
3. If you see errors about SwiftData or iOS 17, the deployment targets are correct

---

## Part 2: Enable CloudKit via iCloud Capability

**Important**: CloudKit is not a separate capability. It's enabled **within** the "iCloud" capability.

### Step 2.1: Enable iCloud (with CloudKit) for iOS App

1. In the **Project Navigator**, click on the **blue "Plena" project icon**
2. Under **"TARGETS"**, select **"Plena"** (iOS app)
3. Click on the **"Signing & Capabilities"** tab at the top
4. Click the **"+ Capability"** button in the top-left corner of the editor
5. In the search box, type **"iCloud"** (not "CloudKit")
6. Double-click **"iCloud"** or click the **"+ Add"** button
7. After adding iCloud, you'll see an **"iCloud"** section with checkboxes:
   - ✅ **Check the "CloudKit" checkbox** (this enables CloudKit)
   - (Optional) You can also check "Key-value storage" or "iCloud Documents")
8. Xcode will automatically:
   - Create a CloudKit container
   - Name it something like `iCloud.com.plena.app` (based on your bundle ID)

### Step 2.2: Note the Container Name

1. After checking "CloudKit", you'll see a **"CloudKit Containers"** section appear
2. Note the container name (usually `iCloud.com.plena.app` or similar)
3. **Write this down** - you'll need it for the Watch app

### Step 2.3: Enable iCloud (with CloudKit) for Watch App

1. Still in the **"TARGETS"** section
2. Select **"Plena Watch App"** (watchOS app)
3. Click on the **"Signing & Capabilities"** tab
4. Click the **"+ Capability"** button
5. Search for **"iCloud"** (not "CloudKit")
6. Double-click **"iCloud"** or click **"+ Add"**
7. **Check the "CloudKit" checkbox** in the iCloud section
8. **IMPORTANT**: In the **"CloudKit Containers"** section that appears:
   - Click the dropdown or **"+"** button
   - Select the **same container** you used for the iOS app
   - This ensures both apps share the same CloudKit database

### Step 2.4: Verify Both Targets Use Same Container

1. Select **"Plena"** target → **"Signing & Capabilities"** tab
2. Under "iCloud" section, verify:
   - ✅ CloudKit checkbox is checked
   - Container name is visible (e.g., `iCloud.com.plena.app`)
3. Select **"Plena Watch App"** target → **"Signing & Capabilities"** tab
4. Under "iCloud" section, verify:
   - ✅ CloudKit checkbox is checked
   - **Same container name** as iOS app
5. If different, click the container dropdown and select the same one

---

## Part 3: Verify Setup

### Step 3.1: Build the Project

1. Press **⌘B** (Command + B) to build
2. Wait for build to complete
3. Check for any errors or warnings

### Step 3.2: Check for SwiftData Errors

- If you see errors about `@Model` or SwiftData, verify:
  - iOS deployment target is 17.0
  - watchOS deployment target is 10.0
  - All SwiftData imports are present

### Step 3.3: Test on Device

1. Connect your iPhone (iOS 17+ required)
2. Select your device from the device dropdown
3. Press **⌘R** (Command + R) to run
4. The app should launch and migrate data on first run

---

## Troubleshooting

### Issue: "CloudKit container already exists"

- **Solution**: This is normal. Xcode may show a warning, but it will use the existing container.

### Issue: "No such module 'SwiftData'"

- **Solution**:
  1. Verify iOS deployment target is 17.0
  2. Clean build folder: **⌘ShiftK** (Command + Shift + K)
  3. Build again: **⌘B**

### Issue: Watch app can't find CloudKit container

- **Solution**:
  1. Make sure both targets have CloudKit capability enabled
  2. Verify both use the same container name
  3. Try removing and re-adding CloudKit capability to Watch app

### Issue: Deployment target won't change

- **Solution**:
  1. Make sure you're changing it in **both** PROJECT and TARGETS
  2. Some settings may be locked - unlock them first
  3. Close and reopen Xcode if needed

---

## Visual Guide (What You Should See)

### After Step 1 (Deployment Targets):

```
PROJECT: Plena
  └─ Info tab
      └─ iOS Deployment Target: 17.0

TARGETS:
  ├─ Plena
  │   └─ General tab
  │       └─ Deployment Info
  │           └─ iOS: 17.0
  │
  └─ Plena Watch App
      └─ General tab
          └─ Deployment Info
              └─ watchOS: 10.0
```

### After Step 2 (CloudKit):

```
TARGETS:
  ├─ Plena
  │   └─ Signing & Capabilities tab
  │       └─ CloudKit
  │           └─ Containers: iCloud.com.plena.app
  │
  └─ Plena Watch App
      └─ Signing & Capabilities tab
          └─ CloudKit
              └─ Containers: iCloud.com.plena.app (same!)
```

---

## Quick Checklist

- [ ] iOS deployment target set to 17.0 (in PROJECT)
- [ ] iOS deployment target set to 17.0 (in TARGETS → Plena)
- [ ] watchOS deployment target set to 10.0 (in TARGETS → Plena Watch App)
- [ ] CloudKit capability added to Plena target
- [ ] CloudKit capability added to Plena Watch App target
- [ ] Both targets use the same CloudKit container
- [ ] Project builds without errors (⌘B)
- [ ] App runs on device successfully

---

## Next Steps After Setup

1. **Test Migration**: Run the app and verify JSON data migrates to SwiftData
2. **Test CloudKit Sync**: Create a session on iPhone, check if it appears on Watch
3. **Import Historical Data**: Use `HealthKitImportService` to import past data
4. **Monitor Console**: Check for any SwiftData or CloudKit errors

---

## Need Help?

If you encounter any issues:

1. Check the console for specific error messages
2. Verify all steps were completed
3. Try cleaning the build folder (⌘ShiftK) and rebuilding
4. Check that your device is running iOS 17.0+ / watchOS 10.0+

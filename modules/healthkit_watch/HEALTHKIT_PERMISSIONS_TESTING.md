# HealthKit Permissions Testing Guide

This guide covers how to test the HealthKit permissions flow in {{APP_NAME}}.

## Overview

{{APP_NAME}} requests HealthKit permissions when:

1. **First meditation session start** - Permissions are requested automatically via `MeditationSessionViewModel.startSession()`
2. **Manual request** - Via Settings → Privacy → "Re-request Authorization" button

## Testing Scenarios

### Prerequisites

**On Real Device:**

- Requires a physical iPhone (HealthKit not available on simulator)
- For full testing, an Apple Watch paired to the iPhone is recommended
- Make sure the app has HealthKit capability enabled in Xcode

**On Simulator (Limited):**

- HealthKit authorization dialogs work on iOS 15+ simulators
- Sensor data won't be available, but permission flow can be tested

---

## Test Case 1: First-Time Permission Request

**Goal:** Test the initial permission request flow when user first starts a session.

### Steps:

1. **Reset app permissions:**

   - Delete the app from device/simulator
   - Reinstall the app
   - OR: Go to Settings → Privacy & Security → Health → {{APP_NAME}} → Turn OFF all permissions

2. **Trigger permission request:**

   - Open {{APP_NAME}} app
   - Accept disclaimer if shown
   - Navigate to meditation session (tap "Start Session" or equivalent)

3. **Expected Behavior:**

   - iOS should show HealthKit permission dialog
   - Dialog should list all requested data types:
     - Heart Rate (Read & Write)
     - HRV (Read & Write)
     - Respiratory Rate (Read & Write)
     - VO2 Max (Read)
     - Body Temperature (Read)
     - Mindful Session (Write)
     - Sleep Analysis (Read)
   - Console logs should show:
     ```
     📋 Requesting HealthKit authorization...
     ✅ HealthKit authorization request completed
     📊 Authorization Statuses: ...
     ```

4. **Test Both Responses:**
   - **Grant All:** Tap "Turn All Categories On" or enable all manually
   - **Deny Some:** Disable some categories (e.g., VO2 Max, Temperature)
   - **Deny All:** Tap "Don't Allow"

### Verification:

- Check console logs for authorization statuses
- After granting, session should start successfully
- After denying required permissions (Heart Rate, HRV, Respiratory Rate), session should show error message
- Optional permissions (VO2 Max, Temperature) denial should not block session start

---

## Test Case 2: Partially Granted Permissions

**Goal:** Test app behavior when some permissions are granted and others denied.

### Steps:

1. **Set up partial permissions:**

   - Settings → Privacy & Security → Health → {{APP_NAME}}
   - Enable: Heart Rate, HRV, Respiratory Rate (required)
   - Disable: VO2 Max, Temperature, Sleep Analysis (optional)

2. **Start session:**

   - Should start successfully
   - Required sensors should work
   - Optional sensors should not be available

3. **Verify console logs:**
   ```
   📊 Authorization Statuses:
      Heart Rate: 2 (Sharing Authorized)
      HRV: 2 (Sharing Authorized)
      Respiratory Rate: 2 (Sharing Authorized)
   ```

### Verification:

- Session starts without errors
- Only enabled sensors show data
- No error messages for missing optional permissions

---

## Test Case 3: Denied Required Permissions

**Goal:** Test error handling when required permissions are denied.

### Steps:

1. **Deny required permissions:**

   - Settings → Privacy & Security → Health → {{APP_NAME}}
   - Turn OFF: Heart Rate, HRV, or Respiratory Rate

2. **Start session:**

   - Should attempt to request authorization again
   - If still denied, should show error message

3. **Expected Error:**
   - Error message: "HealthKit permission denied. Please enable in Settings > Health > Data Access & Devices > {{APP_NAME}}"
   - Session should not start
   - Console should show: `❌ Required sensor permissions not authorized`

### Verification:

- User sees clear error message
- Error message provides path to fix the issue
- Session does not start
- No crashes or undefined behavior

---

## Test Case 4: Re-request Authorization

**Goal:** Test the manual re-request flow from Settings.

### Steps:

1. **Navigate to Settings:**

   - Open {{APP_NAME}} app
   - Go to Settings tab
   - Scroll to "Privacy" section

2. **Test buttons:**

   - **"Refresh Status"** button:

     - Tap to check current authorization status
     - Check console for status logs
     - Should show current state without requesting new permissions

   - **"Re-request Authorization"** button:
     - Tap to trigger permission dialog again
     - iOS will show permission dialog
     - User can change permissions

3. **After changing permissions:**
   - Tap "Refresh Status" to verify changes took effect

### Verification:

- Both buttons work correctly
- Status refresh doesn't show permission dialog
- Re-request shows permission dialog
- Changes are reflected after refresh

---

## Test Case 5: Opening Health Settings

**Goal:** Test the helper flow to guide users to Settings.

### Steps:

1. **Navigate to Settings → Privacy**
2. **Tap "Health Permissions"** button
3. **Expected:**

   - Alert dialog appears with instructions
   - Dialog explains how to enable permissions
   - "Open Settings" button available

4. **Tap "Open Settings":**

   - iOS Settings app should open
   - User is navigated to Health settings (may need to navigate manually to {{APP_NAME}})

5. **Manual navigation (if needed):**
   - Settings → Privacy & Security → Health → {{APP_NAME}}
   - Enable/disable permissions
   - Return to {{APP_NAME}} app

### Verification:

- Alert shows helpful instructions
- "Open Settings" button works
- Instructions are clear and actionable

---

## Test Case 6: Permission State Persistence

**Goal:** Verify permissions persist across app launches.

### Steps:

1. **Grant permissions:**

   - Complete Test Case 1 (grant all permissions)

2. **Close app completely:**

   - Swipe up and close {{APP_NAME}} from app switcher

3. **Reopen app:**

   - Launch {{APP_NAME}} again

4. **Start session:**
   - Should not show permission dialog again
   - Session should start immediately with granted permissions

### Verification:

- No permission dialog on subsequent launches
- Permissions are remembered
- Session starts without requesting again

---

## Test Case 7: Permission Changes While App Running

**Goal:** Test behavior when permissions change in Settings while app is running.

### Steps:

1. **Start with permissions granted:**

   - Grant all permissions
   - Start a meditation session

2. **Change permissions in Settings:**

   - Leave app running (background or foreground)
   - Settings → Privacy & Security → Health → {{APP_NAME}}
   - Disable Heart Rate (required permission)

3. **Return to app:**
   - If session was running, check behavior
   - Try to start a new session

### Verification:

- App handles permission revocation gracefully
- May need to re-request permissions for new sessions
- No crashes or undefined behavior

---

## Test Case 8: Optional Permissions Behavior

**Goal:** Verify optional permissions don't block core functionality.

### Optional Permissions:

- VO2 Max
- Body Temperature
- Sleep Analysis

### Steps:

1. **Grant only required permissions:**

   - Heart Rate: ON
   - HRV: ON
   - Respiratory Rate: ON
   - VO2 Max: OFF
   - Temperature: OFF
   - Sleep Analysis: OFF

2. **Start session:**

   - Should start successfully
   - Required sensors should work

3. **Check console:**
   - Should NOT show errors for missing optional permissions
   - Optional permission statuses should be logged but not block execution

### Verification:

- Core functionality works without optional permissions
- No error messages for optional permissions
- App gracefully handles missing optional data

---

## Test Case 9: Watch App Permissions

**Goal:** Test permissions on Apple Watch (if available).

### Steps:

1. **Install Watch app:**

   - Ensure Watch app is installed on paired Apple Watch

2. **Test permissions on Watch:**

   - HealthKit permissions are separate for Watch app
   - Start session from Watch app
   - Verify permission dialog appears on Watch

3. **Verify data flow:**
   - Watch app should have its own HealthKit permissions
   - Sessions started on Watch should sync to iPhone

### Verification:

- Watch app requests its own permissions
- Watch permissions work independently from iPhone
- Data syncs correctly between devices

---

## Debugging Tips

### Check Authorization Status

Use the `checkAuthorizationStatus()` method to log current state:

```swift
let healthKitService = HealthKitService()
healthKitService.checkAuthorizationStatus()
```

This will print detailed status for all data types in console.

### Authorization Status Values

- `0` = Not Determined (not yet requested)
- `1` = Sharing Denied (user denied)
- `2` = Sharing Authorized (user granted)

### Common Issues

1. **Permissions not showing:**

   - Ensure HealthKit capability is enabled in Xcode project settings
   - Check Info.plist has `NSHealthShareUsageDescription` and `NSHealthUpdateUsageDescription`
   - On simulator, use iOS 15+ for permission dialogs

2. **Permission dialog not appearing:**

   - Delete and reinstall app to reset permissions
   - Check if permissions were already requested (status won't be "Not Determined")
   - Use "Re-request Authorization" button in Settings

3. **Wrong permissions requested:**
   - Verify `readTypes` and `writeTypes` in `HealthKitService.swift`
   - Check that all required types are in the authorization request

---

## Automated Testing Notes

HealthKit permissions cannot be fully automated in unit tests because:

- Permission dialogs require user interaction
- iOS simulators may not fully support HealthKit
- System-level authorization state affects behavior

### Recommended Test Approach:

1. **Unit Tests:**

   - Mock `HealthKitServiceProtocol` to test ViewModel logic
   - Test error handling for different authorization states
   - Test permission status parsing

2. **UI Tests (Limited):**

   - Can test UI elements (buttons, alerts)
   - Cannot automate permission dialog interaction
   - Can verify error messages appear correctly

3. **Manual Testing:**
   - Use this guide for comprehensive manual testing
   - Test on real device for accurate behavior
   - Document results for each test case

---

## Checklist

Use this checklist when testing:

- [ ] First-time permission request works
- [ ] Permission dialog shows correct data types
- [ ] Granting all permissions allows session start
- [ ] Denying required permissions shows error
- [ ] Denying optional permissions doesn't block session
- [ ] Partial permissions work correctly
- [ ] "Refresh Status" button works
- [ ] "Re-request Authorization" button works
- [ ] "Open Settings" button works
- [ ] Permissions persist across app launches
- [ ] Console logs show correct status values
- [ ] Error messages are user-friendly
- [ ] Watch app permissions work (if applicable)

---

## Related Files

- `{{APP_NAME}}Shared/Services/HealthKitService.swift` - Main HealthKit service
- `{{APP_NAME}}Shared/ViewModels/MeditationSessionViewModel.swift` - Requests permissions on session start
- `{{APP_NAME}}/Views/SettingsView.swift` - Manual permission controls
- `{{APP_NAME}}/Info.plist` - Permission descriptions
- `{{APP_NAME}} Watch App/Info.plist` - Watch permission descriptions

---

## Additional Resources

- [Apple HealthKit Documentation](https://developer.apple.com/documentation/healthkit)
- [Requesting Authorization](https://developer.apple.com/documentation/healthkit/hkhealthstore/1614152-requestauthorization)
- [Authorization Status](https://developer.apple.com/documentation/healthkit/hkauthorizationstatus)









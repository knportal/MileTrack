# TestFlight Deployment Guide

**Last Updated:** December 14, 2025

## Pre-Deployment Checklist

### ✅ Critical Configuration

1. **Entitlements** - Update `aps-environment` to `production` (currently set to `development`)
2. **Version Numbers** - Currently set correctly:
   - Marketing Version: 1.0
   - Build Number: 1
3. **Bundle Identifiers** - Configured:
   - iOS: `{{BUNDLE_ID}}`
   - watchOS: `{{BUNDLE_ID}}.watchkitapp`
4. **HealthKit Permissions** - ✅ Properly configured in Info.plist
5. **CloudKit** - ✅ Configured in entitlements
6. **App Groups** - ✅ Configured for iPhone/Watch sync

### ✅ Code Quality

- ✅ Memory optimization completed (see `MEMORY_OPTIMIZATION_FIX.md`)
- ✅ Core features implemented and tested
- ✅ Minor TODOs only (non-blocking):
  - Share readiness score feature (future enhancement)
  - Age-adjusted thresholds (future enhancement)

### ⚠️ Pre-Deployment Actions Required

1. **Update Entitlements for Production**

   - Change `aps-environment` from `development` to `production` in `{{APP_NAME}}.entitlements`
   - This is required for TestFlight and App Store builds

2. **Verify Code Signing**

   - Ensure both iOS and watchOS targets have valid provisioning profiles
   - Use "Automatically manage signing" or configure manual profiles

3. **Test on Physical Devices**

   - Test iPhone app functionality
   - Test Watch app functionality
   - Test iPhone/Watch data sync
   - Test HealthKit permissions flow
   - Test with real meditation sessions

4. **Archive Build Configuration**
   - Ensure you're building with "Release" configuration
   - Verify optimization settings are appropriate

---

## Step-by-Step TestFlight Deployment

### Step 1: Update Entitlements

**File:** `{{APP_NAME}}/{{APP_NAME}}.entitlements`

Change:

```xml
<key>aps-environment</key>
<string>development</string>
```

To:

```xml
<key>aps-environment</key>
<string>production</string>
```

**Note:** If you're not using push notifications, you can remove this key entirely.

### Step 2: Clean Build

1. Open Xcode
2. Product → Clean Build Folder (Shift + Cmd + K)
3. Close and reopen Xcode (optional but recommended)

### Step 3: Configure Archive Settings

1. In Xcode, select the **{{APP_NAME}}** scheme (iOS app)
2. Product → Scheme → Edit Scheme
3. Select "Archive" in the left sidebar
4. Set Build Configuration to **Release**
5. Click "Close"

### Step 4: Create Archive

1. Select "Any iOS Device" or "Generic iOS Device" as destination
2. Product → Archive
3. Wait for the archive to complete (this may take a few minutes)
4. The Organizer window should open automatically

### Step 5: Validate Archive

1. In the Organizer window, select your archive
2. Click "Validate App"
3. Sign in with your Apple Developer account
4. Select your team
5. Choose "Automatically manage signing" or select your distribution certificate
6. Click "Next" and let Xcode validate
7. Fix any issues that appear (usually signing or missing capabilities)

### Step 6: Distribute to TestFlight

1. In the Organizer window, select your validated archive
2. Click "Distribute App"
3. Select "TestFlight & App Store"
4. Click "Next"
5. Choose distribution options:
   - **Upload**: Uploads to App Store Connect immediately
   - **Export**: Saves .ipa file locally (useful for manual upload)
6. Select "Upload" and click "Next"
7. Choose signing method (usually "Automatically manage signing")
8. Review the summary and click "Upload"
9. Wait for upload to complete (this may take 10-20 minutes)

### Step 7: Handle Watch App

**Important:** The Watch app will be included automatically if:

- Both targets are in the same Xcode project
- Watch app target is set as a dependency of the iOS app
- Both are archived together

If the Watch app doesn't appear:

1. Archive the Watch app separately (select Watch app scheme)
2. Upload it as a separate build
3. App Store Connect will associate them automatically

### Step 8: Process Build in App Store Connect

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to "My Apps" → Select "{{APP_NAME}}" (create app if needed)
3. Go to "TestFlight" tab
4. Wait for processing to complete (usually 10-30 minutes)
5. You'll see a notification when processing is done

### Step 9: Configure TestFlight

1. In TestFlight, select your build
2. Add build notes (e.g., "Initial beta release - Core meditation tracking features")
3. Add test information (optional but helpful for testers)
4. Set expiration date (default is 90 days)

### Step 10: Add Internal Testers

1. Go to "Internal Testing" section
2. Add internal testers (up to 100 people with App Store Connect access)
3. They'll receive an email invitation
4. Build becomes available immediately after processing

### Step 11: Add External Testers (Optional)

1. Go to "External Testing" section
2. Create a new group (e.g., "Beta Testers")
3. Add your build to the group
4. Add testers (up to 10,000)
5. Submit for Beta App Review (required for external testers)
   - This typically takes 24-48 hours
   - Apple reviews the app for basic compliance

---

## App Store Connect Setup (First Time)

If this is your first time deploying:

### 1. Create App Record

1. Go to App Store Connect → My Apps
2. Click "+" → "New App"
3. Fill in:
   - **Platform**: iOS
   - **Name**: {{APP_NAME}}
   - **Primary Language**: English (or your preference)
   - **Bundle ID**: `{{BUNDLE_ID}}` (must match Xcode)
   - **SKU**: Unique identifier (e.g., `plena-001`)
   - **User Access**: Full Access (or Limited if using team)
4. Click "Create"

### 2. Configure App Information

1. **App Information**:

   - Category: Health & Fitness
   - Subcategory: (optional)
   - Privacy Policy URL: https://{{DOMAIN}}/privacy-policy (required for TestFlight external testing)

2. **Pricing and Availability**:

   - Set price (Free or Paid)
   - Select countries/regions

3. **App Privacy** (Required):
   - Health & Fitness data: Yes
   - Data types collected: Health information
   - Purpose: App functionality, Analytics (if applicable)

### 3. HealthKit Compliance

Since your app uses HealthKit:

- Ensure privacy policy mentions HealthKit usage
- HealthKit data is not shared with third parties (unless disclosed)
- Users must explicitly grant permission

---

## Testing Checklist Before Beta Release

### Core Functionality

- [ ] App launches without crashes
- [ ] Disclaimer screen appears on first launch
- [ ] HealthKit permission request works
- [ ] Can start meditation session on iPhone
- [ ] Can start meditation session on Watch
- [ ] Real-time sensor data displays correctly
- [ ] Session data saves to Core Data
- [ ] Dashboard displays statistics correctly
- [ ] Data visualization charts render properly
- [ ] Readiness score calculates correctly
- [ ] iPhone/Watch data sync works (if CloudKit enabled)

### Edge Cases

- [ ] App handles missing HealthKit permissions gracefully
- [ ] App handles no sensor data available
- [ ] App handles background/foreground transitions
- [ ] Memory usage stays reasonable (test with 100+ sessions)
- [ ] App works with different iOS versions (17.0+)
- [ ] Watch app works independently and as companion

### User Experience

- [ ] UI is responsive and smooth
- [ ] No obvious UI bugs or layout issues
- [ ] Text is readable and properly localized (if applicable)
- [ ] Navigation is intuitive
- [ ] Error messages are user-friendly

---

## Common Issues & Solutions

### Issue: "Invalid Bundle" Error

**Solution:**

- Ensure bundle identifiers match exactly between Xcode and App Store Connect
- Check that all required capabilities are enabled
- Verify provisioning profiles are valid

### Issue: Watch App Not Included

**Solution:**

- Verify Watch app target is included in the iOS app's dependencies
- Check that both targets are in the same archive
- Manually archive and upload Watch app if needed

### Issue: HealthKit Not Working in TestFlight

**Solution:**

- HealthKit requires physical devices (not simulator)
- Ensure testers grant HealthKit permissions
- Verify entitlements are correctly configured

### Issue: Build Processing Fails

**Solution:**

- Check email notifications from Apple for specific errors
- Verify all required app icons are present
- Ensure minimum deployment targets are set correctly
- Check for deprecated APIs or missing required assets

---

## Post-Deployment

### Monitor TestFlight Feedback

1. Check TestFlight feedback regularly
2. Monitor crash reports in App Store Connect
3. Review tester comments and ratings
4. Track common issues reported

### Iterate Based on Feedback

1. Fix critical bugs reported by testers
2. Address usability concerns
3. Consider feature requests (prioritize carefully)
4. Prepare for next build

### Version Management

For subsequent builds:

- Increment build number (e.g., 1 → 2)
- Update marketing version if significant changes (e.g., 1.0 → 1.1)
- Update build notes with changes

---

## Next Steps After Successful Beta

1. **Gather Feedback**: Collect tester feedback for 1-2 weeks
2. **Fix Critical Issues**: Address any blocking bugs
3. **Prepare for App Store**: When ready, submit for App Store review
4. **Marketing Materials**: Prepare screenshots, description, keywords
5. **Privacy Policy**: Ensure privacy policy URL is live and accurate

---

## Resources

- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [TestFlight Documentation](https://developer.apple.com/testflight/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [HealthKit Guidelines](https://developer.apple.com/documentation/healthkit)

---

**Good luck with your TestFlight deployment! 🚀**

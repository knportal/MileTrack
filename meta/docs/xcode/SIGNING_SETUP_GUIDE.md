# Code Signing Setup Guide

## Recommended: Automatic Signing

For App Store and TestFlight submissions, **Automatic Signing is strongly recommended**.

### Why Automatic Signing?

✅ **Easier to manage** - Xcode handles certificates and provisioning profiles
✅ **Fewer errors** - Automatically fixes common signing issues
✅ **App Store optimized** - Works seamlessly with TestFlight and App Store Connect
✅ **Less maintenance** - Profiles update automatically when needed
✅ **Apple's recommendation** - Preferred method for App Store distribution

### When to Use Manual Signing

Only use Manual Signing if:

- Distributing via Enterprise program
- Using specific custom certificates
- Complex team setups with shared certificates
- Special security requirements

---

## Switching to Automatic Signing

### Step 1: Open Signing Settings

1. Open your project in Xcode
2. Select the **Plena** project in the navigator (blue icon at top)
3. Select the **Plena** target (iOS app)
4. Click **"Signing & Capabilities"** tab

### Step 2: Enable Automatic Signing for iOS App

1. ✅ **Check "Automatically manage signing"**
2. **Select your Team:** "Kenneth Nygren" (C8SXTF2Y53)
3. **Verify Bundle Identifier:** `com.plena.meditation.app`
4. Xcode will automatically:
   - Create/update provisioning profiles
   - Select appropriate certificates
   - Configure signing settings

### Step 3: Enable Automatic Signing for Watch App

1. Select **"Plena Watch App"** target
2. Click **"Signing & Capabilities"** tab
3. ✅ **Check "Automatically manage signing"**
4. **Select your Team:** "Kenneth Nygren" (C8SXTF2Y53)
5. **Verify Bundle Identifier:** `com.plena.meditation.app.watchkitapp`
6. **Verify Watch App Bundle ID** matches iPhone app (should auto-populate)

### Step 4: Verify Settings

**For Plena (iOS):**

- ✅ Automatically manage signing: **Enabled**
- Team: **Kenneth Nygren (C8SXTF2Y53)**
- Bundle Identifier: `com.plena.meditation.app`
- Provisioning Profile: **Xcode Managed Profile** (should appear automatically)
- Signing Certificate: **Apple Development / Apple Distribution** (auto-selected)

**For Plena Watch App:**

- ✅ Automatically manage signing: **Enabled**
- Team: **Kenneth Nygren (C8SXTF2Y53)**
- Bundle Identifier: `com.plena.meditation.app.watchkitapp`
- Provisioning Profile: **Xcode Managed Profile**
- Signing Certificate: **Apple Development / Apple Distribution**

### Step 5: Build and Test

1. **Product** → **Clean Build Folder** (⇧⌘K)
2. **Product** → **Build** (⌘B)
3. If you see warnings/errors, Xcode will usually offer to fix them automatically

---

## Troubleshooting Automatic Signing

### Issue: "No signing certificate found"

**Solution:**

1. Make sure you're logged into Xcode with your Apple ID
2. **Xcode** → **Preferences** → **Accounts**
3. Select your Apple ID → Click **"Manage Certificates..."**
4. Click **"+"** → **"Apple Development"** or **"Apple Distribution"**
5. Try building again

### Issue: "Provisioning profile can't be found"

**Solution:**

1. Ensure "Automatically manage signing" is checked
2. Select your team from the dropdown
3. Xcode will create/update the profile automatically
4. If still failing, clean derived data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```

### Issue: "Bundle identifier is already in use"

**Solution:**

- This means the bundle ID is already registered in App Store Connect (good!)
- Xcode should automatically use the existing App ID
- If not, verify bundle ID matches what's in App Store Connect: `com.plena.meditation.app`

### Issue: "Multiple targets require manual signing"

**Solution:**

1. Enable automatic signing for **both** targets:
   - Plena (iOS app)
   - Plena Watch App (watchOS app)
2. Make sure both have the same team selected
3. Watch app bundle ID must match the pattern: `{main-app-bundle-id}.watchkitapp`

### Issue: Watch app signing errors

**Common causes:**

- Watch app bundle ID doesn't follow required pattern
- Watch app entitlements missing
- Watch app not properly embedded in iOS app

**Solution:**

1. Verify Watch app bundle ID: `com.plena.meditation.app.watchkitapp`
2. Check "Embed Watch Content" build phase exists in iOS app target
3. Ensure Watch app is added as a dependency of iOS app
4. Both targets should use automatic signing with same team

---

## Verifying Signing Configuration

### Check in Xcode

1. **Product** → **Archive**
2. In Organizer window, select your archive
3. Click **"Distribute App"**
4. Choose **"App Store Connect"**
5. If it proceeds without signing errors, you're good!

### Check Provisioning Profiles

Automatic signing creates these profiles:

- **iOS App:**

  - Development: `iOS Team Provisioning Profile: com.plena.meditation.app`
  - Distribution: `App Store: com.plena.meditation.app`

- **Watch App:**
  - Development: `watchOS Team Provisioning Profile: com.plena.meditation.app.watchkitapp`
  - Distribution: `App Store: com.plena.meditation.app.watchkitapp`

**Location:** `~/Library/MobileDevice/Provisioning Profiles/`

You don't need to manage these manually - Xcode handles everything.

---

## Best Practices

1. **Always use Automatic Signing** for App Store/TestFlight
2. **Keep Xcode updated** - signing issues often fixed in updates
3. **Clean builds** when switching signing methods
4. **Verify team selection** - ensure correct team (individual vs organization)
5. **Check bundle identifiers** - must match App Store Connect exactly
6. **Archive before uploading** - catches signing issues early

---

## Signing Configuration Summary

### Current Setup (After Switching to Automatic)

**iOS App (Plena):**

- Signing: ✅ Automatic
- Team: Kenneth Nygren (C8SXTF2Y53)
- Bundle ID: `com.plena.meditation.app`
- Capabilities: HealthKit

**Watch App (Plena Watch App):**

- Signing: ✅ Automatic
- Team: Kenneth Nygren (C8SXTF2Y53)
- Bundle ID: `com.plena.meditation.app.watchkitapp`
- Capabilities: HealthKit

---

## Related Documentation

- [App Store Connect Setup](../setup/)
- [TestFlight Deployment Guide](../../support/TESTFLIGHT_DEPLOYMENT_GUIDE.md)
- [Pre-Deployment Checklist](../../PRE_DEPLOYMENT_CHECKLIST.md)

---

**Last Updated:** December 14, 2025
**For:** App Store / TestFlight Distribution






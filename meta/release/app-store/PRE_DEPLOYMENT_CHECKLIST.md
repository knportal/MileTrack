# Pre-Deployment Checklist

## Before Submitting to App Store

### ✅ 1. Fix App Icons (REQUIRED)

App Store submission was rejected due to icon issues. Run the icon fix script:

```bash
cd {{PROJECT_ROOT}}

# Fix iPhone icons (remove alpha channels)
python3 scripts/icons/fix_app_store_icons.py "{{IOS_APP_TARGET}}/Assets.xcassets/AppIcon.appiconset"

# Fix Watch icons (remove alpha channels + create missing 108x108 icon)
python3 scripts/icons/fix_app_store_icons.py "{{WATCH_APP_TARGET}}/Assets.xcassets/AppIcon.appiconset" watch
```

**Verify:**

- [ ] All icons are opaque (no transparency)
- [ ] `icon_watch_216.png` exists in Watch App icon set
- [ ] Contents.json references all icons correctly

**Reference:** See `APP_STORE_ICON_FIX.md` for details

---

### ✅ 2. Disable Test Data (COMPLETED)

Test data functionality is now hidden in Release builds.

**Status:** ✅ **Already Fixed**

- Test Data section only appears in DEBUG builds (when running from Xcode)
- **TestFlight/App Store builds use Release configuration** → Test Data will NOT appear
- Not visible to users in production builds

**Note:** If you see "Test Data" in Settings, you're running a Debug build (normal for development). TestFlight and App Store submissions use Release builds where it's hidden.

**Verify:**

- [ ] Archive using **Release** configuration (not Debug) - TestFlight does this automatically
- [ ] Settings view should NOT show "Test Data" section in TestFlight builds

---

### ✅ 3. App Store Name (RESOLVED)

App Store name "{{APP_NAME}}" may be taken. Consider alternative names if needed.

**Status:** ⚠️ **Check Availability**

- Check App Store Connect for name availability
- Consider alternative names if primary name is taken
- Bundle ID: `{{BUNDLE_ID}}` (set in Xcode project)

**Note:** Users will see "{{APP_NAME}}" on their devices (set in Info.plist)

**Reference:** See `APP_STORE_NAME_OPTIONS.md` for details

---

### ✅ 4. Build Configuration

Ensure you're building with correct settings:

- [ ] **Scheme:** Use "Release" configuration for Archive
- [ ] **Signing:** Automatic signing enabled
- [ ] **Team:** Correct team selected
- [ ] **Version:** 1.0 (CFBundleShortVersionString)
- [ ] **Build:** 1 (CFBundleVersion)

---

### ✅ 5. Clean Build

Before archiving:

1. **Product** → **Clean Build Folder** (⇧⌘K)
2. Close Xcode
3. Delete Derived Data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
4. Reopen Xcode
5. **Product** → **Archive**

---

### ✅ 6. Final Verification

#### Code Checks:

- [ ] No test/debug code in release build
- [ ] All TODO/FIXME comments addressed or removed
- [ ] No hardcoded test data or credentials
- [ ] Console logs use appropriate levels (not excessive in production)

#### Asset Checks:

- [ ] All app icons are opaque (RGB, not RGBA)
- [ ] All required icon sizes present
- [ ] App icon appears correctly in Xcode

#### Configuration Checks:

- [ ] Privacy Policy URL is valid: `{{PRIVACY_POLICY_URL}}`
- [ ] Support email configured: `{{SUPPORT_EMAIL}}`
- [ ] HealthKit usage descriptions present in Info.plist (if using HealthKit)
- [ ] Bundle identifier matches App Store Connect: `{{BUNDLE_ID}}`

#### Functionality Checks:

- [ ] App launches successfully
- [ ] HealthKit permissions request works
- [ ] Core features function correctly
- [ ] Watch app pairs and syncs properly

---

### ✅ 7. Archive & Upload

1. **Product** → **Archive**
2. Wait for archive to complete
3. **Distribute App** → **App Store Connect**
4. **Upload** (not Export)
5. Wait for upload and processing to complete
6. Check App Store Connect for any validation errors

---

### ✅ 8. App Store Connect Setup

Complete all required fields in App Store Connect:

**App Information:**

- [ ] Name: "{{APP_NAME}}" (or alternative if taken)
- [ ] Subtitle: "{{APP_SUBTITLE}}" (30 characters max)
- [ ] Category: {{PRIMARY_CATEGORY}} (Primary), {{SECONDARY_CATEGORY}} (Secondary)

**Version Information:**

- [ ] Version: 1.0
- [ ] Short description (170 chars max)
- [ ] Full description (4000 chars max)
- [ ] Keywords (100 chars max)
- [ ] Promotional text (optional, 170 chars max)

**Screenshots:**

- [ ] iPhone 6.7" (1290 x 2796)
- [ ] iPhone 6.5" (1242 x 2688)
- [ ] Apple Watch Series 7 (396 x 484)
- [ ] Apple Watch Series 4 (368 x 448)

**Support Information:**

- [ ] Privacy Policy URL: `{{PRIVACY_POLICY_URL}}`
- [ ] Support URL: `{{SUPPORT_URL}}`
- [ ] Support email: `{{SUPPORT_EMAIL}}`

**Age Rating:**

- [ ] Complete questionnaire (likely 4+)

**Reference:** See `documents/APP_STORE_METADATA.md` for all content

---

## Common Issues & Solutions

### Issue: Icon validation errors

**Solution:** Run icon fix script (see step 1)

### Issue: "App Name already in use"

**Status:** ✅ Already resolved - using "Plena Biofeedback"

### Issue: Build fails with signing errors

**Solution:**

- Verify team and bundle ID in project settings
- Clean build folder and derived data
- Ensure certificates/profiles are valid

### Issue: Watch app not included

**Solution:**

- Ensure Watch app target is included in archive
- Check "Embed Watch Content" build phase exists

### Issue: Missing entitlements

**Solution:**

- Verify HealthKit capability enabled
- Check both iPhone and Watch app entitlements

---

## Post-Submission

After successful upload:

1. ✅ Wait for processing (usually 10-30 minutes)
2. ✅ Check App Store Connect → TestFlight for build status
3. ✅ Add build to App Store version
4. ✅ Complete all App Store listing information
5. ✅ Submit for review

**Estimated Review Time:** 1-3 days (typically 24-48 hours)

---

## Need Help?

- **Icon Issues:** See `APP_STORE_ICON_FIX.md`
- **App Name Issues:** See `APP_STORE_NAME_OPTIONS.md`
- **App Store Metadata:** See `documents/APP_STORE_METADATA.md`
- **TestFlight Guide:** See `support/TESTFLIGHT_DEPLOYMENT_GUIDE.md`

---

**Last Updated:** December 14, 2025
**Version:** 1.0






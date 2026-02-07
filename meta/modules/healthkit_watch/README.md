# HealthKit & Apple Watch Module

This optional module contains documentation and templates specific to apps that use:
- **HealthKit** framework for health data
- **Apple Watch** companion apps

## Contents

### Privacy & Compliance
- `APP_STORE_PRIVACY_DISCLOSURE.md` - Detailed privacy disclosure guide for App Store Connect
- `APP_STORE_PRIVACY_QUICK_REFERENCE.md` - Quick reference checklist for privacy settings

### Testing
- `HEALTHKIT_PERMISSIONS_TESTING.md` - Guide for testing HealthKit permissions
- `HEALTHKIT_QUICK_TEST.md` - Quick testing checklist

### Troubleshooting
- `FIX_WATCH_BUILD_ERROR.md` - Common Watch app build issues and fixes

## When to Use This Module

Copy this module into your project if:
- ✅ Your app reads/writes HealthKit data
- ✅ Your app has an Apple Watch companion app
- ✅ You need App Store privacy disclosure guidance for health data
- ✅ You need Watch-specific build troubleshooting

## Integration

1. Copy the entire `modules/healthkit_watch/` folder to your project
2. Replace placeholders (see main `PLACEHOLDERS.md`)
3. Reference these docs when:
   - Setting up App Store privacy disclosures
   - Testing HealthKit permissions
   - Troubleshooting Watch app builds

## Additional Resources

- [Apple HealthKit Documentation](https://developer.apple.com/documentation/healthkit)
- [Apple Watch Development](https://developer.apple.com/watchos/)
- [App Store Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)

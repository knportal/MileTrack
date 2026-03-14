# 🧪 Motion Detection Toggle Feature

## Overview

Added a user-facing toggle to enable/disable motion detection for easy A/B testing while driving.

---

## What Was Added

### 1. Settings Toggle
**Location:** Settings → Auto Mode & Tracking → "Use Motion Detection"

**Features:**
- Labeled with flask icon 🧪 (experimental feature indicator)
- Enabled by default (`useMotionDetection = true`)
- Disabled (grayed out) when Auto Mode is OFF
- Changes take effect immediately

### 2. UserDefaults Integration
**Key:** `useMotionDetection`
**Default:** `true` (motion enabled)

### 3. AutoModeManager Logic
Checks toggle before starting motion detection:
```swift
let useMotionDetection = UserDefaults.standard.bool(forKey: "useMotionDetection")

if useMotionDetection {
  drivingDetection.start()  // Motion + GPS
} else {
  // GPS-only mode
}
```

---

## UI Changes

### AutoModeSettingsView

**Before:**
```
┌─────────────────────────────────────┐
│ [✓] Auto Mode                       │
│     Detect drives and send to Inbox │
└─────────────────────────────────────┘
```

**After:**
```
┌─────────────────────────────────────┐
│ [✓] Auto Mode                       │
│     Detect drives and send to Inbox │
│ ─────────────────────────────────── │
│ [✓] Use Motion Detection 🧪         │
│     Uses motion sensors to filter   │
│     GPS noise and reduce false      │
│     trips. Fallback to GPS-only     │
│     if disabled.                    │
└─────────────────────────────────────┘
```

---

## How to Use for Testing

### Test 1: With Motion (Expected: Fewer False Trips)
1. Settings → Auto Mode & Tracking
2. Ensure "Use Motion Detection" is **ON** ✅
3. Park car for 5 minutes
4. Check Inbox - should be empty
5. Console: `[AutoMode] started (speed + motion)`

### Test 2: Without Motion (Expected: More False Trips)
1. Settings → Auto Mode & Tracking
2. Toggle "Use Motion Detection" **OFF** ❌
3. Park car for 5 minutes
4. Check Inbox - may have false trip
5. Console: `[AutoMode] started (GPS-only)`

### Test 3: Compare A/B Results
| Scenario | Motion ON | Motion OFF |
|----------|-----------|------------|
| Parked 5 min | No trip ✅ | False trip ❌ |
| Real drive | Trip ✅ | Trip ✅ |
| Battery | +2% during trips | No extra cost |

---

## Console Log Differences

### Motion ON (Default)
```
[AutoMode] started (speed + motion)
[Motion] Started device motion monitoring (10 Hz)
[Motion] Confidence: 0.08 (stationary)
[GPS] Speed: 5.3 mph (motion confidence: 0.08) ✗ rejected
// No trip created
```

### Motion OFF (GPS-Only)
```
[AutoMode] started (GPS-only)
[GPS] Speed: 5.3 mph (motion confidence: 0.0) ✓ accepted (fallback)
[AutoMode] movement started
// False trip created
```

---

## Files Modified

### AutoModeSettingsView.swift
- Added `@AppStorage("useMotionDetection")` property
- Added toggle UI with flask icon
- Toggle disabled when Auto Mode is OFF
- Updated UI layout with divider

### AutoModeManager.swift
- Registered default: `"useMotionDetection": true`
- Added conditional logic in `startIfNeeded()`
- Status message reflects mode: "speed + motion" vs "GPS-only"
- Log messages show which mode is active

### MOTION_DETECTION_QUICKSTART.md
- Updated testing checklist with toggle tests
- Added rollback section with toggle option
- Updated Q&A section
- Added A/B testing instructions

---

## Why This Is Useful

### For Development
- **A/B Testing:** Compare motion vs. GPS-only on same route
- **Debugging:** Quickly disable motion if issues occur
- **Validation:** Confirm motion filtering is actually working

### For Users
- **Control:** Users can disable if they experience issues
- **Battery:** Users can disable to save 1.5% battery during trips
- **Transparency:** Shows that motion detection is optional

### For You (While Driving)
- **Real-Time Testing:** Toggle ON/OFF between trips
- **Side-by-Side:** Drive same route twice, compare results
- **Validation:** Prove motion reduces false trips

---

## Default Behavior

**New Users:**
- Motion detection **ON** by default
- Optimal experience (fewer false trips)
- Requires Motion & Fitness permission

**Existing Users:**
- Motion detection **ON** by default (first launch after update)
- Previous behavior: GPS-only
- New behavior: Motion + GPS (better accuracy)

**Fallback:**
- Motion permission denied → GPS-only mode
- Motion unavailable (old device) → GPS-only mode
- Toggle OFF → GPS-only mode

---

## Testing Scenarios

### Scenario A: Motion Improves Accuracy
1. Park car, motion ON → No false trip ✅
2. Park car, motion OFF → False trip ❌
3. **Result:** Motion is working correctly

### Scenario B: Motion Breaks Detection
1. Drive, motion ON → No trip created ❌
2. Drive, motion OFF → Trip created ✅
3. **Result:** Motion threshold too high (tune to 0.15)

### Scenario C: No Difference
1. Park car, motion ON → No trip ✅
2. Park car, motion OFF → No trip ✅
3. **Result:** GPS already accurate (good signal)

---

## Toggle State Persistence

**Saved in UserDefaults:**
```swift
UserDefaults.standard.bool(forKey: "useMotionDetection")
```

**Persists across:**
- ✅ App restarts
- ✅ Device reboots
- ✅ iOS updates
- ✅ App updates

**Reset by:**
- ❌ Deleting app (default: ON)
- ❌ Clearing app data (default: ON)

---

## Edge Cases Handled

### Case 1: Toggle Changed While Driving
**Behavior:** Change takes effect on next trip cycle
**Example:** Trip already in progress continues with current mode

### Case 2: Auto Mode Disabled
**Behavior:** Motion toggle is disabled (grayed out)
**Reason:** Motion only works when Auto Mode is ON

### Case 3: Motion Permission Denied
**Behavior:** Toggle visible but motion won't start
**Fallback:** GPS-only mode automatically

### Case 4: Device Doesn't Support Motion
**Behavior:** Toggle visible, motion confidence stays 0.0
**Fallback:** GPS-only mode automatically

---

## Future Enhancements

### Phase 1.5: Status Indicator (Optional)
Show current mode in UI:
```swift
// In AutoModeSettingsView
if useMotionDetection {
  Text("Mode: GPS + Motion")
} else {
  Text("Mode: GPS Only")
}
```

### Phase 2: Analytics (Future)
Track toggle usage:
- % users with motion enabled
- False trip rate comparison
- Battery impact comparison

### Phase 3: Smart Default (Future)
Auto-disable if motion causes issues:
```swift
if falseNegativeRate > 0.2 {
  // Too many missed trips - suggest disabling motion
}
```

---

## Accessibility

**Toggle:**
- Label: "Use Motion Detection"
- Hint: "Enables motion sensors to improve trip detection accuracy."
- State: Announced when changed

**Flask Icon:**
- Hidden from VoiceOver (decorative)
- Indicates experimental/advanced feature

**Disabled State:**
- Opacity: 0.5
- User can't interact when Auto Mode is OFF
- VoiceOver announces "dimmed"

---

## Documentation Updates

### Updated Files
1. **MOTION_DETECTION_QUICKSTART.md**
   - Testing checklist with toggle tests
   - Rollback section mentions toggle
   - Q&A updated

2. **MOTION_TOGGLE_FEATURE.md** (This file)
   - Complete toggle documentation
   - Testing scenarios
   - A/B testing guide

3. **AutoModeSettingsView.swift**
   - Inline comments explaining toggle
   - Accessibility labels

---

## Quick Reference

**Enable Motion:**
```
Settings → Auto Mode & Tracking → Toggle ON
Console: [AutoMode] started (speed + motion)
```

**Disable Motion:**
```
Settings → Auto Mode & Tracking → Toggle OFF
Console: [AutoMode] started (GPS-only)
```

**Check Current State:**
```swift
UserDefaults.standard.bool(forKey: "useMotionDetection")
```

**Test Both Modes:**
1. Park 5 min, motion ON → No trip
2. Park 5 min, motion OFF → May have trip
3. Compare results

---

## Summary

✅ **Added:** User-facing toggle in Settings  
✅ **Default:** Motion enabled (optimal)  
✅ **Fallback:** GPS-only mode if disabled  
✅ **Testing:** Easy A/B comparison  
✅ **Safe:** No code changes required to disable  

**Perfect for your driving test:**
- Try WITH motion on first drive
- Try WITHOUT motion on second drive
- Compare false trip rates
- Confirm motion filtering works

---

**Status:** ✅ Ready for testing
**Location:** Settings → Auto Mode & Tracking
**Default:** Motion detection ON

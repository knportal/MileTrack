# App Store Connect Testing - Test Details

## What to Test

{{APP_NAME}} tracks your biometric data during mindfulness sessions. Test the following:

### iPhone App

**First Launch:**
- Accept disclaimer, grant HealthKit permissions (read: heart rate, HRV, respiratory rate, temperature, VO2 Max; write: mindfulness sessions)
- Verify graceful handling if permissions denied

**mindfulness sessions:**
- Start session from Session tab
- Verify real-time biometric tracking (heart rate, HRV, respiratory rate)
- Check stress zones update (Blue=Calm, Green=Optimal, Orange=Elevated)
- Stop session, verify it saves
- Log "State of Mind" after session
- Confirm session appears in history

**Dashboard:**
- Check statistics (total sessions, session time, streak)
- Test time ranges: Day, Week, Month, Year
- Verify charts display correctly
- Check HRV insights appear with sufficient data
- Test session frequency and duration trends

**Data Visualization:**
- Navigate Data tab, test time ranges
- Verify sensor charts display correctly
- Check range indicators (above/normal/below)
- Test Consistency and Trend view modes

**Readiness Score:**
- Verify daily score calculates correctly
- Check contributor breakdowns (Resting HR, HRV Balance, Temperature, Recovery, Sleep)
- Compare today vs yesterday

### Apple Watch App

**Watch Launch:**
- Launch app on Watch, verify independent operation
- Check HealthKit permissions sync from iPhone

**Watch Sessions:**
- Start session from Watch
- Verify 3-2-1 countdown appears
- Check real-time sensor readings display
- Scroll through sensors during session
- Verify stress zone indicators
- Stop session, confirm syncs to iPhone

**Watch Dashboard:**
- Check statistics display correctly
- Verify data syncs from iPhone sessions

### Data Sync & Persistence

- Start session on Watch, verify appears on iPhone (and vice versa)
- Check CloudKit sync works (if enabled)
- Verify data persists after app restarts
- Test importing existing HealthKit session data

### Edge Cases

- Test with no HealthKit data available
- Verify graceful handling of missing sensors (older Watch models)
- Test with partial HealthKit permissions
- Test with iCloud/CloudKit disabled
- Watch compatibility: Series 4+ (HRV), Series 6+ (Respiratory), Series 8/Ultra+ (Temperature)

### UI/UX

- Test all tab navigation (Session, Dashboard, Data)
- Verify smooth transitions, back buttons work
- Check stress zone colors are clear
- Verify charts are readable and interactive
- Test app launch speed, session start/stop responsiveness
- Check scrolling performance in data views

### Known Limitations

- HealthKit requires physical devices (simulators won't work)
- Sensor availability depends on Watch model
- First session may take a moment to establish readings

### What to Report

Please report: crashes/freezes, incorrect biometric readings, sessions not saving/syncing, unresponsive UI, chart display issues, permission problems, Watch-iPhone sync failures, confusing UI elements.

### Test Duration

Test over 2-3 days to complete multiple sessions, verify data persistence, check streak tracking, and validate readiness scores with real data.

Thank you for testing {{APP_NAME}}!

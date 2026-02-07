# App Store Connect Test Details

## What to Test

Thank you for testing {{APP_NAME}}! This meditation tracking app uses biometric sensors to help you understand how your body responds to meditation. Please test the following areas:

### Initial Setup & Permissions
- **HealthKit Permissions**: When you first launch the app, grant HealthKit permissions for heart rate, HRV, respiratory rate, temperature, and VO₂ Max. Verify the app requests permissions appropriately.
- **First Launch**: Check that the onboarding flow works smoothly and the app explains what data it needs.

### Core Meditation Session (iPhone)
- **Start a Session**: Tap "Start Session" and verify the 3-2-1 countdown appears before tracking begins.
- **Real-Time Tracking**: During a 2-5 minute meditation session, verify that:
  - Heart rate readings update in real time
  - HRV (SDNN) values display correctly (if your device supports it)
  - Respiratory rate shows accurate readings (Series 6+ watches)
  - Stress zones change color based on your biometrics (Blue=Calm, Green=Optimal, Orange=Elevated)
- **End Session**: Stop the session and verify a summary screen appears with session statistics.

### Apple Watch App
- **Watch Independence**: Start a meditation session directly from the Watch app (without iPhone nearby).
- **Sensor Display**: During a session, swipe to scroll through different sensor readings (heart rate, HRV, respiratory rate).
- **Zone Indicators**: Verify the stress zone colors display correctly on the Watch face.
- **Session Control**: Test starting and stopping sessions from the Watch.

### Dashboard & Statistics (iPhone)
- **Session Stats**: Verify total sessions, total meditation time, and current streak display correctly.
- **Time Ranges**: Test switching between Day, Week, Month, and Year views.
- **Charts**: Check that session frequency charts and duration trends display properly.
- **HRV Insights**: Review any personalized insights about your heart rate variability trends.

### Data Visualization (iPhone)
- **Interactive Graphs**: Navigate to the Data tab and verify:
  - Individual sensor charts (heart rate, HRV, respiratory rate, temperature, VO₂ Max)
  - Time-based views (day, week, month, year) work correctly
  - Range indicators show whether values are above/normal/below expected ranges
- **Trend Analysis**: Check that trend statistics and insights display accurately.

### Readiness Score (iPhone)
- **Daily Score**: Verify the readiness score calculates and displays correctly.
- **Contributors**: Check that contributor breakdowns (Resting Heart Rate, HRV Balance, Body Temperature, Recovery Index, Sleep) show accurate information.
- **Historical Comparison**: Verify today vs yesterday comparison works.

### Data Sync & Persistence
- **Session Saving**: Complete a meditation session and verify it appears in your session history.
- **CloudKit Sync** (if enabled): Start a session on iPhone, then check if it appears on Watch (or vice versa) after sync completes.
- **Historical Import**: If you have existing HealthKit meditation data, verify the app can import it.

### Edge Cases & Known Limitations
- **Device Compatibility**: Note which sensors are available on your device:
  - Heart Rate: All Apple Watch models (Series 1+)
  - HRV: Series 4 or later required
  - Respiratory Rate: Series 6 or later required
  - Temperature: Series 8/Ultra or later required
- **Missing Permissions**: Test what happens if you deny HealthKit permissions - the app should handle this gracefully.
- **No Watch**: Verify the iPhone app works independently without an Apple Watch.
- **Background Behavior**: Start a session, then switch to another app briefly - verify the session continues tracking.

### Performance & Stability
- **App Launch**: Check that the app launches quickly and smoothly.
- **During Sessions**: Verify no lag or freezing during active meditation tracking.
- **Battery Impact**: Note if the app causes excessive battery drain during sessions.
- **Crash Testing**: Use the app normally and report any crashes or freezes.

### User Experience
- **UI Clarity**: Verify all text is readable and UI elements are intuitive.
- **Navigation**: Test that moving between tabs (Dashboard, Data, Settings) feels smooth.
- **Visual Feedback**: Check that stress zone colors and indicators are clear and helpful.

## What to Report

Please report:
- ✅ **What works well**: Features that function as expected
- ❌ **Bugs**: Any crashes, freezes, or incorrect behavior
- 💡 **Suggestions**: Ideas for improvements or missing features
- 📱 **Device Info**: Your iPhone and Apple Watch models, iOS/watchOS versions
- 🔋 **Performance**: Any battery or performance concerns

## Important Notes

- **Physical Device Required**: HealthKit features do not work in simulators. Please test on real devices.
- **Watch Models**: Different Apple Watch models support different sensors. The app adapts to your watch's capabilities.
- **Privacy**: All health data stays on your device or in your iCloud account. No data is sent to external servers.

Thank you for your thorough testing!


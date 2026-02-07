# Plena Support

**Purpose:** This folder contains support website content - user-facing documentation designed for a support website or help center.

**Note:** This is separate from the `documents/` folder, which contains project documentation for developers and App Store submission.

Welcome to the Plena support page. Here you'll find help, documentation, and resources for the Plena mindfulness tracking app.

---

## Quick Links

- 📱 [Main Repository](../README.md)
- 📖 [User Guide](USER_GUIDE.md)
- 🔧 [Troubleshooting Guide](TROUBLESHOOTING.md)
- 🔒 [Privacy Policy](PRIVACY_POLICY.md)
- 📋 [App Overview](APP_OVERVIEW.md)

---

## Getting Help

### Common Issues

**Can't start a mindfulness session?**
- Check HealthKit permissions: Settings → Privacy & Security → Health → Plena
- Ensure you're using a physical device (not simulator)
- See [Troubleshooting Guide](TROUBLESHOOTING.md) for detailed solutions

**Missing sensor data?**
- Verify your Apple Watch is connected and paired
- Check that your Watch model supports the sensor (HRV requires Series 4+, Respiratory Rate requires Series 6+)
- See [Apple Watch Compatibility](APPLE_WATCH_COMPATIBILITY.md) for details

**Data not syncing between iPhone and Watch?**
- Ensure iCloud is enabled on both devices
- Check that CloudKit is enabled in app settings
- Restart both devices and try again

### Need More Help?

If you've checked the troubleshooting guide and still need assistance:

**Email Support:** hello@{{DOMAIN}}

**Privacy Inquiries:** info@{{DOMAIN}}

When contacting support, please include:
- Your device model and iOS/watchOS version
- A description of the issue
- Steps you've already tried
- Screenshots (if applicable)

---

## Documentation

### [User Guide](USER_GUIDE.md)
Complete setup and usage instructions, including:
- Initial setup and HealthKit permissions
- Starting your first session
- Understanding real-time data and stress zones
- Using the Dashboard and Data visualization
- Tips and best practices

### [Troubleshooting Guide](TROUBLESHOOTING.md)
Comprehensive solutions for common issues:
- HealthKit & permissions problems
- Sensor data issues
- Apple Watch connectivity
- Data sync problems
- Performance issues

### [Privacy Policy](PRIVACY_POLICY.md)
Detailed information about:
- What data we collect and how we use it
- HealthKit integration and privacy
- Data storage and security
- Your rights and how to manage your data

### [App Overview](APP_OVERVIEW.md)
High-level information about:
- App features and capabilities
- System requirements
- Architecture and design

---

## Frequently Asked Questions

### General Questions

**Q: What devices does Plena support?**
A: Plena requires iOS 17.0+ on iPhone and watchOS 10.0+ on Apple Watch (Series 4 or newer recommended for full sensor support).

**Q: Do I need an Apple Watch to use Plena?**
A: While an Apple Watch provides the best experience with real-time sensor data, you can use Plena on iPhone alone. However, sensor data collection requires an Apple Watch.

**Q: Does Plena work in the simulator?**
A: No, HealthKit requires a physical device. The app will not function properly in the iOS simulator.

**Q: Is my health data secure?**
A: Yes. All health data is stored locally on your device or in your personal iCloud account. We do not transmit your health data to our servers. See our [Privacy Policy](PRIVACY_POLICY.md) for details.

### HealthKit & Permissions

**Q: Why does Plena need HealthKit permissions?**
A: Plena uses HealthKit to read biometric data (heart rate, HRV, respiratory rate) and write mindfulness session data. HealthKit is Apple's secure framework for health data.

**Q: Can I revoke permissions later?**
A: Yes, you can manage permissions anytime in Settings → Privacy & Security → Health → Plena. You can turn individual data types on or off.

**Q: What happens if I deny permissions?**
A: The app will have limited functionality. You won't be able to start mindfulness sessions or view sensor data. You can grant permissions later in Settings.

**Q: Does Plena share my health data?**
A: No. We do not share, sell, or transmit your health data to third parties. Your data stays on your device or in your iCloud account.

### Apple Watch

**Q: Which Apple Watch models are supported?**
A: Plena works with Apple Watch Series 4 or newer running watchOS 10.0+. Different models support different sensors:
- Heart Rate: All models (Series 1+)
- HRV: Series 4+
- Respiratory Rate: Series 6+
- Temperature: Series 8/Ultra+
- See [Compatibility Guide](APPLE_WATCH_COMPATIBILITY.md) for details.

**Q: Why don't I see HRV data?**
A: HRV requires Apple Watch Series 4 or later and sufficient session duration (typically 10+ minutes with at least 3 HRV samples).

**Q: Can I start sessions from my Watch?**
A: Yes! The Watch app allows you to start and stop mindfulness sessions directly from your wrist. Data automatically syncs to your iPhone.

### Data & Sync

**Q: How does data sync between iPhone and Watch?**
A: Data syncs automatically using CloudKit/iCloud when both devices are connected and signed into the same iCloud account.

**Q: Can I export my data?**
A: Your health data is accessible in the Health app on iPhone. You can view and export data from there. Session summaries are stored locally in the app.

**Q: What happens if I delete the app?**
A: Deleting the app removes local app data. Your HealthKit data remains in the Health app. iCloud data may remain depending on your iCloud settings.

**Q: How long is my data stored?**
A: Local app data is stored until you delete the app. HealthKit data follows your Health app settings. iCloud data follows your iCloud storage settings.

### Features

**Q: What sensors does Plena track?**
A: Plena tracks:
- Heart Rate (BPM) - Real-time heart rate monitoring
- Heart Rate Variability / SDNN (ms) - Variation between heartbeats
- Respiratory Rate (breaths/min) - Breathing rate tracking
- Body Temperature - Temperature monitoring during sessions
- VO₂ Max - Maximum oxygen consumption (periodic readings)

All sensors are tracked in real-time during mindfulness sessions and stored for historical analysis.

**Q: What are stress zones?**
A: Stress zones classify your physiological state:
- 🔵 Calm: Relaxed, low stress
- 🟢 Optimal: Balanced state
- 🟠 Elevated Stress: Higher stress response

**Q: Can I view historical data?**
A: Yes! The Data tab shows historical visualizations with time range options (Day, Week, Month, Year). You can switch between Consistency view (zone distribution) and Trend view (value over time) for each sensor. The view also provides trend statistics and insights.

**Q: What is the Readiness Score?**
A: The Readiness Score is a daily score (0-100) that provides a holistic view of your recovery and readiness. It's calculated from multiple contributors including Resting Heart Rate, HRV Balance, Body Temperature, Recovery Index, and Sleep metrics (duration, balance, regularity). The score helps you understand when you're ready for optimal performance and when to focus on recovery.

---

## System Requirements

### iPhone
- iOS 17.0 or later
- Physical device (not simulator)
- HealthKit support

### Apple Watch (Optional)
- watchOS 10.0 or later
- Apple Watch Series 4 or newer (recommended)
- Paired with iPhone

### Required Permissions
- HealthKit: Read (Heart Rate, HRV, Respiratory Rate, Temperature, VO₂ Max)
- HealthKit: Write (Mindfulness sessions)
- Optional: CloudKit/iCloud for device sync

---

## Contact & Support

### Email Support
- **General Support:** hello@{{DOMAIN}}
- **Privacy Inquiries:** info@{{DOMAIN}}

### Response Times
We aim to respond to support inquiries within 48 hours during business days.

### Bug Reports
If you've found a bug, please include:
- Device model and iOS/watchOS version
- App version
- Steps to reproduce
- Expected vs. actual behavior
- Screenshots (if applicable)

---

## Resources

- 📱 [Main Repository](../README.md) - Source code and development
- 📖 [User Guide](USER_GUIDE.md) - Complete usage instructions
- 🔧 [Troubleshooting](TROUBLESHOOTING.md) - Solutions to common issues
- 🔒 [Privacy Policy](PRIVACY_POLICY.md) - Privacy and data handling
- 📋 [App Overview](APP_OVERVIEW.md) - App features and architecture
- ⌚ [Apple Watch Compatibility](APPLE_WATCH_COMPATIBILITY.md) - Device compatibility details

---

## Legal

- [Privacy Policy](PRIVACY_POLICY.md)
- [Terms of Service](#) - Coming soon

---

## Medical Disclaimer

**Important:** Plena is not a medical device and does not provide medical advice, diagnosis, or treatment. The information provided by Plena is for wellness and self-improvement purposes only.

- Do not use Plena data to diagnose, treat, or prevent any disease
- Consult healthcare professionals for medical advice
- Do not rely on Plena data for medical decisions
- Plena data is not a substitute for professional medical care

---

## Version Information

**Current Version:** See App Store listing

**Minimum iOS:** 17.0
**Minimum watchOS:** 10.0

---

## Updates & Changelog

For the latest updates and version history, see the [main repository releases](https://github.com/knportal/Plena/releases).

---

**Last Updated:** December 12, 2025

---

_For the best support experience, please check the [Troubleshooting Guide](TROUBLESHOOTING.md) and [User Guide](USER_GUIDE.md) before contacting support._


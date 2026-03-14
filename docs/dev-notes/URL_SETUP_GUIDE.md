# App Store Compliance URL Setup

## Current Implementation

Your `SettingsView.swift` now includes:

### Privacy Policy Link
```swift
Link("Privacy Policy", destination: URL(string: "https://miletrack.example/privacy")!)
  .accessibilityLabel("Open Privacy Policy")
```

### Terms of Use Link  
```swift
Link("Terms of Use", destination: URL(string: "https://miletrack.example/terms")!)
  .accessibilityLabel("Open Terms of Use")
```

---

## ⚠️ ACTION REQUIRED

### Before You Submit to App Store:

1. **Replace placeholder URLs** with your actual URLs:
   - `https://miletrack.example/privacy` → Your actual privacy policy URL
   - `https://miletrack.example/terms` → Your actual terms URL

2. **Verify the URLs work**:
   - Visit both URLs in a browser
   - Confirm they load properly
   - Ensure they're mobile-responsive

3. **Update App Store Connect**:
   - **Privacy Policy URL**: App Store Connect → App Information → Privacy Policy
   - **Terms (EULA) URL**: App Store Connect → App → EULA field

4. **Test in TestFlight**:
   - Build with actual URLs
   - Tap the links on a real iOS device
   - Confirm pages load and are readable

---

## Sample Privacy Policy Structure

If you need to create your privacy policy, include:

- What data is collected (location, trips, categories, etc.)
- How data is used
- Data retention policies
- User rights and controls
- Contact information for privacy questions

Example:

```markdown
# Privacy Policy - MileTrack

**Last Updated: [DATE]**

## Information We Collect

- **Location Data**: We collect location information to detect drives and estimate mileage
- **Trip Data**: Destinations, times, distances, and associated metadata
- **App Usage**: Preferences, settings, and feature interactions

## How We Use Your Data

We use this information to:
- Detect automatic trips in Auto Mode
- Estimate mileage for trips
- Generate reports and statistics
- Improve app features and performance

## Data Storage

All trip and location data is stored locally on your device. We do not transmit this data to external servers.

## Your Rights

You can:
- Delete trips at any time
- Reset all data in Settings
- Disable Auto Mode
- Opt out of location tracking

## Contact Us

For privacy questions: privacy@yourcompany.com
```

---

## Sample Terms of Use Structure

If you need to create your terms of use, include:

- Service description
- Use restrictions
- Limitation of liability
- Warranty disclaimers
- Subscription terms
- Termination rights

Example:

```markdown
# Terms of Use - MileTrack

**Last Updated: [DATE]**

## Service Description

MileTrack is a mobile application that helps users track and manage business mileage.

## Acceptable Use

You agree not to:
- Use the app for illegal purposes
- Attempt to reverse-engineer or modify the app
- Transmit malware or harmful code

## Subscription Terms

- Monthly and annual plans are available
- Subscriptions auto-renew unless canceled
- You can cancel anytime in your Apple Account settings

## Limitation of Liability

The app is provided "as is" without warranties. We are not liable for:
- Inaccurate mileage data
- Lost trip information
- Business decisions made using the app

## Termination

We reserve the right to terminate access for violations of these terms.

## Contact

For questions about these terms: legal@yourcompany.com
```

---

## Recommended Hosting Options

1. **Simple (Free)**
   - GitHub Pages (markdown + automatic rendering)
   - Notion public page (professional looking)
   - Google Sites (simple, free)

2. **Professional**
   - Your company website
   - Subpage on existing domain
   - Dedicated docs site

3. **Premium Tools**
   - iubenda.com (cookie/privacy compliance)
   - termly.io (auto-generate policies)
   - appPrivacy.eu (EU GDPR compliant)

---

## Testing Checklist

- [ ] Placeholder URLs replaced with actual URLs
- [ ] Privacy policy URL is live and accessible
- [ ] Terms of Use URL is live and accessible  
- [ ] Both pages load in under 5 seconds
- [ ] Pages are mobile-responsive and readable
- [ ] Links work on physical iOS device
- [ ] Links updated in App Store Connect
- [ ] Privacy policy addresses data collection clearly
- [ ] Terms explain subscription auto-renewal
- [ ] Contact information is provided
- [ ] No authentication required to view policies

---

## Quick Reference

**In SettingsView.swift** (lines ~630-641):
```swift
Link("Privacy Policy", destination: URL(string: "YOUR_PRIVACY_URL")!)
Link("Terms of Use", destination: URL(string: "YOUR_TERMS_URL")!)
```

**In App Store Connect:**
- Privacy Policy field: `YOUR_PRIVACY_URL`
- EULA field: `YOUR_TERMS_URL`

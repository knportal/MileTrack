# App Store Privacy Disclosure - Quick Reference

**Use this when filling out App Store Connect Privacy section**

---

## Does your app collect data?
**Answer: YES**

---

## Data Types to Declare

### 1. Health & Fitness → Health

**What to select:**
- ✅ Health & Fitness
- ✅ Health

**Purpose:**
- ✅ App Functionality (ONLY - check this box)
- ❌ Third-Party Advertising
- ❌ Developer's Advertising or Marketing
- ❌ Analytics
- ❌ Product Personalization
- ❌ Other Purposes

**Linked to User:**
- ✅ Yes

**Used for Tracking:**
- ❌ No

**Third-Party Sharing:**
- ❌ No

**Details:**
- Heart Rate, HRV, Respiratory Rate, Body Temperature, VO₂ Max, Sleep Analysis
- Collected via HealthKit during meditation sessions
- Used for real-time display, stress zone calculations, and trend analysis

---

### 2. Health & Fitness → Fitness

**What to select:**
- ✅ Health & Fitness
- ✅ Fitness

**Purpose:**
- ✅ App Functionality (ONLY - check this box)
- ❌ Third-Party Advertising
- ❌ Developer's Advertising or Marketing
- ❌ Analytics
- ❌ Product Personalization
- ❌ Other Purposes

**Linked to User:**
- ✅ Yes

**Used for Tracking:**
- ❌ No

**Third-Party Sharing:**
- ❌ No

**Details:**
- Meditation session duration, timestamps, and frequency
- Written to HealthKit for integration with Apple Health app
- Used for session tracking and statistics

---

## Data NOT Collected

Do NOT declare these (they are not collected):
- ❌ Contact Info
- ❌ Financial Info
- ❌ Location
- ❌ Sensitive Info
- ❌ User Content
- ❌ Browsing History
- ❌ Search History
- ❌ User ID
- ❌ Device ID
- ❌ Product Interaction
- ❌ Advertising Data
- ❌ Other Usage Data

---

## Third-Party Data Collection

**Answer: NO**

(No third-party SDKs, analytics, or advertising services are used)

---

## Privacy Policy

**Privacy Policy URL:**
```
https://{{DOMAIN}}/privacy-policy
```

**Privacy Choices URL:**
(Optional - leave blank if you don't have a data management page)

---

## Summary Checklist

When completing App Store Connect:

1. ✅ Select "Yes" for data collection
2. ✅ Add "Health & Fitness → Health" data type
   - Purpose: App Functionality only
   - Linked: Yes
   - Tracking: No
3. ✅ Add "Health & Fitness → Fitness" data type
   - Purpose: App Functionality only
   - Linked: Yes
   - Tracking: No
4. ✅ Set Third-Party Data Collection to "No"
5. ✅ Enter Privacy Policy URL
6. ✅ Review and save

---

## Key Points to Remember

- **All data is used for App Functionality only**
- **No tracking, advertising, or analytics**
- **No third-party sharing**
- **Data is linked to user** (health data is inherently personal)
- **No data transmitted to external servers** (stored locally only)

---

**See APP_STORE_PRIVACY_DISCLOSURE.md for detailed information.**





# Plena Documentation Structure

This document shows the structure and content outline for each documentation file.

---

## 📄 Document Outlines

### 1. APP_OVERVIEW.md - "What Plena Does"

**Purpose:** Comprehensive overview of app features and capabilities

**Sections:**

- Introduction: What is Plena?
- Key Features Overview
- Supported Platforms
- Core Capabilities
  - Real-time Biometric Tracking
  - Stress Zone Classification
  - Data Visualization & Analytics
  - Session Management
  - Apple Watch Integration
- Who Should Use Plena
- Benefits of Using Plena
- Technical Requirements

**Length:** ~2-3 pages
**Audience:** New users, potential users, reviewers

---

### 2. USER_GUIDE.md - "User Setup & How-To Guide"

**Purpose:** Step-by-step instructions for setup and daily usage

**Sections:**

- **Getting Started**

  - System Requirements
  - Download & Installation
  - First Launch Walkthrough

- **Initial Setup**

  - HealthKit Permissions Setup
    - Why permissions are needed
    - Step-by-step permission grant
    - Troubleshooting permission issues
  - Apple Watch Setup
    - Installing Watch app
    - Pairing verification
    - Watch app permissions

- **Core Features Walkthrough**

  - Starting Your First Session
    - From iPhone
    - From Apple Watch
  - Understanding Real-time Data
    - Heart Rate
    - HRV (Heart Rate Variability)
    - Respiratory Rate
    - Other sensors
  - Understanding Stress Zones
    - What each zone means
    - How zones are calculated
    - Zone indicators

- **Using the Dashboard**

  - Viewing Statistics
  - Understanding Charts
  - Time Range Selection

- **Data Visualization**

  - Viewing Historical Data
  - Understanding Graphs
  - Time Range Views

- **Session Summary**

  - Reviewing Session Data
  - State of Mind Logging

- **Tips & Best Practices**
  - Getting Accurate Readings
  - Optimal Session Duration
  - When to Use Watch vs iPhone

**Length:** ~8-10 pages
**Audience:** End users, beginners

---

### 3. TROUBLESHOOTING.md - "Common Issues & Solutions"

**Purpose:** Self-service troubleshooting guide

**Sections:**

- **HealthKit & Permissions**

  - "HealthKit not authorized" error
  - "Permission denied" messages
  - How to check/change permissions
  - Re-requesting permissions

- **Sensor Data Issues**

  - No heart rate data appearing
  - Missing HRV readings
  - Respiratory rate not showing
  - "Sensor unavailable" messages
  - Sensor accuracy problems

- **Apple Watch Issues**

  - Watch app not syncing
  - Can't start session from Watch
  - Watch app crashes
  - Connection between iPhone/Watch lost
  - Watch permissions not working

- **Data & Sync Issues**

  - Sessions not saving
  - Missing historical data
  - CloudKit sync problems
  - Data import failures

- **Performance Issues**

  - App running slowly
  - Battery drain concerns
  - Watch battery issues

- **General Issues**

  - App crashes
  - Can't start meditation session
  - Countdown not working
  - Session summary not appearing

- **When to Contact Support**
  - Issues not covered
  - How to report bugs
  - Support contact information

**Length:** ~6-8 pages
**Audience:** Users experiencing issues

---

### 4. APP_STORE_METADATA.md - "App Store Listing Information"

**Purpose:** All metadata needed for App Store Connect submission

**Sections:**

- **App Information**

  - App Name: Plena
  - Subtitle (30 characters max)
  - Category Selection
  - Content Rights

- **Description (Short)**

  - 170 characters max (for preview)

- **Description (Full)**

  - 4000 characters max
  - Feature highlights
  - Benefits
  - Requirements

- **Keywords**

  - 100 characters max
  - Keyword optimization tips
  - Suggestions list

- **Promotional Text**

  - 170 characters max
  - What's new / Promotional content

- **Support Information**

  - Marketing URL (optional)
  - Support URL (required)
  - Privacy Policy URL (required)
  - Support email

- **App Store Screenshots**

  - Requirements summary
  - Content suggestions

- **App Preview Video**
  - Optional but recommended
  - Content suggestions

**Length:** ~3-4 pages
**Audience:** For App Store submission

---

### 5. PRIVACY_POLICY.md - "Privacy Policy"

**Purpose:** Legal privacy policy document (required for HealthKit apps)

**Sections:**

- **Introduction**

  - Our commitment to privacy

- **Information We Collect**

  - Health data collected
  - Device information
  - Usage data

- **How We Use Your Information**

  - Data usage purposes
  - Health data processing

- **Data Storage & Security**

  - Where data is stored
  - Security measures
  - Local vs cloud storage

- **Data Sharing**

  - Third-party services (HealthKit, CloudKit)
  - What is NOT shared

- **Your Rights**

  - Access to data
  - Data deletion
  - HealthKit permissions

- **Health Data Specific**

  - HealthKit integration details
  - Health data privacy
  - Medical disclaimer

- **Children's Privacy**

  - Age restrictions

- **Changes to Policy**

  - Policy updates

- **Contact Us**
  - Privacy inquiries

**Length:** ~4-5 pages
**Audience:** Required legal document
**Note:** Should be reviewed by legal counsel for production

---

### 6. APP_STORE_SCREENSHOTS.md - "Screenshot Requirements Guide"

**Purpose:** Guide for creating App Store screenshots

**Sections:**

- **iOS App Screenshots Required**

  - iPhone 6.7" Display (iPhone 14 Pro Max, etc.)
  - iPhone 6.5" Display (iPhone 11 Pro Max, etc.)
  - iPhone 5.5" Display (iPhone 8 Plus, etc.)
  - iPad Pro 12.9" (if supporting iPad)

- **watchOS App Screenshots Required**

  - Apple Watch Series 7 (45mm)
  - Apple Watch Series 4 (44mm)

- **Screenshot Content Guidelines**

  - What to showcase
  - Key features to highlight
  - Screenshot ordering strategy
  - Text overlays (if any)

- **Localization**

  - If supporting multiple languages

- **Tools & Resources**
  - Screenshot tools
  - Design guidelines

**Length:** ~2-3 pages
**Audience:** Marketing/design team

---

### 7. MARKETING_MATERIALS.md - "Marketing Copy & Materials" (Optional)

**Purpose:** Marketing and promotional content

**Sections:**

- **Tagline Options**

  - Short taglines
  - Long taglines

- **Feature Highlights**

  - One-liners for each feature
  - Feature descriptions

- **App Preview Video Script**

  - Video outline
  - Key moments to capture
  - Voiceover suggestions

- **Press Kit Content**

  - App summary
  - Key facts
  - Feature list
  - Screenshots package description

- **Social Media Copy**
  - Twitter/X posts
  - Instagram captions
  - LinkedIn posts

**Length:** ~3-4 pages
**Audience:** Marketing team

---

## 📊 Documentation Checklist

### Phase 1: Essential User Documentation

- [ ] APP_OVERVIEW.md
- [ ] USER_GUIDE.md
- [ ] TROUBLESHOOTING.md

### Phase 2: App Store Requirements

- [ ] PRIVACY_POLICY.md
- [ ] APP_STORE_METADATA.md
- [ ] APP_STORE_SCREENSHOTS.md

### Phase 3: Marketing (Optional)

- [ ] MARKETING_MATERIALS.md

---

## 🎯 Recommended Order to Create

1. **APP_OVERVIEW.md** - Foundation for understanding
2. **USER_GUIDE.md** - Most useful for users
3. **TROUBLESHOOTING.md** - Reduces support load
4. **PRIVACY_POLICY.md** - **Required** for submission
5. **APP_STORE_METADATA.md** - For submission
6. **APP_STORE_SCREENSHOTS.md** - For submission prep
7. **MARKETING_MATERIALS.md** - Nice to have

---

## 📝 Notes

- All documentation should be in **Markdown** format for easy editing
- Can be converted to HTML/PDF for hosting if needed
- Privacy Policy should be hosted on a website (URL required for App Store)
- Support URL can point to a website or GitHub page with docs
- Consider creating a simple website to host these documents

---

_Ready to generate these documents? Let me know which ones you'd like me to create first!_



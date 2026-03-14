# Apple App Store Compliance Checklist

## Guideline 3.1.1 - Business - Payments - In-App Purchase

### ✅ Restore Purchases Feature
- **Location**: `SettingsView.swift`, Subscription section
- **Implementation**: "Restore" button that calls `subscriptionManager.restorePurchases()`
- **Status**: ✅ **COMPLETE** - Button is distinct and user-initiated (tapped, not automatic)

```swift
Button {
  Task { await subscriptionManager.restorePurchases() }
} label: {
  HStack(spacing: 6) {
    Image(systemName: "arrow.clockwise")
    Text("Restore")
  }
  .frame(maxWidth: .infinity)
  .padding(.vertical, 10)
}
.buttonStyle(.bordered)
```

---

## Guideline 3.1.2 - Business - Payments - Subscriptions

### ✅ Required Information IN-APP

All of the following must be visible within the app:

#### 1. **Title of Publication/Service** ✅
- **Text**: "MileTrack Pro" (referenced in subscription UI)
- **Location**: Subscription section header and plan rows

#### 2. **Length of Subscription** ✅
- **Monthly**: "Billed monthly"
- **Annual**: "Billed yearly"
- **Location**: `SettingsView.swift`, `enhancedPlanRow` subtitle parameter
- **Status**: ✅ Clearly displayed for both plans

#### 3. **Price of Subscription** ✅
- **Implementation**: Uses StoreKit 2 `Product.displayPrice`
- **Location**: `enhancedPlanRow` displays `product.displayPrice`
- **Status**: ✅ Dynamically pulled from App Store

#### 4. **Functional Link to Terms of Use (EULA)** ✅
- **URL**: `https://miletrack.example/terms`
- **Location**: Subscription section, "Terms & Links" VStack
- **Accessibility**: Labeled "Open Terms of Use"
- **Status**: ✅ **UPDATE REQUIRED**: Replace placeholder URL with your actual terms URL

#### 5. **Functional Link to Privacy Policy** ✅
- **URL**: `https://miletrack.example/privacy`
- **Location**: Subscription section, "Terms & Links" VStack
- **Accessibility**: Labeled "Open Privacy Policy"
- **Status**: ✅ **UPDATE REQUIRED**: Replace placeholder URL with your actual privacy policy URL

#### 6. **Auto-Renewal Disclosure Text** ✅
- **Text**: "Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period. You can manage or cancel in your Apple ID account settings."
- **Location**: Subscription section, "Terms & Links" VStack
- **Status**: ✅ Standard Apple-compliant language included

#### 7. **Subscription Management Button** ✅
- **Text**: "Manage Subscription"
- **Function**: Opens Apple's subscription management page
- **Status**: ✅ Implemented with both deep link and web fallback

---

### ✅ Required Information in App Store Metadata

#### App Store Connect Checklist:

1. **Privacy Policy**
   - Location in App Store Connect: Privacy Policy field
   - URL: `https://miletrack.example/privacy`
   - Status: ⚠️ **TODO**: Update in App Store Connect

2. **Terms of Use (EULA)**
   - Location in App Store Connect: EULA field (or App Description)
   - URL: `https://miletrack.example/terms`
   - Status: ⚠️ **TODO**: Update in App Store Connect

---

## URL Replacement Instructions

### Step 1: Update Privacy & Terms URLs in Code

Replace the placeholder URLs in `SettingsView.swift`:

```swift
// Before:
Link("Privacy Policy", destination: URL(string: "https://miletrack.example/privacy")!)
Link("Terms of Use", destination: URL(string: "https://miletrack.example/terms")!)

// After (your actual URLs):
Link("Privacy Policy", destination: URL(string: "https://yourcompany.com/privacy")!)
Link("Terms of Use", destination: URL(string: "https://yourcompany.com/terms")!)
```

### Step 2: Update App Store Connect Metadata

1. Open App Store Connect
2. Select your app
3. Go to **App Information** → **Privacy Policy** field
   - Paste: `https://yourcompany.com/privacy`
4. Go to **App > EULA**
   - Paste: `https://yourcompany.com/terms`

### Step 3: Verify Links Are Live

Before submitting:
1. Ensure both URLs are publicly accessible and not behind authentication
2. Test that links work on physical iOS device
3. Confirm terms and privacy policies load within 3-5 seconds

---

## Summary: Compliance Status

| Guideline | Requirement | Status | Notes |
|-----------|------------|--------|-------|
| **3.1.1** | Restore Purchases button | ✅ Complete | User-initiated, not automatic |
| **3.1.2** | Service title | ✅ Complete | "MileTrack Pro" |
| **3.1.2** | Subscription length | ✅ Complete | Monthly & Annual shown |
| **3.1.2** | Price | ✅ Complete | StoreKit Product.displayPrice |
| **3.1.2** | Terms link | ✅ Complete* | *Update URL before submission |
| **3.1.2** | Privacy link | ✅ Complete* | *Update URL before submission |
| **3.1.2** | Auto-renewal text | ✅ Complete | Standard Apple disclosure |
| **3.1.2** | Manage subscription | ✅ Complete | Apple Account Management link |

---

## Testing Before Submission

1. **Test on Simulator (StoreKit Configuration)**
   - Create a `MileTrack.storekit` configuration file
   - Add both monthly and annual products
   - Test Restore Purchases flow

2. **Test on Physical Device (TestFlight)**
   - Use TestFlight internal testers
   - Verify all links are accessible
   - Confirm prices display correctly

3. **Accessibility Testing**
   - Verify all links have accessibility labels
   - Test with VoiceOver
   - Confirm color contrast (links in blue, 4.5:1 ratio)

---

## Questions?

If Apple rejects your submission citing 3.1.1 or 3.1.2:

1. Ensure Restore Purchases button is visible and functional
2. Verify all five required pieces of subscription information are displayed
3. Check that Privacy & Terms links are live and load correctly
4. Verify App Store Connect metadata includes the links
5. Contact App Review Support with a screenshot showing all requirements

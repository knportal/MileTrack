# App Group Setup - Step-by-Step Walkthrough

## Visual Navigation Guide

### Starting Point

1. Go to: **https://developer.apple.com/account/**
2. Sign in with your Apple Developer account

---

## Step 1: Find "Certificates, Identifiers & Profiles"

### Option A: From Dashboard

```
Developer Portal Homepage
  ↓
Look for card/section titled:
  "Certificates, Identifiers & Profiles"
  ↓
Click on it
```

### Option B: From Account Menu

```
Click your name/icon (top right)
  ↓
Dropdown menu appears
  ↓
Click: "Certificates, Identifiers & Profiles"
```

### Option C: Direct URL

Go directly to: **https://developer.apple.com/account/resources/identifiers/list**

---

## Step 2: Navigate to Identifiers

Once in "Certificates, Identifiers & Profiles", you'll see a **left sidebar**:

```
Left Sidebar:
├── Certificates
├── Identifiers  ← CLICK THIS
├── Devices
├── Profiles
├── Keys
└── ...
```

Click **"Identifiers"** in the left sidebar.

---

## Step 3: Find App Groups Tab

After clicking "Identifiers", you'll see **tabs at the top** of the main content area:

```
Top Tabs:
├── App IDs (usually selected by default)
├── App Groups  ← CLICK THIS TAB
├── Website Push IDs
├── Merchant IDs
└── ...
```

Click the **"App Groups"** tab.

---

## Step 4: Create New App Group

In the App Groups view:

```
Top of page:
[+ Register] button (blue, top left)  ← CLICK THIS
```

After clicking **"+ Register"** or **"Register"** button:

### Form Fields:

```
Description: [Text field]
  ↓
Enter: "Plena Shared Data"

Identifier: [Text field]
  ↓
Enter: group.com.plena.meditation.app
  (Must start with "group.")
```

### Buttons:

```
[Cancel]  [Continue]  ← Click Continue
```

### Review Screen:

```
Review your information
  ↓
[Back]  [Register]  ← Click Register
```

---

## Step 5: Verify App Group Created

After registering, you'll be back at the App Groups list:

```
App Groups List:
└── group.com.plena.meditation.app  ← Should appear here
```

If you see it in the list, **Step 1 is complete!**

---

## Step 6: Configure App IDs

### Go Back to App IDs Tab

```
Top Tabs:
├── App IDs  ← CLICK THIS TAB (go back)
├── App Groups
└── ...
```

### Find Your iPhone App ID

In the App IDs list:

- Look for: `com.plena.meditation.app`
- Or use the **search box** at the top
- **Click on the App ID name** (not Edit yet, just click the name)

### Edit the App ID

After clicking the App ID name:

```
App ID Detail Page:
  [Edit] button (top right)  ← CLICK THIS
```

### Enable App Groups Capability

Scroll down the edit form to find capabilities:

```
Capabilities List:
☐ App Groups  ← CHECK THIS BOX
  ↓
When checked, a list appears below:
  ☐ group.com.plena.meditation.app  ← CHECK THIS TOO
```

### Save Changes

```
Bottom of page:
[Cancel]  [Save]  ← Click Save
  ↓
Confirmation:
[Cancel]  [Save]  ← Click Save again
```

### Repeat for Watch App

1. Go back to App IDs list
2. Find: `com.plena.meditation.app.watchkitapp`
3. Click on it
4. Click **Edit**
5. Check **App Groups** capability
6. Check `group.com.plena.meditation.app`
7. Click **Save**

---

## Step 7: Update Provisioning Profiles

### Navigate to Profiles

```
Left Sidebar:
├── Certificates
├── Identifiers
├── Devices
├── Profiles  ← CLICK THIS
└── ...
```

### Find Your Profiles

You'll see a list of provisioning profiles. Look for ones that include:

- Your iPhone app
- Your Watch app

They might be named like:

- `Plena Development`
- `Plena Distribution`
- Or just your app bundle IDs

### Edit Each Profile

1. **Click on a profile name** to select it
2. Click **Edit** button (top right)
3. Scroll down to find **App Groups** section
4. Ensure `group.com.plena.meditation.app` is checked
5. Click **Generate** or **Save**
6. Click **Download** to save the updated profile

### Repeat for All Profiles

Do this for:

- Development profiles
- Distribution profiles
- Any profile that includes your apps

---

## Common Issues & Solutions

### "I don't see 'Certificates, Identifiers & Profiles'"

- Make sure you're signed in with an **Apple Developer account** (not just Apple ID)
- You need an active Developer Program membership

### "I don't see 'App Groups' tab"

- Make sure you clicked **"Identifiers"** in the left sidebar first
- The tabs appear at the top of the main content area

### "The App Group identifier is invalid"

- Must start with `group.`
- Must match exactly what's in your entitlements file
- Format: `group.com.yourcompany.appname`

### "App Groups option is grayed out in App ID"

- Make sure you've registered the App Group first (Step 1)
- Wait a few minutes for the system to sync
- Try refreshing the page

### "I can't find my App ID"

- Use the search box at the top of the App IDs list
- Check if you're looking in the right account/team
- Make sure the App ID was created in this Developer account

---

## Quick Checklist

After completing all steps, verify:

- [ ] App Group `group.com.plena.meditation.app` exists in App Groups list
- [ ] iPhone App ID has App Groups capability enabled
- [ ] Watch App ID has App Groups capability enabled
- [ ] Both App IDs have `group.com.plena.meditation.app` checked
- [ ] Provisioning profiles are updated and downloaded
- [ ] Xcode shows App Groups capability in Signing & Capabilities
- [ ] Both apps rebuilt and reinstalled

---

## Next Steps

After completing the Developer Portal setup:

1. **Clean Xcode build folder** (⌘ShiftK)
2. **Delete apps from devices**
3. **Rebuild and reinstall** both apps
4. **Check console logs** - container UUIDs should match
5. **Test sync** - start session on Watch, check iPhone Dashboard









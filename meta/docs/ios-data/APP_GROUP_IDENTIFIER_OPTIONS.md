# App Group Identifier Options

## Problem

The identifier `group.com.plena.meditation.app` is not available (already taken by another developer).

## Solution

Use a more unique identifier. I've updated the code to use:

**Current Identifier:** `group.com.plena.meditation.plena.shared`

**Note:** If this is also taken, try the alternatives below and update the code accordingly.

## Alternative Identifiers to Try

If `group.com.plena.meditation.plena.shared` is also taken, try these alternatives (in order):

1. `group.com.plena.meditation.plena.data`
2. `group.com.plena.meditation.plena.core`
3. `group.com.plena.meditation.plena.shareddata`
4. `group.com.plena.meditation.plena2024`
5. `group.com.plena.meditation.plena.watchsync`
6. `group.com.plena.meditation.datasync`
7. `group.com.plena.meditation.coredata.shared`
8. `group.com.plena.meditation.plena.app.shared`

## How to Update

### Step 1: Register New App Group

In Apple Developer Portal:

1. Go to **Identifiers** → **App Groups**
2. Click **+ Register**
3. Use identifier: `group.com.plena.meditation.plena.shared` (or try alternatives if taken)
4. Description: "Plena Shared Data Container"
5. Click **Register**

**If this identifier is also taken**, try the alternatives listed above until you find one that's available.

### Step 2: Code Already Updated

The following files have been updated automatically:

- ✅ `Plena/Plena.entitlements`
- ✅ `Plena Watch App/Plena Watch App.entitlements`
- ✅ `PlenaShared/Services/CoreDataStack.swift`

### Step 3: Update App IDs

1. Go to **Identifiers** → **App IDs**
2. Edit your iPhone App ID (`com.plena.meditation.app`)
3. Enable **App Groups** capability
4. Check: `group.com.plena.meditation.plena.shared` (or whatever identifier you successfully registered)
5. **Uncheck** any old identifiers if they're there
6. Save
7. Repeat for Watch App ID

### Step 4: Update Provisioning Profiles

1. Go to **Profiles**
2. Edit each profile
3. Ensure `group.com.plena.meditation.plena.shared` (or your chosen identifier) is checked
4. Uncheck any old identifiers
5. Save and download

### Step 5: Clean and Rebuild

1. In Xcode: **Product** → **Clean Build Folder** (⌘ShiftK)
2. Delete apps from devices
3. Rebuild both apps

## Testing

After completing the setup:

1. Check console logs - both apps should show the same container UUID
2. Start a session on Watch
3. Check iPhone Dashboard - session should appear

## If New Identifier is Also Taken

If `group.com.plena.meditation.plena.shared` is also unavailable, try:

- Adding your team identifier: `group.com.plena.meditation.TEAMID.shared`
- Using a more unique suffix: `group.com.plena.meditation.plena2024`
- Adding a date: `group.com.plena.meditation.shared.2024`

The key is finding an identifier that's unique and available.









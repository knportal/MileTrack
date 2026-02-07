# App Group Troubleshooting Guide

## Problem: Watch and iPhone Using Different App Group Containers

If you see different container UUIDs in the logs:

- Watch: `804EC17C-B879-437D-ACF8-46D0344E31EB`
- iPhone: `E75E196F-D110-4BC9-810A-D0E5728D8E0F`

This means the apps are **not sharing the same App Group container**, so data won't sync.

## Root Cause

The App Group `group.com.plena.meditation.app` is not properly configured or registered, causing iOS to create separate containers for each app.

## Solution Steps

### Step 1: Register App Group in Apple Developer Portal

#### Navigation Path:

1. **Go to Apple Developer Portal**

   - Open: https://developer.apple.com/account/
   - Sign in with your Apple Developer account

2. **Find Certificates, Identifiers & Profiles**

   - Look for this section in the left sidebar (or main dashboard)
   - If you don't see it, click on your account name/icon in the top right
   - Select **"Certificates, Identifiers & Profiles"** from the dropdown

3. **Navigate to Identifiers**

   - In the left sidebar, you'll see:
     - Certificates
     - **Identifiers** ← Click this
     - Devices
     - Profiles
     - Keys
     - etc.

4. **Select App Groups**

   - After clicking **Identifiers**, you'll see a list of identifier types at the top:
     - App IDs
     - **App Groups** ← Click this tab
     - Website Push IDs
     - Merchant IDs
     - etc.

5. **Create New App Group**

   - Click the **+** button in the top-left corner (blue button)
   - You'll see a form with:
     - **Description**: Enter "Plena Shared Data" (or any descriptive name)
     - **Identifier**: Enter `group.com.plena.meditation.app`
       - Must start with `group.`
       - Must match exactly what's in your entitlements
   - Click **Continue**
   - Review the information
   - Click **Register**

6. **Verify App Group Created**
   - You should now see `group.com.plena.meditation.app` in the App Groups list

### Step 2: Configure App IDs

#### For iPhone App:

1. **Go to App IDs**

   - Still in **Identifiers** section
   - Click the **App IDs** tab (first tab, usually selected by default)

2. **Find Your iPhone App ID**

   - Look for: `com.plena.meditation.app`
   - Use the search box if you have many App IDs
   - Click on the App ID name to select it

3. **Edit the App ID**

   - Click the **Edit** button (top right, or double-click the App ID)

4. **Enable App Groups**

   - Scroll down to find **App Groups** section
   - Check the box next to **App Groups** capability
   - A list of App Groups will appear below
   - Check the box next to: `group.com.plena.meditation.app`

5. **Save Changes**
   - Click **Save** (top right)
   - You may need to click **Continue** and **Save** again to confirm

#### For Watch App:

1. **Find Your Watch App ID**

   - Still in **App IDs** tab
   - Look for: `com.plena.meditation.app.watchkitapp`
   - Or search for "watchkitapp"

2. **Edit the Watch App ID**

   - Click **Edit** button

3. **Enable App Groups**

   - Scroll to **App Groups** section
   - Check the **App Groups** capability box
   - Check the box next to: `group.com.plena.meditation.app`

4. **Save Changes**
   - Click **Save**

### Step 3: Update Provisioning Profiles

1. **Go to Profiles**

   - In the left sidebar, click **Profiles**
   - You'll see a list of provisioning profiles

2. **Find Your Profiles**

   - Look for profiles that include:
     - Your iPhone app (`com.plena.meditation.app`)
     - Your Watch app (`com.plena.meditation.app.watchkitapp`)
   - You may have:
     - **Development** profiles (for testing)
     - **Distribution** profiles (for App Store/TestFlight)

3. **Edit Each Profile**

   - Click on a profile name to select it
   - Click **Edit** button (top right)
   - Scroll down to find **App Groups** section
   - Ensure `group.com.plena.meditation.app` is checked
   - If it's not there, the App Group wasn't added to the App ID properly
   - Click **Generate** or **Save**

4. **Download Updated Profiles**

   - After saving, click **Download** button
   - Save the `.mobileprovision` file
   - Repeat for all relevant profiles (Development and Distribution)

5. **Install Profiles in Xcode** (if needed)
   - Usually Xcode will automatically use updated profiles
   - If not: Xcode → Preferences → Accounts → Select your account → Download Manual Profiles

### Step 4: Verify Xcode Configuration

1. Open your project in Xcode
2. Select the **Plena** (iPhone) target
3. Go to **Signing & Capabilities**
4. Verify **App Groups** capability exists
5. Verify it shows: `group.com.plena.meditation.app` (checked)
6. Repeat for **Plena Watch App** target

### Step 5: Clean and Rebuild

1. In Xcode: **Product** → **Clean Build Folder** (⌘ShiftK)
2. Delete both apps from devices:
   - Delete from iPhone
   - Delete from Watch
3. Rebuild and install:
   - Build iPhone app first (⌘R)
   - Then build Watch app (select Watch scheme, ⌘R)

### Step 6: Verify Container UUIDs Match

After rebuilding, check the console logs. Both apps should show:

- **Same container UUID** (not different ones)
- `✅ Using App Group shared container: [same path]`

## Alternative: Use WatchConnectivity (Temporary Workaround)

If App Group setup is complex, you can use WatchConnectivity to send session data directly:

1. Watch saves session to its local Core Data
2. Watch sends session data via WatchConnectivity to iPhone
3. iPhone receives and saves to its Core Data

This is more complex but works without App Group configuration.

## Verification

After fixing, test:

1. Start a session on Watch
2. Complete the session
3. Check Watch logs - should see save confirmation
4. Open iPhone Dashboard
5. Session should appear immediately

If container UUIDs still differ, the App Group is still not properly configured.









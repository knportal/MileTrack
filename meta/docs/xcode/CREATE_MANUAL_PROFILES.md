# Create Manual Provisioning Profiles for App Group

## Problem

Xcode automatic signing isn't creating profiles that properly share the App Group container. We need to create profiles manually.

## Solution: Create Profiles in Developer Portal

### Step 1: Create iPhone App Development Profile

1. **Go to Developer Portal** → **Profiles**
2. **Click the "+" button** (top left, blue button)
3. **Select Profile Type:**

   - Under "Development", select **"iOS App Development"**
   - Click **"Continue"**

4. **Select App ID:**

   - Choose: `com.plena.meditation.app`
   - Click **"Continue"**

5. **Select Certificates:**

   - Check your development certificate (Apple Development: Kenneth Nygren)
   - Click **"Continue"**

6. **Select Devices:**

   - Check your iPhone device(s)
   - Click **"Continue"**

7. **Name the Profile:**

   - Enter: `Plena Development`
   - Click **"Generate"**

8. **Download:**
   - Click **"Download"** button
   - Save the `.mobileprovision` file

### Step 2: Create Watch App Development Profile

1. **Click "+" again** in Profiles
2. **Select Profile Type:**

   - Under "Development", select **"watchOS App Development"**
   - Click **"Continue"**

3. **Select App ID:**

   - Choose: `com.plena.meditation.app.watchkitapp`
   - Click **"Continue"**

4. **Select Certificates:**

   - Check your development certificate
   - Click **"Continue"**

5. **Select Devices:**

   - Check your Watch device(s)
   - Click **"Continue"**

6. **Name the Profile:**

   - Enter: `Plena Watch Development`
   - Click **"Generate"**

7. **Download:**
   - Click **"Download"** button
   - Save the `.mobileprovision` file

### Step 3: Install Profiles in Xcode

1. **Double-click both `.mobileprovision` files** you downloaded

   - This installs them in Xcode

2. **Or manually install:**
   - Xcode → Settings → Accounts
   - Select your account
   - Click "Download Manual Profiles"

### Step 4: Configure Xcode to Use Manual Profiles

1. **In Xcode, select "Plena" target**
2. **Go to "Signing & Capabilities"**
3. **Uncheck "Automatically manage signing"**
4. **Under "Provisioning Profile", select:**

   - `Plena Development` (the one you just created)

5. **Select "Plena Watch App" target**
6. **Go to "Signing & Capabilities"**
7. **Uncheck "Automatically manage signing"**
8. **Under "Provisioning Profile", select:**
   - `Plena Watch Development` (the one you just created)

### Step 5: Verify App Groups in Profiles

After creating profiles, verify they include the App Group:

1. **Go back to Developer Portal** → **Profiles**
2. **Click on "Plena Development" profile**
3. **Check "Enabled Capabilities" section**
4. **Verify** `group.com.plena.meditation.coredata` is listed
5. **Repeat for "Plena Watch Development"**

If the App Group isn't listed, you need to:

- Edit the profile
- The App Group should appear automatically if the App ID has it enabled
- If not, regenerate the profile

### Step 6: Clean and Rebuild

1. **Clean Build Folder** (⌘ShiftK)
2. **Delete apps from devices**
3. **Rebuild iPhone app** (⌘R)
4. **Rebuild Watch app** (⌘R)
5. **Check UUIDs** - they should now match!

## Important Notes

- Manual profiles need to be renewed before they expire
- You'll need to create new profiles if you add new devices
- For App Store builds, create "App Store" type profiles instead of "Development"









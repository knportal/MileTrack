# CloudKit Setup - Clarified Instructions

## Important: CloudKit is Part of iCloud Capability

CloudKit is **not** a separate capability. It's configured **within** the "iCloud" capability.

## Step-by-Step: Enable CloudKit via iCloud Capability

### Step 1: Add iCloud Capability

1. In Xcode, select your **"Plena"** target (iOS app)
2. Go to **"Signing & Capabilities"** tab
3. Click **"+ Capability"**
4. Search for **"iCloud"** (not "CloudKit")
5. Double-click **"iCloud"** to add it

### Step 2: Enable CloudKit Services

After adding "iCloud" capability, you'll see an **"iCloud"** section with checkboxes:

1. ✅ Check **"CloudKit"** checkbox

   - This enables CloudKit for your app
   - Xcode will automatically create a CloudKit container

2. (Optional) You can also check:
   - **"Key-value storage"** - for small data sync
   - **"iCloud Documents"** - for file storage

### Step 3: Note the Container Name

1. After checking "CloudKit", you'll see a **"CloudKit Containers"** section appear
2. Xcode automatically creates a container named something like:
   - `iCloud.com.plena.app` (based on your bundle ID)
3. **Write down this container name** - you'll need it for the Watch app

### Step 4: Repeat for Watch App

1. Select **"Plena Watch App"** target
2. Go to **"Signing & Capabilities"** tab
3. Click **"+ Capability"**
4. Add **"iCloud"** capability
5. Check **"CloudKit"** checkbox
6. **IMPORTANT**: In the "CloudKit Containers" dropdown, select the **same container** as your iOS app
   - Click the dropdown or "+" button
   - Choose the container you noted in Step 3 (e.g., `iCloud.com.plena.app`)

## What You Should See

### After Adding iCloud Capability:

```
Signing & Capabilities Tab:

┌─ iCloud ─────────────────────────┐
│ ☑ CloudKit                       │
│ ☐ Key-value storage              │
│ ☐ iCloud Documents               │
│                                  │
│ CloudKit Containers:             │
│ ┌─────────────────────────────┐ │
│ │ iCloud.com.plena.app        │ │
│ └─────────────────────────────┘ │
└──────────────────────────────────┘
```

## Verification

### Check iOS App:

1. Select **"Plena"** target
2. **"Signing & Capabilities"** tab
3. Should show:
   - ✅ iCloud capability added
   - ✅ CloudKit checkbox checked
   - ✅ Container name visible

### Check Watch App:

1. Select **"Plena Watch App"** target
2. **"Signing & Capabilities"** tab
3. Should show:
   - ✅ iCloud capability added
   - ✅ CloudKit checkbox checked
   - ✅ **Same container** as iOS app selected

## Common Confusion

- ❌ **Wrong**: Looking for "CloudKit" as a separate capability
- ✅ **Correct**: Add "iCloud" capability, then check "CloudKit" checkbox

## If You Don't See CloudKit Checkbox

If after adding "iCloud" you don't see a "CloudKit" checkbox:

1. Make sure you're on the **"Signing & Capabilities"** tab (not "General")
2. Scroll down in the capabilities list - it might be below other options
3. Try removing and re-adding the iCloud capability
4. Make sure your Apple Developer account has CloudKit enabled

## Alternative: App Groups (If CloudKit Doesn't Work)

If you prefer file-based sharing instead of CloudKit:

1. Add **"App Groups"** capability (instead of iCloud)
2. Create a group: `group.com.plena.meditation.app`
3. Add the same group to both iOS and Watch targets
4. Update `PlenaWatchApp.swift` to use the App Group identifier

But CloudKit is recommended for automatic sync!




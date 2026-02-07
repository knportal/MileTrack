# Creating CloudKit Container Manually

## Issue

After enabling iCloud with CloudKit, the container section shows "Add containers here" instead of an automatic container.

## Solution: Create Container Manually

### Step 1: Click the "+" Button

1. In the **"Containers"** section under iCloud
2. Click the **"+"** button (next to "Add containers here")
3. A dialog will appear

### Step 2: Create New Container

1. In the dialog, you'll see options:
   - **"Create a new container"** or similar
   - A text field for container identifier
2. Enter a container identifier:
   - Format: `iCloud.com.plena.app` (or `iCloud.` + your bundle ID)
   - Or use: `iCloud.com.plena.meditation`
3. Click **"OK"** or **"Create"**

### Step 3: Verify Container Appears

1. After creating, the container should appear in the list
2. It will show something like: `iCloud.com.plena.app`
3. Make sure it's selected/checked

### Step 4: Repeat for Watch App

1. Select **"Plena Watch App"** target
2. Go to **"Signing & Capabilities"** tab
3. Add **"iCloud"** capability if not already added
4. Check **"CloudKit"** checkbox
5. Click **"+"** in Containers section
6. **Select the same container** you just created (don't create a new one!)
   - It should appear in the dropdown/list
   - Click on it to select it

## Alternative: Use Your Bundle Identifier

If the "+" button doesn't work or you want to specify exactly:

1. Click the **"+"** button
2. In the container identifier field, enter:

   ```
   iCloud.com.plena.app
   ```

   (Replace `com.plena.app` with your actual bundle identifier if different)

3. Click **"OK"**

## Troubleshooting

### If "+" Button Doesn't Work:

1. Make sure you're signed in with your Apple Developer account
2. Check that your bundle identifier is properly set
3. Try removing and re-adding the iCloud capability
4. Restart Xcode

### If Container Creation Fails:

1. Check your Apple Developer account status
2. Verify you have CloudKit enabled in your developer account
3. Make sure your bundle identifier matches your App ID

### If You See "Container Already Exists":

- This is fine! It means the container exists in your developer account
- Just select it from the list instead of creating new

## What You Should See After

```
┌─ iCloud ─────────────────────────┐
│ Services:                        │
│ ☑ Key-value storage              │
│ ☑ iCloud Documents               │
│ ☑ CloudKit                       │
│                                  │
│ Containers:                      │
│ ┌─────────────────────────────┐ │
│ │ ☑ iCloud.com.plena.app      │ │  ← Should appear here
│ └─────────────────────────────┘ │
└──────────────────────────────────┘
```

## Important Notes

- **Container name format**: Must start with `iCloud.` followed by your bundle identifier
- **Both apps must use same container**: iOS and Watch apps need the exact same container name
- **Container is shared**: This container will be used by SwiftData for CloudKit sync




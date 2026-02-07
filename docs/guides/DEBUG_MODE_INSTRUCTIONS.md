# How to Run in Debug Mode in Xcode

## Quick Answer

**Debug mode is the default** - just run the app normally! Xcode builds in Debug configuration by default unless you specifically change it.

---

## Step-by-Step Instructions

### 1. Open Your Project
- Open `Plena.xcodeproj` in Xcode
- Make sure the project loads correctly

### 2. Select Your Target
- At the top toolbar, you'll see a scheme selector
- Make sure it says **"Plena"** (not "Plena Watch App")
- If it shows a device/simulator, that's fine

### 3. Select Run Destination
- Next to the scheme selector, choose where to run:
  - **iPhone Simulator** (recommended for testing)
  - Or a connected physical iPhone

### 4. Build and Run
- Press **⌘R** (Command + R)
- OR click the **Play button** (▶) in the top-left toolbar
- OR go to **Product → Run**

### 5. Wait for Build
- Xcode will build the app in **Debug mode**
- You'll see build progress at the top
- First build takes longer (subsequent builds are faster)

### 6. App Launches
- The app will launch in the simulator/device
- You should see all tabs including **"Test Data"** tab

---

## Verifying Debug Mode

### Check Build Configuration

**Method 1: Check Scheme**
1. Click the scheme selector (next to Play button)
2. Select **"Edit Scheme..."**
3. Look at left sidebar → **"Run"**
4. Under **"Build Configuration"**, it should say **"Debug"**

**Method 2: Check Build Settings**
1. Select your project in the navigator
2. Select the "Plena" target
3. Go to **"Build Settings"** tab
4. Search for "Configuration"
5. Verify **"Debug"** configuration is selected

---

## The Test Data Tab

Once running in debug mode:
- You should see **4 tabs** at the bottom:
  1. **Meditate** (leaf icon)
  2. **Dashboard** (chart icon)
  3. **Data** (line chart icon)
  4. **Test Data** (wrench icon) ← **Only in Debug!**

If you see the "Test Data" tab, you're in debug mode! ✅

---

## Debug vs Release

### Debug Mode (Default)
- ✅ Slower performance (optimizations disabled)
- ✅ Debug symbols included
- ✅ Assertions enabled
- ✅ **Test Data tab visible**
- ✅ Easier debugging

### Release Mode
- ⚡ Fast performance (optimized)
- 🚫 No debug symbols
- 🚫 No Test Data tab
- 🚫 Production-ready build

---

## Common Issues

### "I don't see the Test Data tab"

**Possible causes:**
1. **Not in debug mode**:
   - Check scheme configuration (see above)
   - Make sure "Debug" is selected in build configuration

2. **Wrong target selected**:
   - Make sure you're running "Plena" target
   - Not "Plena Watch App"

3. **Build configuration issue**:
   - Product → Scheme → Edit Scheme
   - Run → Build Configuration → Debug

### "App won't build"

**Solutions:**
1. Clean build folder: **⌘⇧K** (Command + Shift + K)
2. Product → Clean Build Folder
3. Try building again: **⌘B**
4. Check for errors in the Issue Navigator

### "Simulator won't launch"

**Solutions:**
1. Check Xcode → Settings → Platforms
2. Make sure iOS Simulator is downloaded
3. Try a different simulator device
4. Restart Xcode

---

## Quick Reference

| Action | Keyboard Shortcut |
|--------|------------------|
| Run (Debug) | **⌘R** |
| Build | **⌘B** |
| Stop | **⌘.** |
| Clean Build | **⌘⇧K** |
| Edit Scheme | **⌘<** |

---

## Troubleshooting Checklist

✅ Project opens without errors
✅ Scheme shows "Plena" target
✅ Build Configuration is "Debug"
✅ Simulator/Device selected
✅ App builds successfully
✅ App launches
✅ See 4 tabs including "Test Data"

---

## Next Steps

Once running in debug mode:

1. **Navigate to "Test Data" tab**
2. **Tap "Generate Test Data"**
3. **Wait for generation to complete**
4. **Go to "Dashboard" tab**
5. **Explore your test data!**

---

## Pro Tips

### Faster Development
- Keep simulator running between builds
- Use **⌘R** to rebuild and relaunch quickly
- Changes to code auto-reload in SwiftUI preview

### Testing on Device
1. Connect iPhone via USB
2. Select your device in scheme selector
3. Xcode will prompt to trust device
4. Run as normal - still in debug mode!

### Multiple Simulators
- You can run iPhone + Watch simulators simultaneously
- Useful for testing companion app features

---

**You're all set! Just press ⌘R to run in debug mode!** 🚀





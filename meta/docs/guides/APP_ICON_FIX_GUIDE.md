# App Icon Border Fix Guide

## Problem

The Plena app icon shows a dark blue border and doesn't fill the space properly. This is because iOS app icons need to be designed edge-to-edge with no padding.

## Solution

### For iOS App Icons:

1. **Icons must be square** (e.g., 1024x1024 for marketing icon)
2. **No padding or borders** - the design should extend to all edges
3. **No rounded corners** - iOS applies these automatically
4. **Background should fill the entire canvas** - no transparency around edges

### Current Issue

Your icon images likely have:

- Transparent padding around the edges
- A border built into the design
- The design doesn't extend to the canvas edges

### How to Fix

#### Option 1: Edit in Design Tool (Recommended)

1. Open your source icon design (should be 1024x1024 or larger)
2. Remove any padding/margins - design should touch all edges
3. Remove any border from the design
4. Ensure the background color extends to all edges
5. Export as PNG with no transparency (or solid background)
6. Regenerate all icon sizes from the master 1024x1024 version

#### Option 2: Use Image Tools to Remove Padding

If your icons have transparent padding, you can:

1. Use an image editor to extend the design to edges
2. Or use command-line tools to crop/expand

#### Option 3: Regenerate Icons

If you have a proper 1024x1024 master icon:

1. Use an icon generator tool or script
2. Generate all required sizes from the master
3. Replace all icons in the AppIcon.appiconset

### Required Icon Sizes

- **1024x1024** - Marketing icon (most important)
- **180x180** - iPhone App (3x, 60pt)
- **120x120** - iPhone App (2x, 60pt)
- **120x120** - iPhone App (3x, 40pt)
- **87x87** - iPhone Settings (3x, 29pt)
- **80x80** - iPhone Spotlight (2x, 40pt)
- **60x60** - iPhone App (3x, 20pt)
- **58x58** - iPhone Settings (2x, 29pt)
- **40x40** - iPhone App (2x, 20pt)
- Plus iPad and Watch sizes

### Testing

After updating icons:

1. Clean build folder (Cmd+Shift+K)
2. Delete app from device/simulator
3. Rebuild and install
4. Check icon appears correctly on home screen

### Best Practices

- Design at 1024x1024 or higher resolution
- Use a solid background color (no transparency)
- Design extends edge-to-edge
- No borders, shadows, or effects that create visual borders
- Keep important content away from edges (iOS may crop slightly)



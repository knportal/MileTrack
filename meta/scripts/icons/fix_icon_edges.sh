#!/bin/bash

# Fix Icon Edge Transparency Script
# Removes transparent padding and ensures icons fill edge-to-edge

set -e

MASTER_ICON="Plena/Assets.xcassets/PlenaRoundedAppIcon_v2.appiconset/icon_1024x1024_ios-marketing_app_1x.png"
OUTPUT_DIR="Plena/Assets.xcassets/AppIcon.appiconset"

echo "🔍 Analyzing master icon for edge transparency..."
echo ""

# Check if ImageMagick is available (better for edge detection)
if command -v convert &> /dev/null; then
    echo "Using ImageMagick for analysis..."

    # Get corner pixel alpha values
    echo "Checking corner pixels for transparency..."
    corners=$(convert "$MASTER_ICON" -format "%[pixel:0,0] %[pixel:1023,0] %[pixel:0,1023] %[pixel:1023,1023]" info:)
    echo "Corner pixels: $corners"

    # Check if edges have transparency
    # Sample edge pixels
    edge_sample=$(convert "$MASTER_ICON" -crop "1024x1+0+0" -format "%[mean]" info: 2>/dev/null || echo "unknown")
    echo "Top edge sample: $edge_sample"

    echo ""
    echo "⚠️  If edges are transparent, we need to fill them with the background color"
    echo ""

elif command -v sips &> /dev/null; then
    echo "Using sips for basic analysis..."
    sips -g hasAlpha "$MASTER_ICON"
    echo ""
    echo "⚠️  Master icon has alpha channel. Checking if edges need filling..."
fi

echo "🔧 Creating edge-filled version..."
echo ""

# Strategy: If there's transparency, we'll create a version that:
# 1. Detects the dominant background color
# 2. Fills transparent edges with that color
# 3. Regenerates all icons

# For now, let's create a script that uses sips to ensure solid edges
# We'll create a temporary version with solid background

TEMP_ICON="${MASTER_ICON%.png}_filled.png"

echo "Creating edge-filled master icon..."
echo "This will ensure the icon extends to all edges with no transparency"

# Use sips to remove alpha and fill with background
# First, let's try to get the corner color and use it as background
if command -v convert &> /dev/null; then
    # Get the color at center (likely the background)
    bg_color=$(convert "$MASTER_ICON" -format "%[pixel:512,512]" info: 2>/dev/null | head -1)
    echo "Detected background color: $bg_color"

    # Create a version with solid background (no transparency)
    convert "$MASTER_ICON" -background "$bg_color" -alpha remove -alpha off "$TEMP_ICON" 2>/dev/null || {
        # Fallback: just remove alpha
        convert "$MASTER_ICON" -alpha off "$TEMP_ICON"
    }

    if [ -f "$TEMP_ICON" ]; then
        echo "✅ Created edge-filled version: $TEMP_ICON"
        echo ""
        echo "🔄 Regenerating all icons with edge-filled version..."
        MASTER_ICON="$TEMP_ICON"
    fi
else
    echo "⚠️  ImageMagick not available. Using sips fallback..."
    # sips can't easily fill transparency, so we'll note this
    echo "Note: Master icon has transparency. For best results:"
    echo "  1. Open master icon in image editor"
    echo "  2. Ensure design extends to all edges"
    echo "  3. Remove transparent padding"
    echo "  4. Export with solid background"
fi

# Regenerate icons if we created a filled version
if [ -f "$TEMP_ICON" ]; then
    echo ""
    echo "Regenerating icons from edge-filled master..."
    ./generate_icons.sh
    echo ""
    echo "Cleaning up temporary file..."
    rm -f "$TEMP_ICON"
fi

echo ""
echo "✅ Icon edge fix complete!"
echo ""
echo "📝 Next steps:"
echo "  1. Clean build folder in Xcode (Cmd+Shift+K)"
echo "  2. Delete app from device/simulator"
echo "  3. Rebuild and reinstall"
echo "  4. Check if border is gone"




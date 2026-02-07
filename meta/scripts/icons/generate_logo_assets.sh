#!/bin/bash

# Script to generate 2x and 3x versions of the app logo
# Usage: ./generate_logo_assets.sh <source_image_path>

set -e

SOURCE_IMAGE="${1:-Plena/Assets.xcassets/AppIcon.appiconset/icon_ios_marketing_1024.png}"

if [ ! -f "$SOURCE_IMAGE" ]; then
    echo "Error: Source image not found at $SOURCE_IMAGE"
    echo "Usage: $0 <path_to_source_image>"
    exit 1
fi

# Get image dimensions
WIDTH=$(sips -g pixelWidth "$SOURCE_IMAGE" | tail -1 | awk '{print $2}')
HEIGHT=$(sips -g pixelHeight "$SOURCE_IMAGE" | tail -1 | awk '{print $2}')

if [ -z "$WIDTH" ] || [ "$WIDTH" -eq 0 ]; then
    echo "Error: Could not read image dimensions. Is the image file valid?"
    exit 1
fi

echo "Source image: $SOURCE_IMAGE"
echo "Dimensions: ${WIDTH}x${HEIGHT}"

# Calculate scaled dimensions
WIDTH_2X=$((WIDTH * 2))
HEIGHT_2X=$((HEIGHT * 2))
WIDTH_3X=$((WIDTH * 3))
HEIGHT_3X=$((HEIGHT * 3))

echo "Generating 2x version: ${WIDTH_2X}x${HEIGHT_2X}"
echo "Generating 3x version: ${WIDTH_3X}x${HEIGHT_3X}"

# iOS Assets
IOS_ASSETS_DIR="Plena/Assets.xcassets/AppLogo.imageset"
echo "Creating iOS assets in $IOS_ASSETS_DIR..."

# Copy 1x (assuming source is 1x, or scale if needed)
sips -z $HEIGHT $WIDTH "$SOURCE_IMAGE" --out "$IOS_ASSETS_DIR/PlenaAppLogo.png" > /dev/null 2>&1 || cp "$SOURCE_IMAGE" "$IOS_ASSETS_DIR/PlenaAppLogo.png"

# Generate 2x
sips -z $HEIGHT_2X $WIDTH_2X "$SOURCE_IMAGE" --out "$IOS_ASSETS_DIR/PlenaAppLogo@2x.png" > /dev/null 2>&1

# Generate 3x
sips -z $HEIGHT_3X $WIDTH_3X "$SOURCE_IMAGE" --out "$IOS_ASSETS_DIR/PlenaAppLogo@3x.png" > /dev/null 2>&1

# Watch Assets
WATCH_ASSETS_DIR="Plena Watch App/Assets.xcassets/AppLogo.imageset"
echo "Creating Watch assets in $WATCH_ASSETS_DIR..."

# For Watch, we typically use the same images but may need different sizes
# Copy 1x
cp "$IOS_ASSETS_DIR/PlenaAppLogo.png" "$WATCH_ASSETS_DIR/PlenaAppLogo.png"
# Copy 2x
cp "$IOS_ASSETS_DIR/PlenaAppLogo@2x.png" "$WATCH_ASSETS_DIR/PlenaAppLogo@2x.png"
# Copy 3x
cp "$IOS_ASSETS_DIR/PlenaAppLogo@3x.png" "$WATCH_ASSETS_DIR/PlenaAppLogo@3x.png"

echo ""
echo "✓ Logo assets generated successfully!"
echo ""
echo "iOS assets: $IOS_ASSETS_DIR"
echo "  - PlenaAppLogo.png (1x)"
echo "  - PlenaAppLogo@2x.png (2x)"
echo "  - PlenaAppLogo@3x.png (3x)"
echo ""
echo "Watch assets: $WATCH_ASSETS_DIR"
echo "  - PlenaAppLogo.png (1x)"
echo "  - PlenaAppLogo@2x.png (2x)"
echo "  - PlenaAppLogo@3x.png (3x)"



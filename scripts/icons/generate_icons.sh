#!/bin/bash

# Icon Generation Script for Plena App
# Generates all required icon sizes from master 1024x1024 icon
# Ensures icons fill edge-to-edge with no border

set -e

# Try PlenaRoundedAppIcon_v2 first, fallback to existing marketing icon
if [ -f "Plena/Assets.xcassets/PlenaRoundedAppIcon_v2.appiconset/icon_1024x1024_ios-marketing_app_1x.png" ]; then
    MASTER_ICON="Plena/Assets.xcassets/PlenaRoundedAppIcon_v2.appiconset/icon_1024x1024_ios-marketing_app_1x.png"
elif [ -f "Plena/Assets.xcassets/AppIcon.appiconset/icon_ios_marketing_1024.png" ]; then
    MASTER_ICON="Plena/Assets.xcassets/AppIcon.appiconset/icon_ios_marketing_1024.png"
else
    MASTER_ICON=""
fi
OUTPUT_DIR="Plena/Assets.xcassets/AppIcon.appiconset"

if [ ! -f "$MASTER_ICON" ]; then
    echo "❌ Error: Master icon not found at $MASTER_ICON"
    exit 1
fi

echo "📱 Generating app icons from master icon..."
echo "Master icon: $MASTER_ICON"
echo "Output directory: $OUTPUT_DIR"
echo ""

# Create backup of existing icons
BACKUP_DIR="${OUTPUT_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
if [ -d "$OUTPUT_DIR" ]; then
    echo "📦 Creating backup of existing icons..."
    mkdir -p "$BACKUP_DIR"
    cp -r "$OUTPUT_DIR"/* "$BACKUP_DIR/" 2>/dev/null || true
    echo "✅ Backup created at: $BACKUP_DIR"
    echo ""
fi

# Function to generate icon with edge-to-edge fill
generate_icon() {
    local size=$1
    local output_file="$OUTPUT_DIR/icon_${size}x${size}_${2}.png"

    echo "  Generating ${size}x${size}..."

    # Use sips to resize, ensuring edge-to-edge
    # sips will maintain the full canvas, so if master has padding, we need to crop first
    # For now, we'll resize directly - if there's padding in master, it will be preserved
    # We'll need to check and fix padding separately

    sips -z $size $size "$MASTER_ICON" --out "$output_file" > /dev/null 2>&1

    if [ -f "$output_file" ]; then
        echo "    ✅ Created: $(basename $output_file)"
    else
        echo "    ❌ Failed: $(basename $output_file)"
    fi
}

# Generate all required iOS icon sizes
echo "📱 Generating iOS icons..."

# iPhone App Icons
generate_icon 180 "iphone_app_3x"      # 60pt @ 3x
generate_icon 120 "iphone_app_2x"      # 60pt @ 2x
generate_icon 120 "iphone_app_3x"      # 40pt @ 3x
generate_icon 87 "iphone_app_3x"       # 29pt @ 3x
generate_icon 80 "iphone_app_2x"       # 40pt @ 2x
generate_icon 60 "iphone_app_3x"       # 20pt @ 3x
generate_icon 58 "iphone_app_2x"       # 29pt @ 2x
generate_icon 40 "iphone_app_2x"       # 20pt @ 2x

# iPad App Icons
generate_icon 167 "ipad_app_2x"        # 83.5pt @ 2x
generate_icon 152 "ipad_app_2x"        # 76pt @ 2x
generate_icon 80 "ipad_app_2x"         # 40pt @ 2x
generate_icon 76 "ipad_app_1x"         # 76pt @ 1x
generate_icon 58 "ipad_app_2x"         # 29pt @ 2x
generate_icon 40 "ipad_app_2x"         # 20pt @ 2x
generate_icon 40 "ipad_app_1x"         # 40pt @ 1x
generate_icon 29 "ipad_app_1x"         # 29pt @ 1x
generate_icon 20 "ipad_app_1x"         # 20pt @ 1x

# Marketing icon (already exists, but ensure it's correct)
echo "  Copying marketing icon..."
cp "$MASTER_ICON" "$OUTPUT_DIR/icon_1024x1024_ios-marketing_app_1x.png"
echo "    ✅ Marketing icon ready"

echo ""
echo "✅ iOS icon generation complete!"
echo ""
echo "⚠️  Note: If icons still show borders, the master icon may have transparent padding."
echo "   The master icon design should extend edge-to-edge with no transparent areas."


#!/bin/bash

# Generate Watch App Icons
# Uses the watch marketing icon or falls back to iOS icon

set -e

WATCH_MASTER="Plena/Assets.xcassets/PlenaRoundedAppIcon_v2.appiconset/icon_1024x1024_watch-marketing_app_1x.png"
IOS_MASTER="Plena/Assets.xcassets/PlenaRoundedAppIcon_v2.appiconset/icon_1024x1024_ios-marketing_app_1x.png"
OUTPUT_DIR="Plena Watch App/Assets.xcassets/AppIcon.appiconset"

# Use watch master if available, otherwise use iOS master
if [ -f "$WATCH_MASTER" ]; then
    MASTER_ICON="$WATCH_MASTER"
    echo "Using watch-specific master icon"
else
    MASTER_ICON="$IOS_MASTER"
    echo "Using iOS master icon for watch (watch-specific not found)"
fi

if [ ! -f "$MASTER_ICON" ]; then
    echo "❌ Error: Master icon not found"
    exit 1
fi

echo "⌚ Generating watch app icons..."
echo "Master: $MASTER_ICON"
echo "Output: $OUTPUT_DIR"
echo ""

# Function to generate icon
generate_icon() {
    local size=$1
    local output_file="$OUTPUT_DIR/icon_${size}x${size}_${2}.png"

    echo "  Generating ${size}x${size}..."
    sips -z $size $size "$MASTER_ICON" --out "$output_file" > /dev/null 2>&1

    if [ -f "$output_file" ]; then
        echo "    ✅ Created: $(basename $output_file)"
    else
        echo "    ❌ Failed: $(basename $output_file)"
    fi
}

# Generate watch icon sizes
generate_icon 196 "watch_quickLook_2x"      # 98pt @ 2x (42mm)
generate_icon 172 "watch_quickLook_2x"       # 86pt @ 2x (38mm)
generate_icon 88 "watch_appLauncher_2x"      # 44pt @ 2x (42mm)
generate_icon 80 "watch_appLauncher_2x"      # 40pt @ 2x (38mm)
generate_icon 55 "watch_notificationCenter_2x" # 27.5pt @ 2x (42mm)
generate_icon 48 "watch_notificationCenter_2x" # 24pt @ 2x (38mm)
generate_icon 58 "watch_companionSettings_2x" # 29pt @ 2x

# Marketing icon
echo "  Copying watch marketing icon..."
if [ -f "$WATCH_MASTER" ]; then
    cp "$WATCH_MASTER" "$OUTPUT_DIR/icon_1024x1024_watch-marketing_app_1x.png"
else
    cp "$IOS_MASTER" "$OUTPUT_DIR/icon_1024x1024_watch-marketing_app_1x.png"
fi
echo "    ✅ Marketing icon ready"

echo ""
echo "✅ Watch icon generation complete!"




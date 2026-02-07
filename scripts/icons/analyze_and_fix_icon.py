#!/usr/bin/env python3
"""
Analyze and fix app icon edge transparency
Ensures icons fill edge-to-edge with no border
"""

import sys
import os
from pathlib import Path

try:
    from PIL import Image
    import numpy as np
except ImportError:
    print("⚠️  PIL/Pillow not available. Installing...")
    print("   Run: pip3 install Pillow numpy")
    sys.exit(1)

def analyze_icon_edges(image_path):
    """Analyze icon for edge transparency"""
    img = Image.open(image_path)
    width, height = img.size

    print(f"📊 Analyzing: {os.path.basename(image_path)}")
    print(f"   Size: {width}x{height}")
    print(f"   Mode: {img.mode}")

    if img.mode != 'RGBA':
        print("   ✅ No alpha channel - icon should be fine")
        return False

    # Convert to numpy for analysis
    img_array = np.array(img)
    alpha = img_array[:, :, 3] if len(img_array.shape) == 3 else None

    if alpha is None:
        print("   ✅ No alpha channel")
        return False

    # Check edge pixels
    edge_pixels = np.concatenate([
        alpha[0, :],           # Top edge
        alpha[-1, :],          # Bottom edge
        alpha[:, 0],           # Left edge
        alpha[:, -1]           # Right edge
    ])

    transparent_count = np.sum(edge_pixels < 255)
    total_edge = len(edge_pixels)
    transparent_percent = (transparent_count / total_edge) * 100

    print(f"   Edge transparency: {transparent_percent:.1f}% ({transparent_count}/{total_edge} pixels)")

    if transparent_percent > 5:
        print("   ⚠️  WARNING: Significant edge transparency detected!")
        print("      This will cause the dark blue border effect.")
        return True
    else:
        print("   ✅ Edges are mostly opaque")
        return False

def fix_icon_edges(image_path, output_path):
    """Fix icon by filling transparent edges with background color"""
    img = Image.open(image_path)
    width, height = img.size

    if img.mode != 'RGBA':
        print(f"   ℹ️  No transparency to fix, copying as-is")
        img.save(output_path)
        return

    # Get background color from center area (most likely the actual background)
    center_x, center_y = width // 2, height // 2
    # Sample a small area around center
    sample_size = min(100, width // 4, height // 4)
    sample = img.crop((
        center_x - sample_size // 2,
        center_y - sample_size // 2,
        center_x + sample_size // 2,
        center_y + sample_size // 2
    ))

    # Get most common color (background)
    colors = sample.getcolors(maxcolors=256*256*256)
    if colors:
        # Sort by frequency and get most common
        colors.sort(reverse=True, key=lambda x: x[0])
        bg_color = colors[0][1]

        # If bg_color has alpha, make it opaque
        if isinstance(bg_color, tuple) and len(bg_color) == 4:
            bg_color = bg_color[:3]  # Remove alpha

        print(f"   🎨 Detected background color: {bg_color}")

        # Create new image with solid background
        new_img = Image.new('RGB', (width, height), bg_color)

        # Paste original image on top (this will composite properly)
        if img.mode == 'RGBA':
            new_img.paste(img, (0, 0), img.split()[3])  # Use alpha channel as mask
        else:
            new_img.paste(img, (0, 0))

        new_img.save(output_path, 'PNG')
        print(f"   ✅ Created edge-filled version: {os.path.basename(output_path)}")
    else:
        # Fallback: just remove alpha
        new_img = img.convert('RGB')
        new_img.save(output_path, 'PNG')
        print(f"   ✅ Removed alpha channel: {os.path.basename(output_path)}")

def main():
    master_icon = "Plena/Assets.xcassets/PlenaRoundedAppIcon_v2.appiconset/icon_1024x1024_ios-marketing_app_1x.png"

    if not os.path.exists(master_icon):
        print(f"❌ Master icon not found: {master_icon}")
        sys.exit(1)

    print("🔍 Step 1: Analyzing master icon for edge issues...\n")
    has_issues = analyze_icon_edges(master_icon)

    if has_issues:
        print("\n🔧 Step 2: Fixing edge transparency...\n")
        fixed_icon = master_icon.replace('.png', '_fixed.png')
        fix_icon_edges(master_icon, fixed_icon)

        print(f"\n✅ Fixed icon created: {fixed_icon}")
        print("\n📝 Next steps:")
        print("   1. Review the fixed icon")
        print("   2. If it looks good, replace the master icon")
        print("   3. Run generate_icons.sh again")
    else:
        print("\n✅ Master icon looks good! No edge transparency issues.")
        print("   If you still see borders, the issue might be in the design itself.")
        print("   Ensure the icon design extends to all edges with no padding.")

if __name__ == "__main__":
    main()




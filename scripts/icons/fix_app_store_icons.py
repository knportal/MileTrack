#!/usr/bin/env python3
"""
Fix app icons for App Store submission by removing alpha channels.

Apple requires all app icons to be opaque (no transparency/alpha channel).
This script:
1. Removes alpha channels from all icons by compositing onto white background
2. Creates missing Watch icons (108x108@2x for Series 4)
3. Saves icons as opaque PNG files
"""

import os
import sys
import json
from PIL import Image

def remove_alpha_channel(image_path, output_path=None, background_color=(255, 255, 255)):
    """
    Remove alpha channel from an image by compositing onto a solid background.

    Args:
        image_path: Path to input image
        output_path: Path to save output (defaults to overwriting input)
        background_color: RGB tuple for background (default white)

    Returns:
        True if successful, False otherwise
    """
    try:
        # Open image
        img = Image.open(image_path)

        # Convert to RGB if image has alpha channel
        if img.mode in ('RGBA', 'LA', 'P'):
            # Create white background
            background = Image.new('RGB', img.size, background_color)

            # Composite image onto background (handles transparency)
            if img.mode == 'P':
                img = img.convert('RGBA')
            if img.mode == 'LA':
                img = img.convert('RGBA')

            # Composite with alpha blending
            background.paste(img, mask=img.split()[3] if img.mode == 'RGBA' else None)
            img = background
        elif img.mode != 'RGB':
            img = img.convert('RGB')

        # Save as RGB (no alpha)
        output = output_path if output_path else image_path
        img.save(output, 'PNG', optimize=False)
        print(f"✓ Fixed: {os.path.basename(image_path)}")
        return True

    except Exception as e:
        print(f"✗ Error processing {image_path}: {e}")
        return False

def create_watch_108_icon(source_icon_path, output_path, size=(216, 216)):
    """
    Create the missing 108x108@2x (216x216) Watch icon from a source icon.

    Args:
        source_icon_path: Path to source icon (will use largest available)
        output_path: Path to save the new 108x108@2x icon
        size: Target size (216x216 for 108pt@2x)
    """
    try:
        # Open source icon
        img = Image.open(source_icon_path)

        # Remove alpha if present
        if img.mode in ('RGBA', 'LA', 'P'):
            background = Image.new('RGB', img.size, (255, 255, 255))
            if img.mode == 'P':
                img = img.convert('RGBA')
            if img.mode == 'LA':
                img = img.convert('RGBA')
            background.paste(img, mask=img.split()[3] if img.mode == 'RGBA' else None)
            img = background
        elif img.mode != 'RGB':
            img = img.convert('RGB')

        # Resize to target size with high-quality resampling
        img_resized = img.resize(size, Image.Resampling.LANCZOS)

        # Save
        img_resized.save(output_path, 'PNG', optimize=False)
        print(f"✓ Created: {os.path.basename(output_path)} (216x216)")
        return True

    except Exception as e:
        print(f"✗ Error creating 108x108 icon: {e}")
        return False

def process_icon_set(icon_set_path, watch_set=False):
    """
    Process all icons in an icon set to remove alpha channels.

    Args:
        icon_set_path: Path to .appiconset directory
        watch_set: If True, also handle missing 108x108 icon
    """
    if not os.path.exists(icon_set_path):
        print(f"Error: Directory not found: {icon_set_path}")
        return False

    contents_json = os.path.join(icon_set_path, 'Contents.json')
    if not os.path.exists(contents_json):
        print(f"Error: Contents.json not found in {icon_set_path}")
        return False

    # Read Contents.json
    with open(contents_json, 'r') as f:
        contents = json.load(f)

    # Process all existing icons
    print(f"\nProcessing icons in: {icon_set_path}")
    print("-" * 60)

    fixed_count = 0
    missing_icons = []

    for image_entry in contents.get('images', []):
        filename = image_entry.get('filename')
        if not filename:
            # Missing icon
            size = image_entry.get('size', 'unknown')
            role = image_entry.get('role', 'unknown')
            missing_icons.append({
                'entry': image_entry,
                'size': size,
                'role': role
            })
            continue

        icon_path = os.path.join(icon_set_path, filename)
        if os.path.exists(icon_path):
            if remove_alpha_channel(icon_path):
                fixed_count += 1
        else:
            print(f"⚠ Missing file: {filename}")

    # Handle missing Watch icons
    if watch_set and missing_icons:
        print(f"\nCreating {len(missing_icons)} missing icon(s)...")

        # Find a source icon to resize (prefer 1024x1024 or largest available)
        source_icon = None
        source_size = 0

        for image_entry in contents.get('images', []):
            filename = image_entry.get('filename')
            if filename:
                icon_path = os.path.join(icon_set_path, filename)
                if os.path.exists(icon_path):
                    try:
                        img = Image.open(icon_path)
                        if img.width * img.height > source_size:
                            source_size = img.width * img.height
                            source_icon = icon_path
                    except:
                        pass

        if not source_icon:
            print("✗ No source icon found to create missing icons")
            return False

        # Create missing icons
        for missing in missing_icons:
            entry = missing['entry']
            size_str = missing['size']
            role = missing['role']

            # Parse size (e.g., "108x108")
            if 'x' in size_str:
                try:
                    width_pt, height_pt = map(int, size_str.split('x'))
                    scale = entry.get('scale', '1x')
                    scale_factor = int(scale.replace('x', ''))
                    pixel_size = (width_pt * scale_factor, height_pt * scale_factor)

                    # Generate filename
                    filename = f"icon_watch_{pixel_size[0]}.png"
                    output_path = os.path.join(icon_set_path, filename)

                    if create_watch_108_icon(source_icon, output_path, pixel_size):
                        # Update Contents.json
                        entry['filename'] = filename

                except ValueError as e:
                    print(f"✗ Could not parse size '{size_str}': {e}")

        # Save updated Contents.json
        with open(contents_json, 'w') as f:
            json.dump(contents, f, indent=2)
        print(f"\n✓ Updated Contents.json")

    print(f"\n{'='*60}")
    print(f"✓ Successfully processed {fixed_count} icon(s)")
    if watch_set and missing_icons:
        print(f"✓ Created {len(missing_icons)} missing icon(s)")
    print(f"{'='*60}\n")

    return True

def main():
    """Main entry point."""
    if len(sys.argv) < 2:
        print("Usage: python3 fix_app_store_icons.py <icon_set_path> [watch_set]")
        print("\nExamples:")
        print("  python3 fix_app_store_icons.py ../Plena/Assets.xcassets/AppIcon.appiconset")
        print("  python3 fix_app_store_icons.py ../Plena\\ Watch\\ App/Assets.xcassets/AppIcon.appiconset watch")
        print("\nThis script removes alpha channels from all icons to comply with App Store requirements.")
        sys.exit(1)

    icon_set = sys.argv[1]
    is_watch_set = len(sys.argv) > 2 and sys.argv[2].lower() == 'watch'

    print("=" * 60)
    print("App Store Icon Fixer")
    print("=" * 60)
    print("Removing alpha channels from all icons...")

    success = process_icon_set(icon_set, watch_set=is_watch_set)

    if success:
        print("✓ All icons have been fixed!")
        print("\nNext steps:")
        print("1. Verify icons in Xcode look correct")
        print("2. Clean build folder (Product > Clean Build Folder)")
        print("3. Archive and resubmit to App Store Connect")
    else:
        print("✗ Some errors occurred. Please check the output above.")
        sys.exit(1)

if __name__ == '__main__':
    main()






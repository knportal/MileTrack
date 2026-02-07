#!/usr/bin/env python3
"""
Script to remove white borders from app icon images.
Removes white pixels around the edges of the head silhouette.
"""

import os
import sys
from PIL import Image
import numpy as np

def remove_white_border(image_path, output_path, threshold=240):
    """
    Remove white borders from an image by making white pixels transparent
    or removing them if they're on the edge of the design element.

    Args:
        image_path: Path to input image
        output_path: Path to save processed image
        threshold: RGB threshold for "white" (0-255, default 240)
    """
    try:
        # Open image
        img = Image.open(image_path)

        # Convert to RGBA if not already
        if img.mode != 'RGBA':
            img = img.convert('RGBA')

        # Convert to numpy array for processing
        data = np.array(img)

        # Create mask for white pixels (RGB all above threshold)
        # We'll make white pixels transparent
        white_mask = (data[:, :, 0] > threshold) & \
                    (data[:, :, 1] > threshold) & \
                    (data[:, :, 2] > threshold)

        # Make white pixels transparent
        data[white_mask, 3] = 0  # Set alpha to 0 for white pixels

        # Convert back to PIL Image
        result = Image.fromarray(data)

        # Save result
        result.save(output_path, 'PNG', optimize=True)
        print(f"✓ Processed: {os.path.basename(image_path)}")
        return True

    except Exception as e:
        print(f"✗ Error processing {image_path}: {e}")
        return False

def process_icon_set(icon_set_path, output_path=None):
    """
    Process all PNG files in an icon set directory.

    Args:
        icon_set_path: Path to .appiconset directory
        output_path: Optional output directory (defaults to same location with _noborder suffix)
    """
    if not os.path.exists(icon_set_path):
        print(f"Error: Directory not found: {icon_set_path}")
        return False

    # Get all PNG files
    png_files = [f for f in os.listdir(icon_set_path) if f.endswith('.png')]

    if not png_files:
        print(f"No PNG files found in {icon_set_path}")
        return False

    print(f"Found {len(png_files)} icon files to process...")
    print(f"Processing icons in: {icon_set_path}\n")

    # Process each file
    success_count = 0
    for png_file in png_files:
        input_path = os.path.join(icon_set_path, png_file)

        if output_path:
            os.makedirs(output_path, exist_ok=True)
            output_file = os.path.join(output_path, png_file)
        else:
            # Backup original and replace
            backup_path = input_path + '.backup'
            if not os.path.exists(backup_path):
                os.rename(input_path, backup_path)
            output_file = input_path

        if remove_white_border(input_path if not output_path else input_path, output_file):
            success_count += 1

    print(f"\n✓ Successfully processed {success_count}/{len(png_files)} icons")
    return success_count == len(png_files)

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python3 remove_icon_border.py <icon_set_path> [output_path]")
        print("\nExample:")
        print("  python3 remove_icon_border.py ../PlenaRoundedAppIcon_v2.appiconset")
        print("  python3 remove_icon_border.py ../PlenaRoundedAppIcon_v2.appiconset ./output")
        sys.exit(1)

    icon_set = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else None

    process_icon_set(icon_set, output_dir)



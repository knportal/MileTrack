# App Logo Setup Instructions

## Current Status

The asset catalog structure has been set up for both iOS and Watch apps with support for:

- **iOS**: 1x, 2x, and 3x scale versions
- **Watch**: Multiple Watch sizes (38mm, 42mm, 44mm, 45mm, 49mm)

## Adding Your Logo Image

The app logo assets are automatically generated from the app icon marketing image.

### Option 1: Automatic Generation (Recommended)

1. The script uses the marketing icon from `Plena/Assets.xcassets/AppIcon.appiconset/icon_ios_marketing_1024.png` by default

   - Or specify a custom source image path when running the script

2. Run the generation script:

   ```bash
   ./generate_logo_assets.sh
   ```

   Or specify a custom source image:

   ```bash
   ./generate_logo_assets.sh /path/to/your/logo.png
   ```

3. The script will automatically:
   - Generate 2x and 3x versions for iOS
   - Copy all versions to the Watch app assets
   - Place files in the correct asset catalog locations

### Option 2: Manual Setup

1. **For iOS App** (`Plena/Assets.xcassets/AppLogo.imageset/`):

   - Add `PlenaAppLogo.png` (1x - base size, e.g., 1024x1024)
   - Add `PlenaAppLogo@2x.png` (2x - double size, e.g., 2048x2048)
   - Add `PlenaAppLogo@3x.png` (3x - triple size, e.g., 3072x3072)

2. **For Watch App** (`Plena Watch App/Assets.xcassets/AppLogo.imageset/`):
   - Add the same image files as iOS
   - Watch will automatically use the appropriate size based on device

## Recommended Logo Sizes

For best results, your source logo should be:

- **Minimum**: 1024x1024 pixels (will be scaled up for 2x/3x)
- **Recommended**: 2048x2048 pixels or higher (better quality when scaled)
- **Format**: PNG with transparency support

## Usage in Code

Once the images are in place, use the logo in SwiftUI:

```swift
// Basic usage
Image("AppLogo")
    .resizable()
    .scaledToFit()

// With specific size
Image("AppLogo")
    .resizable()
    .scaledToFit()
    .frame(width: 100, height: 100)

// As an icon
Image("AppLogo")
    .resizable()
    .scaledToFit()
    .frame(width: 40, height: 40)
```

## Asset Catalog Structure

```
Plena/Assets.xcassets/AppLogo.imageset/
├── Contents.json
├── PlenaAppLogo.png (1x)
├── PlenaAppLogo@2x.png (2x)
└── PlenaAppLogo@3x.png (3x)

Plena Watch App/Assets.xcassets/AppLogo.imageset/
├── Contents.json
├── PlenaAppLogo.png (1x)
├── PlenaAppLogo@2x.png (2x)
└── PlenaAppLogo@3x.png (3x)
```

## Notes

- Xcode will automatically recognize the asset catalog structure
- The `@2x` and `@3x` suffixes tell iOS which image to use for different screen densities
- All image files are currently placeholders and need to be replaced with actual logo images



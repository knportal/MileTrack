#!/bin/bash
# Permanent fix for PrimaryColor/SecondaryColor warnings
# Run this script whenever the warnings reappear

cd "$(dirname "$0")"

echo "🧹 Cleaning up PrimaryColor/SecondaryColor directories..."

# Remove from main app
rm -rf "Plena/Assets.xcassets/PrimaryColor.colorset"
rm -rf "Plena/Assets.xcassets/SecondaryColor.colorset"

# Remove from watch app
rm -rf "Plena Watch App/Assets.xcassets/PrimaryColor.colorset"
rm -rf "Plena Watch App/Assets.xcassets/SecondaryColor.colorset"

# Clear DerivedData
echo "🧹 Clearing DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Plena-*

echo "✅ Cleanup complete!"
echo ""
echo "Next steps:"
echo "  1. Clean build folder in Xcode (Cmd+Shift+K)"
echo "  2. Rebuild the project"
echo ""
echo "If warnings persist, check Xcode's asset catalog editor"
echo "and ensure PrimaryColor/SecondaryColor are not listed there."

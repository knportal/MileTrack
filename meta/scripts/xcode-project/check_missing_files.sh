#!/bin/bash
# Script to check for Swift files that exist but aren't in the Xcode project
# Usage: ./check_missing_files.sh [--fix] [--verbose]

set -e

PROJECT_FILE="Plena.xcodeproj/project.pbxproj"
FIX_MODE=false
VERBOSE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --fix)
            FIX_MODE=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--fix] [--verbose]"
            exit 1
            ;;
    esac
done

if [ ! -f "$PROJECT_FILE" ]; then
    echo "❌ Error: Project file not found: $PROJECT_FILE"
    exit 1
fi

echo "🔍 Checking for Swift files not in Xcode project..."
echo ""

# Find all Swift files in the project directories
SWIFT_FILES=$(find Plena Plena\ Watch\ App PlenaShared Tests -name "*.swift" -type f 2>/dev/null | sort)

if [ -z "$SWIFT_FILES" ]; then
    echo "⚠️  No Swift files found in project directories"
    exit 0
fi

MISSING_FILES=()
TOTAL_FILES=0

# Check each Swift file
while IFS= read -r file; do
    TOTAL_FILES=$((TOTAL_FILES + 1))

    # Get just the filename
    filename=$(basename "$file")

    # Check if file is referenced in project.pbxproj
    if ! grep -q "$filename" "$PROJECT_FILE"; then
        MISSING_FILES+=("$file")
        if [ "$VERBOSE" = true ]; then
            echo "  ❌ Missing: $file"
        fi
    fi
done <<< "$SWIFT_FILES"

echo "📊 Summary:"
echo "   Total Swift files: $TOTAL_FILES"
echo "   Missing from project: ${#MISSING_FILES[@]}"
echo ""

if [ ${#MISSING_FILES[@]} -eq 0 ]; then
    echo "✅ All Swift files are included in the Xcode project!"
    exit 0
fi

echo "❌ Found ${#MISSING_FILES[@]} file(s) not in Xcode project:"
for file in "${MISSING_FILES[@]}"; do
    echo "   - $file"
done
echo ""

if [ "$FIX_MODE" = false ]; then
    echo "💡 To automatically add these files, run:"
    echo "   $0 --fix"
    echo ""
    echo "⚠️  Note: Auto-adding files requires manual verification in Xcode"
    exit 1
fi

echo "⚠️  Auto-fix mode: Files need to be manually added to Xcode project"
echo "   This script can only detect missing files, not automatically add them"
echo "   Please add these files through Xcode's 'Add Files to Project' feature"
echo ""
echo "📝 Files to add:"
for file in "${MISSING_FILES[@]}"; do
    echo "   $file"
done

exit 1



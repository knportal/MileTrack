#!/bin/bash
# Script to be run as an Xcode build phase
# This ensures all Swift files are in the project before building
#
# IMPORTANT: In Xcode Build Phase settings:
# - Uncheck "Based on dependency analysis" to avoid path issues
# - OR use a relative output path if you want dependency analysis

# Use SRCROOT if available (Xcode sets this), otherwise detect it
if [ -z "$SRCROOT" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    SRCROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
fi

cd "$SRCROOT"

# Run the script and capture output
# We suppress warnings but show actual errors
OUTPUT=$(python3 "$SRCROOT/scripts/add_missing_files_to_project.py" 2>&1)
EXIT_CODE=$?

# Check if there were real errors (not just warnings)
if [ $EXIT_CODE -ne 0 ]; then
    # Check if it's a real error or just warnings
    if echo "$OUTPUT" | grep -qE "❌ Error|error:"; then
        echo "$OUTPUT" | grep -E "(❌ Error|error:)" >&2
        exit 1
    fi
    # Otherwise, it's just warnings - continue
fi

# Exit successfully
exit 0


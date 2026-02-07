#!/bin/bash
# File watcher that automatically adds new Swift files to Xcode project
# Run this in the background: ./scripts/watch_for_new_files.sh &

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

# Check if fswatch is installed
if ! command -v fswatch &> /dev/null; then
    echo "❌ fswatch is not installed. Install it with:"
    echo "   brew install fswatch"
    echo ""
    echo "Alternatively, use the Xcode build phase or git hooks for automatic checking."
    exit 1
fi

echo "👀 Watching for new Swift files..."
echo "   Press Ctrl+C to stop"
echo ""

# Watch for new .swift files in project directories
fswatch -o \
    "Plena/**/*.swift" \
    "Plena Watch App/**/*.swift" \
    "PlenaShared/**/*.swift" \
    "Tests/**/*.swift" \
    | while read num; do
    echo "📝 Detected Swift file changes, checking for missing files..."
    python3 "$SCRIPT_DIR/add_missing_files_to_project.py" 2>&1 | grep -E "(Found|Successfully|Error)" || true
done





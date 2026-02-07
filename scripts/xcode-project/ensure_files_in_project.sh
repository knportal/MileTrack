#!/bin/bash
# Quick script to ensure all Swift files are in the Xcode project
# Run this after creating new Swift files

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "🔍 Checking for missing files in Xcode project..."
python3 "$SCRIPT_DIR/add_missing_files_to_project.py" --dry-run

if [ $? -eq 0 ]; then
    echo ""
    read -p "Add missing files to project? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        python3 "$SCRIPT_DIR/add_missing_files_to_project.py"
    fi
else
    echo "✅ All files are in the project!"
fi





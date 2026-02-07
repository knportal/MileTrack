#!/bin/bash

# Find and delete Core Data store files for {{APP_NAME}} app
echo "Searching for {{APP_NAME}} Core Data stores..."

# For Simulator
SIMULATOR_DIR="$HOME/Library/Developer/CoreSimulator/Devices"
if [ -d "$SIMULATOR_DIR" ]; then
    echo "Checking Simulator devices..."
    find "$SIMULATOR_DIR" -name "{{DATA_MODEL_NAME}}.sqlite*" -type f 2>/dev/null | while read file; do
        echo "Found: $file"
        rm -f "$file"
        echo "Deleted: $file"
    done

    # Also delete .sqlite-wal and .sqlite-shm files
    find "$SIMULATOR_DIR" -name "{{DATA_MODEL_NAME}}.sqlite-wal" -type f 2>/dev/null -delete
    find "$SIMULATOR_DIR" -name "{{DATA_MODEL_NAME}}.sqlite-shm" -type f 2>/dev/null -delete
fi

echo "Done! Core Data stores deleted."
echo "Now rebuild and run the app - it will create a new local-only store."

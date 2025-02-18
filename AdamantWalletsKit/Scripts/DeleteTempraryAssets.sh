#!/bin/bash

# Automatically determine the root of the project
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)

# Path to the TemporaryAssets folder
TEMP_ASSETS_PATH="$ROOT/AdamantWalletsKit/Sources/AdamantWalletsKit/TemporaryAssets"

echo "ROOT: $ROOT"
echo "TEMP_ASSETS_PATH: $TEMP_ASSETS_PATH"

# Check if the TemporaryAssets directory exists
if [ -d "$TEMP_ASSETS_PATH" ]; then
    echo "Removing TemporaryAssets folder: $TEMP_ASSETS_PATH..."
    rm -rf "$TEMP_ASSETS_PATH"
    echo "TemporaryAssets folder has been successfully removed."
else
    echo "TemporaryAssets folder does not exist: $TEMP_ASSETS_PATH"
fi

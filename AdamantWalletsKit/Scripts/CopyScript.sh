#!/bin/bash

# Define the base project directory (the folder where this script is located)
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd "$SCRIPT_DIR/../.." && pwd)  # Project root directory

# Package details
PACKAGE_NAME="adamant-wallets"
GITHUB_REPO="https://github.com/Adamant-im/adamant-wallets.git"
TARGET_DIR="$PROJECT_ROOT/$PACKAGE_NAME"

# Remove the old version and clone the new one
if [ -d "$TARGET_DIR" ]; then
    echo "Removing old version of $PACKAGE_NAME..."
    rm -rf "$TARGET_DIR"
fi

echo "Cloning $PACKAGE_NAME from GitHub..."
git clone --depth 1 --branch dev "$GITHUB_REPO" "$TARGET_DIR"

# Check if cloning was successful
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Failed to download $PACKAGE_NAME from GitHub."
    exit 1
fi

# Define paths for required directories
ASSETS_PATH="$TARGET_DIR/assets"
ADAMANTWALLETSKIT_PATH="$PROJECT_ROOT/AdamantWalletsKit"
JSON_STORE_PATH="$ADAMANTWALLETSKIT_PATH/Sources/AdamantWalletsKit/JsonStore"
TEMP_ASSETS_PATH="$ADAMANTWALLETSKIT_PATH/Sources/AdamantWalletsKit/TemporaryAssets"

# Clear and create necessary directories
rm -rf "$JSON_STORE_PATH" "$TEMP_ASSETS_PATH"
mkdir -p "$JSON_STORE_PATH" "$TEMP_ASSETS_PATH"

# Copy blockchain assets
cp -R "$ASSETS_PATH/blockchains" "$JSON_STORE_PATH"

# Process the "general" folder
GENERAL_PATH="$ASSETS_PATH/general"
if [ -d "$GENERAL_PATH" ]; then
    echo "Processing 'general' folder..."

    for TOKEN_FOLDER in "$GENERAL_PATH"/*; do
        if [ -d "$TOKEN_FOLDER" ]; then
            TOKEN_NAME=$(basename "$TOKEN_FOLDER")

            # Create directories
            mkdir -p "$JSON_STORE_PATH/general/$TOKEN_NAME"
            mkdir -p "$TEMP_ASSETS_PATH/general/$TOKEN_NAME"

            # Copy JSON files
            find "$TOKEN_FOLDER" -maxdepth 1 -type f -name "*.json" -exec cp {} "$JSON_STORE_PATH/general/$TOKEN_NAME" \;

            # Copy images folder
            if [ -d "$TOKEN_FOLDER/images" ]; then
                cp -R "$TOKEN_FOLDER/images" "$TEMP_ASSETS_PATH/general/$TOKEN_NAME"
            fi
        fi
    done

    echo "Processing of 'general' folder completed."
else
    echo "Error: 'general' folder not found at path $GENERAL_PATH."
    exit 1
fi

# Remove the downloaded package after processing
echo "Cleaning up: Removing downloaded package $PACKAGE_NAME..."
rm -rf "$TARGET_DIR"

echo "Script execution completed successfully."

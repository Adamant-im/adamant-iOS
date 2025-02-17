DERIVED_DATA_BASE=~/Library/Developer/Xcode/DerivedData
PACKAGE_NAME="adamant-wallets"
PACKAGE_PATH=$(find "$DERIVED_DATA_BASE" -type d -path "*/SourcePackages/checkouts/$PACKAGE_NAME" 2>/dev/null | head -n 1)

# Check if the package path was found
if [ -z "$PACKAGE_PATH" ]; then
    echo "Error: Could not find dependency folder $PACKAGE_NAME in DerivedData."
    exit 1
fi

# Path to the assets folder within the dependency
ASSETS_PATH="$PACKAGE_PATH/assets"

# Determine the script's directory
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ADAMANTWALLETSKIT_PATH=$(cd "$SCRIPT_DIR/../../AdamantWalletsKit" && pwd)

# Paths for output
JSON_STORE_PATH="$ADAMANTWALLETSKIT_PATH/Sources/AdamantWalletsKit/JsonStore"
TEMP_ASSETS_PATH="$ADAMANTWALLETSKIT_PATH/Sources/AdamantWalletsKit/TemporaryAssets"

# Clear or create necessary directories
rm -rf "$JSON_STORE_PATH" "$TEMP_ASSETS_PATH"
mkdir -p "$JSON_STORE_PATH" "$TEMP_ASSETS_PATH"

# Copy the blockchains folder to JsonStore
cp -R "$ASSETS_PATH/blockchains" "$JSON_STORE_PATH"

# Process the general folder
GENERAL_PATH="$ASSETS_PATH/general"
if [ -d "$GENERAL_PATH" ]; then
    echo "Processing general folder..."

    for TOKEN_FOLDER in "$GENERAL_PATH"/*; do
        if [ -d "$TOKEN_FOLDER" ]; then
            TOKEN_NAME=$(basename "$TOKEN_FOLDER")

            # Create folders for JsonStore and TemporaryAssets
            mkdir -p "$JSON_STORE_PATH/general/$TOKEN_NAME"
            mkdir -p "$TEMP_ASSETS_PATH/general/$TOKEN_NAME"

            # Copy JSON files to JsonStore
            find "$TOKEN_FOLDER" -maxdepth 1 -type f -name "*.json" -exec cp {} "$JSON_STORE_PATH/general/$TOKEN_NAME" \;

            # Copy images folder to TemporaryAssets
            if [ -d "$TOKEN_FOLDER/images" ]; then
                cp -R "$TOKEN_FOLDER/images" "$TEMP_ASSETS_PATH/general/$TOKEN_NAME"
            fi
        fi
    done

    echo "General folder processing completed."
else
    echo "Error: General folder not found at path $GENERAL_PATH."
    exit 1
fi

echo "Script completed successfully."

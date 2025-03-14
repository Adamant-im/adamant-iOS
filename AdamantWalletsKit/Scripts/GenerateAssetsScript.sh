#!/bin/bash

# Automatically determine the root of the project
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)

# Paths
TEMP_ASSETS_PATH="$ROOT/AdamantWalletsKit/Sources/AdamantWalletsKit/TemporaryAssets/General"
WALLETS_ASSETS_PATH="$ROOT/AdamantWalletsKit/Sources/AdamantWalletsKit/Wallets.xcassets"
NOTIFICATION_IMAGES_PATH="$ROOT/NotificationServiceExtension/WalletImages"

echo "ROOT: $ROOT"
echo "TEMP_ASSETS_PATH: $TEMP_ASSETS_PATH"
echo "WALLETS_ASSETS_PATH: $WALLETS_ASSETS_PATH"
echo "NOTIFICATION_IMAGES_PATH: $NOTIFICATION_IMAGES_PATH"

# Remove old asset folders
rm -rf "$NOTIFICATION_IMAGES_PATH" "$WALLETS_ASSETS_PATH"
mkdir -p "$NOTIFICATION_IMAGES_PATH" "$WALLETS_ASSETS_PATH"

echo "Created new WalletImages and Wallets.xcassets folders."

# Function to create Contents.json
function create_contents {
    TARGET=$1
    IMAGE_NAME=$2
    WITH_DARK=$3

    echo "Generating Contents.json for $TARGET..."

    if [ "$WITH_DARK" = true ]; then
        cat > "${TARGET}/Contents.json" << __EOF__
{
  "images" : [
    { "filename" : "${IMAGE_NAME}.png", "idiom" : "universal", "scale" : "1x" },
    { "filename" : "${IMAGE_NAME}@2x.png", "idiom" : "universal", "scale" : "2x" },
    { "filename" : "${IMAGE_NAME}@3x.png", "idiom" : "universal", "scale" : "3x" },
    { "appearances": [{ "appearance": "luminosity", "value": "dark" }], "filename": "${IMAGE_NAME}_dark.png", "idiom": "universal", "scale": "1x" },
    { "appearances": [{ "appearance": "luminosity", "value": "dark" }], "filename": "${IMAGE_NAME}_dark@2x.png", "idiom": "universal", "scale": "2x" },
    { "appearances": [{ "appearance": "luminosity", "value": "dark" }], "filename": "${IMAGE_NAME}_dark@3x.png", "idiom": "universal", "scale": "3x" }
  ],
  "info": { "author": "xcode", "version": 1 }
}
__EOF__
    else
        cat > "${TARGET}/Contents.json" << __EOF__
{
  "images" : [
    { "filename" : "${IMAGE_NAME}.png", "idiom" : "universal", "scale" : "1x" },
    { "filename" : "${IMAGE_NAME}@2x.png", "idiom" : "universal", "scale" : "2x" },
    { "filename" : "${IMAGE_NAME}@3x.png", "idiom" : "universal", "scale" : "3x" }
  ],
  "info": { "author": "xcode", "version": 1 }
}
__EOF__
    fi
}

# Function to copy images with fallback to wallet icons
function copy_images_with_fallback {
    SOURCE_DIR=$1
    IMAGE_NAME=$2
    DEST_DIR=$3
    FALLBACK_IMAGE_NAME=$4

    mkdir -p "$DEST_DIR"

    # Copy regular images with fallback
    cp "$SOURCE_DIR/${IMAGE_NAME}.png" "$DEST_DIR/${IMAGE_NAME}.png" 2>/dev/null || cp "$SOURCE_DIR/${FALLBACK_IMAGE_NAME}.png" "$DEST_DIR/${IMAGE_NAME}.png" 2>/dev/null
    cp "$SOURCE_DIR/${IMAGE_NAME}@2x.png" "$DEST_DIR/${IMAGE_NAME}@2x.png" 2>/dev/null || cp "$SOURCE_DIR/${FALLBACK_IMAGE_NAME}@2x.png" "$DEST_DIR/${IMAGE_NAME}@2x.png" 2>/dev/null
    cp "$SOURCE_DIR/${IMAGE_NAME}@3x.png" "$DEST_DIR/${IMAGE_NAME}@3x.png" 2>/dev/null || cp "$SOURCE_DIR/${FALLBACK_IMAGE_NAME}@3x.png" "$DEST_DIR/${IMAGE_NAME}@3x.png" 2>/dev/null

    # Copy dark mode images with fallback
    cp "$SOURCE_DIR/${IMAGE_NAME}_dark.png" "$DEST_DIR/${IMAGE_NAME}_dark.png" 2>/dev/null || cp "$SOURCE_DIR/${FALLBACK_IMAGE_NAME}_dark.png" "$DEST_DIR/${IMAGE_NAME}_dark.png" 2>/dev/null
    cp "$SOURCE_DIR/${IMAGE_NAME}_dark@2x.png" "$DEST_DIR/${IMAGE_NAME}_dark@2x.png" 2>/dev/null || cp "$SOURCE_DIR/${FALLBACK_IMAGE_NAME}_dark@2x.png" "$DEST_DIR/${IMAGE_NAME}_dark@2x.png" 2>/dev/null
    cp "$SOURCE_DIR/${IMAGE_NAME}_dark@3x.png" "$DEST_DIR/${IMAGE_NAME}_dark@3x.png" 2>/dev/null || cp "$SOURCE_DIR/${FALLBACK_IMAGE_NAME}_dark@3x.png" "$DEST_DIR/${IMAGE_NAME}_dark@3x.png" 2>/dev/null
}

# Process each token in TemporaryAssets/General
function process_tokens {
    echo "Processing tokens in $TEMP_ASSETS_PATH..."

    for TOKEN_DIR in "$TEMP_ASSETS_PATH"/*; do
        if [ -d "$TOKEN_DIR" ]; then
            TOKEN_NAME=$(basename "$TOKEN_DIR")
            IMAGES_DIR="$TOKEN_DIR/images"

            echo "Processing token: $TOKEN_NAME"
            echo "IMAGES_DIR: $IMAGES_DIR"

            # Skip if no images directory exists
            if [ ! -d "$IMAGES_DIR" ]; then
                echo "Skipping $TOKEN_NAME: no images directory found."
                continue
            fi

            # Function to process an image set
            function process_image_set {
                TYPE=$1
                FALLBACK_TYPE=$2
                TARGET_PATH="$WALLETS_ASSETS_PATH/${TOKEN_NAME}_${TYPE}.imageset"
                IMAGE_BASE_NAME="${TOKEN_NAME}_${TYPE}"

                mkdir -p "$TARGET_PATH"
                echo "Creating $TYPE imageset: $TARGET_PATH"

                # Copy images, using wallet images as fallback
                copy_images_with_fallback "$IMAGES_DIR" "$IMAGE_BASE_NAME" "$TARGET_PATH" "${TOKEN_NAME}_${FALLBACK_TYPE}"

                # Check for dark mode images
                WITH_DARK=false
                if [ -e "$TARGET_PATH/${IMAGE_BASE_NAME}_dark.png" ]; then
                    WITH_DARK=true
                fi

                # Generate Contents.json
                create_contents "$TARGET_PATH" "$IMAGE_BASE_NAME" "$WITH_DARK"
            }

            # Process wallet, wallet_row (fallback to wallet), and notification (fallback to wallet)
            process_image_set "wallet" "wallet"
            process_image_set "wallet_row" "wallet"
            process_image_set "notification" "wallet"

            # Copy notification content image (only @3x)
            if [ -e "$IMAGES_DIR/${TOKEN_NAME}_wallet@3x.png" ]; then
                echo "Copying notification content image for $TOKEN_NAME"
                cp "$IMAGES_DIR/${TOKEN_NAME}_wallet@3x.png" "$NOTIFICATION_IMAGES_PATH/${TOKEN_NAME}_notificationContent.png"
            fi
        else
            echo "Skipping $TOKEN_DIR: Not a directory"
        fi
    done
}

# Main script execution
process_tokens
echo "Asset generation completed!"

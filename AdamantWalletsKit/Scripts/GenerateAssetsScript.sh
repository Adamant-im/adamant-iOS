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

# Remove old WalletImages folder
if [ -d "$NOTIFICATION_IMAGES_PATH" ]; then
    echo "Removing old WalletImages folder..."
    rm -rf "$NOTIFICATION_IMAGES_PATH"
fi
mkdir -p "$NOTIFICATION_IMAGES_PATH"
echo "Created new WalletImages folder."

# Remove old Wallets.xcassets folder
if [ -d "$WALLETS_ASSETS_PATH" ]; then
    echo "Removing old Wallets.xcassets..."
    rm -rf "$WALLETS_ASSETS_PATH"
fi
mkdir -p "$WALLETS_ASSETS_PATH"
echo "Created new Wallets.xcassets folder."

# Function to create Contents.json
function create_contents {
    TARGET=$1
    IMAGE_NAME=$2
    WITH_DARK=$3

    echo "Generating Contents.json for $TARGET..."

    if [ "$WITH_DARK" = true ]; then
        cat > ${TARGET}/Contents.json << __EOF__
{
  "images" : [
    {
      "filename" : "${IMAGE_NAME}.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "filename" : "${IMAGE_NAME}_dark.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "filename" : "${IMAGE_NAME}@2x.png",
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "filename" : "${IMAGE_NAME}_dark@2x.png",
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "filename" : "${IMAGE_NAME}@3x.png",
      "idiom" : "universal",
      "scale" : "3x"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "filename" : "${IMAGE_NAME}_dark@3x.png",
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
__EOF__
    else
        cat > ${TARGET}/Contents.json << __EOF__
{
  "images" : [
    {
      "idiom" : "universal",
      "scale" : "1x",
      "filename" : "${IMAGE_NAME}.png"
    },
    {
      "idiom" : "universal",
      "scale" : "2x",
      "filename" : "${IMAGE_NAME}@2x.png"
    },
    {
      "idiom" : "universal",
      "scale" : "3x",
      "filename" : "${IMAGE_NAME}@3x.png"
    }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
__EOF__
    fi
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

            # Wallet images
            TARGET_WALLET_IMAGESET="$WALLETS_ASSETS_PATH/${TOKEN_NAME}_wallet.imageset"
            mkdir -p "$TARGET_WALLET_IMAGESET"
            echo "Creating wallet imageset: $TARGET_WALLET_IMAGESET"

            cp "$IMAGES_DIR/${TOKEN_NAME}_wallet.png" "$TARGET_WALLET_IMAGESET/${TOKEN_NAME}_wallet.png" 2>/dev/null
            cp "$IMAGES_DIR/${TOKEN_NAME}_wallet@2x.png" "$TARGET_WALLET_IMAGESET/${TOKEN_NAME}_wallet@2x.png" 2>/dev/null
            cp "$IMAGES_DIR/${TOKEN_NAME}_wallet@3x.png" "$TARGET_WALLET_IMAGESET/${TOKEN_NAME}_wallet@3x.png" 2>/dev/null

            # Check for dark mode images
            WITH_DARK=false
            if [ -e "$IMAGES_DIR/${TOKEN_NAME}_wallet_dark.png" ]; then
                echo "Dark mode images found for $TOKEN_NAME"
                cp "$IMAGES_DIR/${TOKEN_NAME}_wallet_dark.png" "$TARGET_WALLET_IMAGESET/${TOKEN_NAME}_wallet_dark.png"
                cp "$IMAGES_DIR/${TOKEN_NAME}_wallet_dark@2x.png" "$TARGET_WALLET_IMAGESET/${TOKEN_NAME}_wallet_dark@2x.png" 2>/dev/null
                cp "$IMAGES_DIR/${TOKEN_NAME}_wallet_dark@3x.png" "$TARGET_WALLET_IMAGESET/${TOKEN_NAME}_wallet_dark@3x.png" 2>/dev/null
                WITH_DARK=true
            fi

            # Generate Contents.json for wallet
            create_contents "$TARGET_WALLET_IMAGESET" "${TOKEN_NAME}_wallet" "$WITH_DARK"

            # Copy notification content images
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

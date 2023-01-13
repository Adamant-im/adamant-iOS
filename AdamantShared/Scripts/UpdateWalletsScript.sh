ROOT="$PWD"
BRANCH_NAME="dev" #master
SCRIPTS_DIR="$ROOT/scripts"
WALLETS_DIR="$ROOT/scripts/wallets"
WALLETS_NAME_DIR="$ROOT/scripts/wallets/adamant-wallets-$BRANCH_NAME/assets/general"
WALLETS_TOKENS_DIR="$ROOT/scripts/wallets/adamant-wallets-$BRANCH_NAME/assets/blockchains"

# Download
function download ()
{
    mkdir -p "$WALLETS_DIR"
    cd "$WALLETS_DIR"
    curl -fSsOL https://github.com/Adamant-im/adamant-wallets/archive/refs/heads/$BRANCH_NAME.zip
    tar xzf $BRANCH_NAME.zip
}

# create Contents for the image
function create_contents
{
    Target=$1
    IMAGE_NAME=$2
    With_Dark=$3
    
    if [ $With_Dark = true ]
    then
        cat > ${Target}/Contents.json << __EOF__
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
        cat > ${Target}/Contents.json << __EOF__
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

# Move image to asset
function moveImage ()
{
    FROM_DIR=$1
    WALLET_NAME=$2
    Target=$3
    IMAGE_NAME_FROM=$4
    IMAGE_NAME_TO=$5
    
    cp $FROM_DIR/$WALLET_NAME/Images/${IMAGE_NAME_FROM}.png ${Target}/${IMAGE_NAME_TO}.png
    cp $FROM_DIR/$WALLET_NAME/Images/${IMAGE_NAME_FROM}@2x.png ${Target}/${IMAGE_NAME_TO}@2x.png
    cp $FROM_DIR/$WALLET_NAME/Images/${IMAGE_NAME_FROM}@3x.png ${Target}/${IMAGE_NAME_TO}@3x.png
    
    # check dark icons
    if [ -e $FROM_DIR/$WALLET_NAME/Images/${IMAGE_NAME_FROM}_dark.png ]
    then
        cp $FROM_DIR/$WALLET_NAME/Images/${IMAGE_NAME_FROM}_dark.png ${Target}/${IMAGE_NAME_TO}_dark.png
        cp $FROM_DIR/$WALLET_NAME/Images/${IMAGE_NAME_FROM}_dark@2x.png ${Target}/${IMAGE_NAME_TO}_dark@2x.png
        cp $FROM_DIR/$WALLET_NAME/Images/${IMAGE_NAME_FROM}_dark@3x.png ${Target}/${IMAGE_NAME_TO}_dark@3x.png
        create_contents ${Target} ${IMAGE_NAME_TO} true
    else
        create_contents ${Target} ${IMAGE_NAME_TO} false
    fi
}

# unpack
function unpack ()
{
    cd "$WALLETS_NAME_DIR"
    for dir in $WALLETS_NAME_DIR/*/; do
        WALLET_NAME=$(basename $dir)
        
        # if exist {name}
        if [ -e $WALLETS_NAME_DIR/$WALLET_NAME/Images/${WALLET_NAME}_wallet.png ]
        then
            # copy @3x image to Notification Service Extension
            Target_Notification_Content=$ROOT/NotificationServiceExtension/WalletImages
            cp $WALLETS_NAME_DIR/$WALLET_NAME/Images/${WALLET_NAME}_wallet@3x.png ${Target_Notification_Content}/${WALLET_NAME}_notificationContent.png
        
            # move wallet images to assets
            Target_Wallet_Image=$ROOT/AdamantShared/Shared.xcassets/Wallets/${WALLET_NAME}_wallet.imageset
            mkdir -p ${Target_Wallet_Image}
            moveImage $WALLETS_NAME_DIR $WALLET_NAME ${Target_Wallet_Image} ${WALLET_NAME}_wallet ${WALLET_NAME}_wallet
        fi
        
        # move notification images to assets
        if [ -e $WALLETS_NAME_DIR/$WALLET_NAME/Images/${WALLET_NAME}_wallet.png ]
        then
            Target_Notification_Image=$ROOT/AdamantShared/Shared.xcassets/Wallets/${WALLET_NAME}_notification.imageset
            mkdir -p ${Target_Notification_Image}
            if [ -e $WALLETS_NAME_DIR/$WALLET_NAME/Images/${WALLET_NAME}_notification.png ]
            then
                moveImage $WALLETS_NAME_DIR $WALLET_NAME ${Target_Notification_Image} ${WALLET_NAME}_notification ${WALLET_NAME}_notification
            else
                moveImage $WALLETS_NAME_DIR $WALLET_NAME ${Target_Notification_Image} ${WALLET_NAME}_wallet ${WALLET_NAME}_notification
            fi
        fi
        
        # move row images to assets
        if [ -e $WALLETS_NAME_DIR/$WALLET_NAME/Images/${WALLET_NAME}_wallet.png ]
        then
            Target_Row_Image=$ROOT/AdamantShared/Shared.xcassets/Wallets/${WALLET_NAME}_wallet_row.imageset
            mkdir -p ${Target_Row_Image}
            if [ -e $WALLETS_NAME_DIR/$WALLET_NAME/Images/${WALLET_NAME}_wallet_row.png ]
            then
                moveImage $WALLETS_NAME_DIR $WALLET_NAME ${Target_Row_Image} ${WALLET_NAME}_wallet_row ${WALLET_NAME}_wallet_row
            else
                moveImage $WALLETS_NAME_DIR $WALLET_NAME ${Target_Row_Image} ${WALLET_NAME}_wallet ${WALLET_NAME}_wallet_row
            fi
        fi
    done
}

# update swift files
function updateSwiftFiles ()
{
    BLOCKCHAIN_NAME=$1
    WALLET_NAME=$2
    WALLET_SYMBOL=$3
    WALLET_CONTRACT=$4
    WALLET_DECIMALS=$5
    DEFAULT_VISABILITY_RAW=$6
    DEFAULT_ORDINAL_LEVEL_RAW=$7
    
    DEFAULT_VISABILITY="${DEFAULT_VISABILITY_RAW:=false}"
    DEFAULT_ORDINAL_LEVEL="${DEFAULT_ORDINAL_LEVEL_RAW:=nil}"
    echo "DEFAULT_VISABILITY"
    echo $DEFAULT_VISABILITY
    echo "DEFAULT_ORDINAL_LEVEL"
    echo $DEFAULT_ORDINAL_LEVEL
    
# to-do defaultVisibility & defaultOrdinalLevel from general info
    TARGET=$ROOT/AdamantShared/Models
     cat >> ${TARGET}/${BLOCKCHAIN_NAME}TokensList.swift << __EOF__
        ERC20Token(symbol: "$WALLET_SYMBOL",
                   name: "$WALLET_NAME",
                   contractAddress: "$WALLET_CONTRACT",
                   decimals: $WALLET_DECIMALS,
                   naturalUnits: $WALLET_DECIMALS,
                   defaultVisibility: $DEFAULT_VISABILITY,
                   defaultOrdinalLevel: $DEFAULT_ORDINAL_LEVEL),
__EOF__
}

# set tokens
function setTokens ()
{
    cd "$WALLETS_TOKENS_DIR"
    for dir in $WALLETS_TOKENS_DIR/*/; do
        BLOCKCHAIN_NAME=$(basename $dir)
        TARGET=$ROOT/AdamantShared/Models
        BLOCKCHAIN_JSON=$WALLETS_TOKENS_DIR/$BLOCKCHAIN_NAME/info.json
        BLOCKCHAIN_TYPE=$(perl -ne 'if (/"type": "(.*)"/) { print $1 . "\n" }' $BLOCKCHAIN_JSON)
        
        cat > ${TARGET}/${BLOCKCHAIN_NAME}TokensList.swift << __EOF__
import Foundation

extension ${BLOCKCHAIN_TYPE}Token {
    static let supportedTokens: [ERC20Token] = [

__EOF__

        for dir in $WALLETS_TOKENS_DIR/$BLOCKCHAIN_NAME/*/; do
                WALLET_NAME=$(basename $dir)
                WALLET_JSON=$WALLETS_TOKENS_DIR/$BLOCKCHAIN_NAME/$WALLET_NAME/info.json
                NAME=$(perl -ne 'if (/"name": "(.*)"/) { print $1 . "\n" }' $WALLET_JSON)
                SYMBOL=$(perl -ne 'if (/"symbol": "(.*)"/) { print $1 . "\n" }' $WALLET_JSON)
                CONTRACT=$(perl -ne 'if (/"contractId": "(.*)"/) { print $1 . "\n" }' $WALLET_JSON)
                DECIMALS=$(perl -ne 'if (/"decimals": (.*)/) { print $1 . "\n" }' $WALLET_JSON)

                WALLET_GENERAL_JSON=$WALLETS_NAME_DIR/general/$WALLET_NAME/info.json
                DEFAULT_VISABILITY=$(perl -ne 'if (/"defaultVisibility": "(.*)"/) { print $1 . "\n" }' $WALLET_GENERAL_JSON)
                DEFAULT_ORDINAL_LEVEL=$(perl -ne 'if (/"defaultOrdinalLevel": "(.*)"/) { print $1 . "\n" }' $WALLET_GENERAL_JSON)
                updateSwiftFiles "$BLOCKCHAIN_NAME" "$NAME" "$SYMBOL" "$CONTRACT" "$DECIMALS"  "$DEFAULT_VISABILITY" "$DEFAULT_ORDINAL_LEVEL"
         done

        cat >> ${TARGET}/${BLOCKCHAIN_NAME}TokensList.swift << __EOF__
    ]
    
}
__EOF__

    done
}

# unpack data for coins
function unpackCoins ()
{
    ./$ROOT/AdamantShared/Scripts/CoinsScript.rb xcode
}

# remove temp directory
function remove_script_directory ()
{
    rm -r $SCRIPTS_DIR
}

download

unpack

setTokens

# unpackCoins

# remove_script_directory

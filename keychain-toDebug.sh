PASSFILE="./appstorepass.txt"
SOURCE="./Adamant/Services/KeychainStore.swift"
DEBUGPASS="debug"

if [ ! -f $PASSFILE ]; then
	echo "$0:5: error: No file with passphrase"
	exit 1
fi

if [ ! -f $SOURCE ]; then
	echo "$0:10: error: No file to replace password"
	exit 1
fi

passToLook=$(<appstorepass.txt)

sed -i '' "s/${passToLook}/${DEBUGPASS}/" $SOURCE
exit 0

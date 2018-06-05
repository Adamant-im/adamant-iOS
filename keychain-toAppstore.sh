PASSFILE="./appstorepass.txt"
SOURCE="./Adamant/Services/KeychainStore.swift"
DEBUGPASS="debug"

if [ ! -f $PASSFILE ]; then
	echo "$0:6: error: No file with passphrase"
	exit 1
fi

if [ ! -f $SOURCE ]; then
	echo "$0:11: error: No file to replace password"
	exit 1
fi

appstorepass=$(<appstorepass.txt)

sed -i '' "s/${DEBUGPASS}/${appstorepass}/" $SOURCE
exit 0

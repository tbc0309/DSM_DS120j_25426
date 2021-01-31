#!/bin/sh

PACKAGE_WHITE_LIST="$1"
SZD_TMP="$2"


if [ -z "$PACKAGE_WHITE_LIST" -o -z "$SZD_TMP" ]; then
	exit 1
fi
if [ ! -e "$PACKAGE_WHITE_LIST" ]; then
	exit 1
fi

# collect whitelist for packages
cat "$PACKAGE_WHITE_LIST" | while read LINE
do
	if [ -z "$LINE" ]; then
		continue;
	fi
	DEST_DIR="$SZD_TMP"`/usr/bin/dirname "$LINE"`
	mkdir -p "$DEST_DIR"
	cp -rsx "$LINE" "$DEST_DIR"
done

exit 0

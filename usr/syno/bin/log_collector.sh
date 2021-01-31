#!/bin/sh

exec > /dev/null

# collect File White list
COLLECT_WHITE_LISTS="/usr/syno/etc/logcollector/whitelist/*"
# collector
COLLECTOR_LIST="/usr/syno/bin/logcollector/*"

# other file for debug

if [ -z "$1" ]; then
	SZD_TMP="/tmp/@`date +%s`.$$"
else
	SZD_TMP="$1"
fi


# call other collector
for COLLECTOR in $COLLECTOR_LIST; do
	if [ -x "$COLLECTOR" ]; then
		"$COLLECTOR" "$SZD_TMP"
	fi
done

# white list
for WHITE_LIST in $COLLECT_WHITE_LISTS; do
	cat "$WHITE_LIST" | while read LINE
	do
		if [ -z "$LINE" ]; then
			continue;
		fi
		DEST_DIR="$SZD_TMP"`/usr/bin/dirname "$LINE"`
		mkdir -p "$DEST_DIR"
		cp -rsx "$LINE" "$DEST_DIR"
	done
done

exit 0

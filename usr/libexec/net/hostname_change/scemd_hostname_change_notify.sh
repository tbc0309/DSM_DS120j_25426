#!/bin/sh

SZF_SCEMD_LOCK="/tmp/syno_scemd.lock"

post_up () {
	flock -n -x $SZF_SCEMD_LOCK /usr/syno/bin/syno_scemd_connector --hostname_change
}

case $1 in
    --sdk-mod-ver)
	#Print SDK support version
	echo "1.0";
    ;;
    --name)
	#Print package name
	echo "scemd"
    ;;
    --pkg-ver)
	#Print package version
	echo "1.0";
    ;;
    --vendor)
	#Print package vendor
	echo "Synology";
    ;;
    --pre)
	#Actions before net service action
    ;;
    --post)
	#Actions after net service action
		post_up &
    ;;
    *)
	echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
    ;;
esac


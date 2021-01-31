#!/bin/sh

SZF_SCEMD_LOCK="/tmp/syno_scemd.lock"
SZF_SCEMD_READY="/tmp/.scemd_ready"

post_up () {
	if [ -f $SZF_SCEMD_READY ]; then
		flock -n -x $SZF_SCEMD_LOCK /usr/syno/bin/syno_scemd_connector --net_change
	fi
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
	--post)
	post_up &
	;;
	*)
	echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac


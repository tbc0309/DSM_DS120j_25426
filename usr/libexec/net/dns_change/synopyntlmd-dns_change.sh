#!/bin/sh
# Copyright (c) 2000-2019 Synology Inc. All rights reserved.

case "$1" in
	--sdk-mod-ver)
		echo "1.0";
		;;
	--name)
		echo "synopyntlmd";
		;;
	--pkg-ver)
		echo "1.0";
		;;
	--vendor)
		echo "Synology";
		;;
	--pre)
		/usr/syno/sbin/synoservice --disable synopyntlmd
		;;
	--post)
		if [ "xyes" == "x$(synogetkeyvalue  /etc/synoinfo.conf enable_http_negotiate)" ]; then
			/usr/syno/sbin/synoservice --enable synopyntlmd
		fi
		;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
		;;
esac
exit 0

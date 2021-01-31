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
		;;
	--post)
		/usr/syno/sbin/synoservice --disable synopyntlmd
		/usr/syno/bin/synosetkeyvalue /etc/synoinfo.conf enable_http_negotiate no
		;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
		;;
esac
exit 0

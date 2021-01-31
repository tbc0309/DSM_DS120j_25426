#!/bin/sh
# Copyright (c) 2000-2015 Synology Inc. All rights reserved.

case "$1" in
	--sdk-mod-ver)
	#Print SDK support version
	echo "1.0"
	;;
	--name)
	#Print package name
	echo "Synoindex"
	;;
	--pkg-ver)
	#Print package version
	echo "1.0"
	;;
	--vendor)
	#Print package vendor
	echo "Synology Inc."
	;;
	--pre)
	#Actions before share set
	;;
	--post)
		/usr/syno/sbin/synoservice --restart synoindexd
		/usr/syno/sbin/synoservice --restart synomkthumbd
		/usr/syno/sbin/synoservice --restart synomkflvd
		;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
		;;
esac
exit 0

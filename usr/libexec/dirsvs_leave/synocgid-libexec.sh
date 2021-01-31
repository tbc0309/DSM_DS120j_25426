#!/bin/sh
# Copyright (c) 2000-2015 Synology Inc. All rights reserved.

case "$1" in
	--sdk-mod-ver)
		echo "1.0";
		;;
	--name)
		echo "synocgid";
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
		/sbin/initctl restart synocgid
		;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
		;;
esac
exit 0

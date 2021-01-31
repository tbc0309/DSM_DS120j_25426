#!/bin/sh
# Copyright (c) 2018 Synology Inc. All rights reserved.


case "$1" in
	--sdk-mod-ver)
		echo "1.0";
		;;
	--name)
		echo "synoconfd";
		;;
	--pkg-ver)
		echo "1.0";
		;;
	--vendor)
		echo "Synology Inc.";
		;;
	--pre)
		;;
	--post)
		[ "$RESULT" = "0" ] && /usr/syno/bin/expired-user-check
		;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
		;;
esac
exit 0

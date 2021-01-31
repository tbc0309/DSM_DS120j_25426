#!/bin/bash
# Copyright (c) 2000-2015 Synology Inc. All rights reserved.


case "$1" in
	--sdk-mod-ver)
		echo "1.0"
		;;
	--name)
		echo "unmount all volume hook"
		;;
	--pkg-ver)
		echo "1.0"
		;;
	--vendor)
		echo "Synology Inc."
		;;
	--pre)
		/usr/syno/bin/synocheckshare --all-vol-unmounting
		/usr/syno/sbin/synosharesnaptool misc vol-unmount-all
		;;
	--post)
		# Nothing to be done.
		;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
		;;
esac
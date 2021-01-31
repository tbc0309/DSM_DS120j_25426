#!/bin/sh
BIN=/usr/syno/bin/synosmartblock
case "$1" in
	--sdk-mod-ver)
		echo 1.0;
	;;
	--name)
		echo smartblock
	;;
	--vendor)
		echo "Synology Inc."
	;;
	--pre)
		true
	;;
	--post)
		"$BIN" strip_users
	;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac

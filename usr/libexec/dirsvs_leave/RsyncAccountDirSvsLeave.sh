#!/bin/sh

BIN=/usr/syno/bin/synorsyncdtool

case $1 in
	--sdk-mod-ver)
		echo "1.0"
	;;
	--name)
		echo "Rsync"
	;;
	--pkg-ver)
		echo "1.0"
	;;
	--vendor)
		echo "Synology Inc."
	;;
	--pre)
		true
	;;
	--post)
		$BIN --dirsvs_leave
	;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac


#!/bin/sh

case $1 in
	--sdk-mod-ver)
		echo "1.0"
	;;
	--name)
		echo "smbd"
	;;
	--pkg-ver)
		smbd -V | head -n1 | cut -d' ' -f2
	;;
	--vendor)
		echo "Synology Inc."
	;;
	--pre)
		true
	;;
	--post)
		synoservice --reload samba &
	;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac


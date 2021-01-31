#!/bin/sh

# Usable environment variable:
#       LOCATION, DEVICE, MOUNTPOINT, and RESULT

case $1 in
	--sdk-mod-ver)
		echo "1.0"
	;;
	--name)
		echo "TCM (linux lio, target core mod) volume umount hook"
	;;
	--pkg-ver)
		echo "1.0"
	;;
	--vendor)
		echo "Synology Inc."
	;;
	--pre)
		/usr/syno/bin/synoiscsihook --volume_umount ${MOUNTPOINT}
	;;
	--post)
	;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac


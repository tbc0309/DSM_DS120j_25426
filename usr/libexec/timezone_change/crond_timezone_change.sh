#!/bin/sh

case $1 in
	--sdk-mod-ver)
		echo "1.0"
	;;
	--name)
		echo "crond timezone change plugin"
	;;
	--pkg-ver)
		echo "1.x"
	;;
	--vendor)
		echo "Synology Inc."
	;;
	--post)
		if /usr/syno/bin/synobootseq --is-booting-up > /dev/null 2>&1 ; then
			exit
		fi
		/usr/syno/sbin/synoservice --reload crond
	;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--post"
	;;
esac

#!/bin/sh

################################################
# winbindd hook for volume unmount
# Usable environment variable:
#	LOCATION, DEVICE, MOUNTPOINT, and RESULT
###############################################

case $1 in
	--sdk-mod-ver)
		echo "1.0"
		;;
	--name)
		echo "winbindd volume unmount hook"
		;;
	--pkg-ver)
		echo "1.0"
		;;
	--vendor)
		echo "Synology Inc."
		;;
	--pre)
		## do nothing when ds is shutdown
		if /usr/syno/bin/synobootseq --is-shutdown > /dev/null 2>&1 ; then
			exit 0
		fi

		DIR=/var/lib/samba/winbindd_cache.tdb
		VOL_PATH=`dirname \`realpath $DIR\``

		## restart winbindd if the cache path will be unmount
		if [ "x${MOUNTPOINT}" = "x${VOL_PATH}" ]; then
			synoservice --restart winbindd
		fi
		;;
	--post)
		;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac

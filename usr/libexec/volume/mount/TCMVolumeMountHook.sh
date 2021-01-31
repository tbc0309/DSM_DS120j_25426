#!/bin/sh

case $1 in
	--sdk-mod-ver)
		echo "1.0"
	;;
	--name)
		echo "TCM (linux lio, target core mod) volume mount hook"
	;;
	--pkg-ver)
		echo "1.0"
	;;
	--vendor)
		echo "Synology Inc."
	;;
	--pre)
	;;
	--post)
		/usr/syno/bin/synoiscsihook --volume_mount ${MOUNTPOINT}
		# do nothing when mounting at booting-up stage
		if /usr/syno/bin/synobootseq --is-booting-up > /dev/null 2>&1 ; then
			if [ -z "`status iscsitrg-adapter | grep running`" ]; then
				exit
			fi
		fi
		# do nothing when mounting at shutdown stage
		if /usr/syno/bin/synobootseq --is-shutdown > /dev/null 2>&1 ; then
			exit
		fi

		/usr/syno/bin/synoiscsiep --startall iscsi
	;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac


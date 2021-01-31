#!/bin/sh

SYNOSDUTILS="/usr/syno/bin/synosdutils"
SYNOSERVICE="/usr/syno/sbin/synoservice"
SYNOSDUTILS_NAME="synosdutils"
SYNOSDUTILS_VERSION="1.0"
SYNOSUTILS_VENDOR="Synology Inc."
SDK_MODVER="2.0"

case $1 in
	--sdk-mod-ver)
		#Print SDK support version
		echo ${SDK_MODVER}
	;;
	--name)
		#Print synosdutils name
		echo ${SYNOSDUTILS_NAME}
	;;
	--pkg-ver)
		#Print synosdutils version
		echo ${SYNOSDUTILS_VERSION}
	;;
	--vendor)
		#Print synosdutils vendor
		echo ${SYNOSDUTILS_VENDOR}
	;;
	--pre)
		echo "synosdutils share set pre hook!"
	;;
	--post)
		# do nothing when booting-up
		if /usr/syno/bin/synobootseq --is-booting-up > /dev/null 2>&1 ; then
			exit
		fi
		# do nothing when when shutdown
		if /usr/syno/bin/synobootseq --is-shutdown > /dev/null 2>&1 ; then
			exit
		fi
		# Check share in Time Machine share list
		RES="`${SYNOSDUTILS} time-machine --share-status | /bin/grep ${ORIGIN_SHARE_NAME}`"
		if [ -n "$RES" ]; then
			# Remove origin share
			${SYNOSDUTILS} time-machine --rm-share ${ORIGIN_SHARE_NAME}
			# Append new share name to Time Machine share list
			${SYNOSDUTILS} time-machine --add-share ${SHARE_NAME}
		fi
		# Restart avahi
		${SYNOSERVICE} --restart avahi
	;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac

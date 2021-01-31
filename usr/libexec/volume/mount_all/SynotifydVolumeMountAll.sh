#!/bin/sh

SYNOTIFYD_TOOL_BINARY=/usr/syno/bin/synotifydutil

SYNOTIFYD_PKG_NAME="synotifyd"
SYNOTIFYD_PKG_VERSION="1.0"
SYNOTIFYD_PKG_VENDOR="Synology Inc."
SDK_MODVER="1.0"

case $1 in
	--sdk-mod-ver)
		#Print SDK support version
		echo ${SDK_MODVER}
	;;
	--name)
		#Print package name
		echo ${SYNOTIFYD_PKG_NAME}
	;;
	--pkg-ver)
		#Print package version
		echo ${SYNOTIFYD_PKG_VERSION}
	;;
	--vendor)
		#Print package vendor
		echo ${SYNOTIFYD_PKG_VENDOR}
	;;
	--pre)
		#Actions before volume mount_all
	;;
	--post)
		#Actions after volume mount_all
		if [ "0" != "${RESULT}" ]; then
			exit 0
		fi
		for INDEX in $(seq 1 1 $VOLUME_NUMBER); do
			eval "MOUNTPOINT=\$MOUNTPOINT_$INDEX"
			${SYNOTIFYD_TOOL_BINARY} -a mount_volume -m "${MOUNTPOINT}"
		done
	;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac

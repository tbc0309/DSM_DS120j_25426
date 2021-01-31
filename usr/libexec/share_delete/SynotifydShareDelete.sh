#!/bin/sh

SYNOTIFYD_TOOL_BINARY=/usr/syno/bin/synotifydutil

SYNOTIFYD_PKG_NAME="synotifyd"
SYNOTIFYD_PKG_VERSION="1.0"
SYNOTIFYD_PKG_VENDOR="Synology Inc."
SDK_MODVER="2.0"

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
		#Actions before share delete
		for INDEX in $(seq 1 1 $NTIMES); do
			eval "SYNOTIFYD_SHARE_NAME=\$SHARE_NAME_$INDEX"
			${SYNOTIFYD_TOOL_BINARY} -a umount_share -n "${SYNOTIFYD_SHARE_NAME}"
		done
	;;
	--post)
		#Actions after share delete
		for INDEX in $(seq 1 1 $NTIMES); do
			eval "SHARE_OP_RESULT=\$SHARE_OP_RESULT_$INDEX"
			eval "SYNOTIFYD_SHARE_NAME=\$SHARE_NAME_$INDEX"
			if [ "0x0000" != "${SHARE_OP_RESULT}" ]; then
				${SYNOTIFYD_TOOL_BINARY} -a mount_share -n "${SYNOTIFYD_SHARE_NAME}"
			fi
		done
	;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac

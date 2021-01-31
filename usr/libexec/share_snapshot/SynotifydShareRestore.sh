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
		#Actions before share restore
		if [ "RESTORE" = "${ACTION}" ]; then
			${SYNOTIFYD_TOOL_BINARY} -a umount_share -n "${SHARE_NAME}"
		fi
	;;
	--post)
		#Actions after share restore
		case $ACTION in
			CREATE)
			;;
			RESTORE)
				${SYNOTIFYD_TOOL_BINARY} -a mount_share -n "${SHARE_NAME}"
			;;
			CLONE_SHARE)
				if [ "0" = "${RESULT}" ]; then
					${SYNOTIFYD_TOOL_BINARY} -a mount_share -n "${NEW_SHARE_NAME}"
				fi
			;;
			CLONE_SNAP)
			;;
			*)
			;;
		esac
	;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac

#!/bin/sh

SYNOTIFYD_TOOL_BINARY=/usr/syno/bin/synotifydutil

SYNOTIFYD_PKG_NAME="synotifyd"
SYNOTIFYD_PKG_VERSION="1.0"
SYNOTIFYD_PKG_VENDOR="Synology Inc."
SDK_MODVER="2.0"

# 0: move, 1: create, -1: do nothing
CheckShareAction() {
	if [ "" = "${ORIGIN_SHARE_NAME}" ]; then
		return 1
	fi

	# share name changed or share path changed
	if [ "${ORIGIN_SHARE_NAME}" != "${SHARE_NAME}" ] ||
	   [ "${ORIGIN_SHARE_PATH}" != "${SHARE_PATH}" ]; then
		return 0
	fi

	return -1
}

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
		#Actions before share set
		CheckShareAction
		RET=$?
		if [ "0" = "${RET}" ]; then
			${SYNOTIFYD_TOOL_BINARY} -a umount_share -n "${ORIGIN_SHARE_NAME}"
		fi;
	;;
	--post)
		#Actions after share set
		CheckShareAction
		RET=$?
		if [ "-1" = "${RET}" ]; then
			exit 0
		fi

		if [ "0" != "${RESULT}" ]; then
			if [ "0" = "${RET}" ]; then
				${SYNOTIFYD_TOOL_BINARY} -a mount_share -n "${ORIGIN_SHARE_NAME}"
			fi
			exit 0
		fi

		${SYNOTIFYD_TOOL_BINARY} -a mount_share -n "${SHARE_NAME}"
	;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac

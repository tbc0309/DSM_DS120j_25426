#!/bin/sh

###############################################################
#   This script should be hooked when invoking SYNOShareDelete()
#   Usable environment variable:
#       NITEMS, SHARE_NAME_X, SHARE_PATH_X, SHARE_OP_RESULT_X
#
###############################################################

#At begining, acquire package settings
RETENTION_BINARY=/usr/syno/bin/synoretentionconf

RETENTION_PKG_NAME="SynoRetention"
RETENTION_PKG_VERSION="1.0"
RETENTION_PKG_VENDOR="Synology Inc."
RETENTION_PKG_MODVER="2.0"
RETENTION_SHARE_PREFIX="Share#"

case $1 in
	--sdk-mod-ver)
		echo ${RETENTION_PKG_MODVER}
	;;
	--name)
		echo ${RETENTION_PKG_NAME}
	;;
	--pkg-ver)
		echo ${RETENTION_PKG_VERSION}
	;;
	--vendor)
		echo ${RETENTION_PKG_VENDOR}
	;;
	--pre)
	;;
	--post)
		if [ -f "${RETENTION_BINARY}" ]; then
			INDEX=1
			NITEMS=$((NITEMS + 1))
			while [ "${INDEX}" != "${NITEMS}" ]
			do
				eval "SHARE_OP_RESULT=\$SHARE_OP_RESULT_$INDEX"
				eval "SHARE_NAME=\$SHARE_NAME_$INDEX"
				if [ "0x0000" = "${SHARE_OP_RESULT}" ]; then
					${RETENTION_BINARY} --remove "${RETENTION_SHARE_PREFIX}" "${SHARE_NAME}"
				fi
				INDEX=$((INDEX + 1))
			done
		fi
	;;
	*)
                echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac

#!/bin/sh

###############################################################
#   This script should be hooked when invoking SYNOShareSet()
#   Usable environment variable:
#       ORIGIN_SHARE_NAME, ORIGIN_SHARE_STATUS, ORIGIN_SHARE_PATH, SHARE_NAME, SHARE_STATUS, SHARE_PATH
#   Note: The script should bear to be invoked multiple times
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
		#Print SDK support version. Right now, Share module is 2.0
		echo ${RETENTION_PKG_MODVER}
	;;
	--name)
		#Print name
		echo ${RETENTION_PKG_NAME}
	;;
	--pkg-ver)
		echo ${RETENTION_PKG_VERSION}
	;;
	--vendor)
		#Print package vendor
		echo ${RETENTION_PKG_VENDOR}
	;;
	--pre)
		#Actions before share set
	;;
	--post)
		#Actions after share set
		if [ -f "${RETENTION_BINARY}" ]; then
			if [ -n "${ORIGIN_SHARE_NAME}" ] && [ "${ORIGIN_SHARE_NAME}" != "${SHARE_NAME}" ] && [ "0" = "${RESULT}" ]; then
				${RETENTION_BINARY} --rename "${RETENTION_SHARE_PREFIX}" "${ORIGIN_SHARE_NAME}" "${SHARE_NAME}"
			fi
		fi
	;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac

#!/bin/sh

###############################################################
#   Usable environment variable:
#       LUN_UUID, LUN_NEW_NAME, LUN_OLD_NAME, LUN_ROOT_PATH, LUN_ID, LUN_TYPE, IS_THIN_LUN, IS_ADV_LUN, IS_BKP_LUN, ERROR_CODE,
###############################################################

#At begining, acquire package settings
RETENTION_BINARY=/usr/syno/bin/synoretentionconf

RETENTION_PKG_NAME="SynoRetention"
RETENTION_PKG_VERSION="1.0"
RETENTION_PKG_VENDOR="Synology Inc."
RETENTION_PKG_MODVER="1.0"
RETENTION_LUN_PREFIX="Lun#"

case $1 in
	--sdk-mod-ver)
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
			if [ "0" = "${ERROR_CODE}" ]; then
				${RETENTION_BINARY} --rename "${RETENTION_LUN_PREFIX}" "${LUN_ID}" "${LUN_ID}"
			fi
		fi
	;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac

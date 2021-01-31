#!/bin/sh

###############################################################
#   This script should be hooked when invoking SYNOiSCSILunDelete()
#   Usable environment variable:
#       LUN_UUID, LUN_NAME, LUN_ROOT_PATH, LUN_ID, LUN_TYPE,
#       IS_THIN_LUN, IS_ADV_LUN, IS_BKP_LUN, ERROR_CODE
#
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
            ${RETENTION_BINARY} --remove "${RETENTION_LUN_PREFIX}" "${LUN_ID}"
        fi
    ;;
    *)
        echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
    ;;
esac


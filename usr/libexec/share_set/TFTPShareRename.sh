#!/bin/sh

###############################################################
#   This script should be hooked when invoking SYNOShareSet()
#   Usable environment variable:
#       ORIGIN_SHARE_NAME, ORIGIN_SHARE_STATUS, ORIGIN_SHARE_PATH, SHARE_NAME, SHARE_STATUS, SHARE_PATH
###############################################################

#Include common scripts
SYNOTFTP_INC_SCRP=/usr/libexec/TFTPCommon.sh
. ${SYNOTFTP_INC_SCRP}

#At begining, acquire package settings
case $1 in
    --sdk-mod-ver)
	    #Print SDK support version
        echo ${SYNOTFTP_PKG_MODVER};
    ;;
    --name)
        #Print package name
        echo ${SYNOTFTP_PKG_NAME};
    ;;
    --pkg-ver)
        #Print package version
        echo ${SYNOTFTP_PKG_VERSION};
    ;;
    --vendor)
        #Print package vendor
        echo ${SYNOTFTP_PKG_VENDOR};
    ;;
    --pre)
        #Actions before share set
        RESULT_END=`${BIN_TFTP_SHARE_RENAME} pre "${ORIGIN_SHARE_PATH}" "${SHARE_PATH}"`
    ;;
    --post)
        #Actions after share set
        RESULT_END=`${BIN_TFTP_SHARE_RENAME} post "${ORIGIN_SHARE_PATH}" "${SHARE_PATH}" "${RESULT}"`
    ;;
    *)
        echo "Usage: $0 --sdk_mod_ver|--name|--pkg_ver|--vendor|--pre|--post"
    ;;
esac


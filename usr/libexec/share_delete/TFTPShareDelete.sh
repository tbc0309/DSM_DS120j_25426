#!/bin/sh

###############################################################
#   This script should be hooked when invoking SYNOShareDelete()
#   Usable environment variable:
#       NITEMS, SHARE_NAME_X, SHARE_PATH_X, SHARE_SSTATUS_X
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
        #Actions before share del
    ;;
    --post)
        #Actions after share del
        CNT=1;

        #Check if service share
        while [ "${CNT}" -le "${NITEMS}" ]
        do
            if [ "${CNT}" = "${NITEMS}" ] ; then
                eval "TMP_SHARE_PATH=\$SHARE_PATH_${CNT}"
            else
                eval "TMP_SHARE_PATH=\$SHARE_PATH_${CNT},"
            fi

            DEL_SHARES=${DEL_SHARES}${TMP_SHARE_PATH}
            CNT=$((CNT + 1))
        done
        RESULT_END=`${BIN_TFTP_SHARE_DELETE} "${DEL_SHARES}" ${NITEMS}`
    ;;
    *)
        echo "Usage: $0 --sdk_mod_ver|--name|--pkg_ver|--vendor|--pre|--post"
    ;;
esac


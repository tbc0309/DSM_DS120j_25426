#!/bin/sh

###############################################################
#   This script should be hooked when invoking SYNOShareDelete()
#   Usable environment variable:
#       NITEMS, SHARE_NAME_X, SHARE_OP_RESULT_X
###############################################################

#Include common scripts
FILE_SYNOINDEX_INC_SCRP=/usr/libexec/SynoindexShareCommon.sh
. ${FILE_SYNOINDEX_INC_SCRP}

CheckShareDeleted() {
    # Only hooked when shares are deleted successfully
    INDEX=1;
    NITEMS=$((NITEMS + 1))
    while [ "${INDEX}" != "${NITEMS}" ]
    do
        eval "SHARE_OP_RESULT=\$SHARE_OP_RESULT_$INDEX"
        if [ "0x0000" = "${SHARE_OP_RESULT}" ]; then
            eval "SYNOINDEX_SHARE_NAME=\$SHARE_NAME_$INDEX"
            eval "SYNOINDEX_SHARE_PATH=\$SHARE_PATH_$INDEX"
            SynoindexShareRemove
        fi
        INDEX=$((INDEX + 1))
    done
}

case $1 in
    --sdk-mod-ver)
        #Print SDK support version
        echo ${SYNOINDEX_PKG_MODVER}
    ;;
    --name)
        #Print package name
        echo ${SYNOINDEX_PKG_NAME}
    ;;
    --pkg-ver)
        #Print package version
        echo ${SYNOINDEX_PKG_VERSION}
    ;;
    --vendor)
        #Print package vendor
        echo ${SYNOINDEX_PKG_VENDOR}
    ;;
    --pre)
        #Actions before share delete
    ;;
    --post)
        #Actions after share delete
        CheckShareDeleted
    ;;
    *)
        echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
    ;;
esac

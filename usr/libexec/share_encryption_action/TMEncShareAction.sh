#!/bin/sh

###############################################################
#   This script should be hooked when invoking SYNOShareEncShareMount & SYNOShareEncShareUnmount
#   Usable environment variable:
#       SHARE_NAME, ENC_ACTION={encrypt|decrypt}, RESULT
###############################################################


#At begining, acquire package settings
SYNOSDUTILS="/usr/syno/bin/synosdutils"
SYNOSERVICE="/usr/syno/sbin/synoservice"
SYNOSDUTILS_NAME="synosdutils"
SYNOSDUTILS_VENDOR="Synology Inc."
SYNOSDUTILS_VERSION="1.0"
SDK_MODVER="2.0"

case $1 in
    --sdk-mod-ver)
        #Print SDK support version
        echo ${SDK_MODVER}
    ;;
    --name)
        #Print synosdutils name
        echo ${SYNOSDUTILS_NAME}
    ;;
    --pkg-ver)
        #Print synosdutils version
        echo ${SYNOSDUTILS_VERSION}
    ;;
    --vendor)
        #Print package vendor
        echo ${SYNOSDUTILS_VENDOR}
    ;;
    --pre)
        echo "synosdutils enc share pre hook!"
    ;;
    --post)
        # do nothing when booting-up
        if /usr/syno/bin/synobootseq --is-booting-up > /dev/null 2>&1 ; then
            exit
        fi
        # do nothing when when shutdown
        if /usr/syno/bin/synobootseq --is-shutdown > /dev/null 2>&1 ; then
            exit
        fi
        #Actions after share encrypt action
        if [ "encrypt" = "${ENC_ACTION}" ]; then
            if [ "0" == "${RESULT}" ]; then
                ${SYNOSDUTILS} time-machine --disable-share "${SHARE_NAME}"
            fi
            ${SYNOSERVICE} --restart avahi
        elif [ "decrypt" = "${ENC_ACTION}" ]; then
            if [ "0" == "${RESULT}" ]; then
                ${SYNOSDUTILS} time-machine --enable-share "${SHARE_NAME}"
            fi
            ${SYNOSERVICE} --restart avahi
        fi
    ;;
    *)
        echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
    ;;
esac


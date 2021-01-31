#!/bin/sh

###############################################################
#   This script should be hooked when invoking share_set hook.
#   Usable environment variable:
#       ORIGIN_SHARE_NAME, ORIGIN_SHARE_STATUS, ORIGIN_SHARE_PATH, SHARE_NAME, SHARE_STATUS, SHARE_PATH
###############################################################

BIN="$(which synobtrfssnapusage)"

#At begining, acquire package settings
case $1 in
    --sdk-mod-ver)
	    echo "2.0" ;;
    --name)
		echo "ShareSnapshot Caculator" ;;
    --pkg-ver)
	    echo "1.0" ;;
    --vendor)
	    echo "Synology Inc." ;;
    --pre)
	    ;;
    --post)
		${BIN} --clean-share-task ${ORIGIN_SHARE_NAME}
		;;
    *)
	    echo "Usage: $0 --sdk_mod_ver|--name|--pkg_ver|--vendor|--pre|--post" ;;
esac



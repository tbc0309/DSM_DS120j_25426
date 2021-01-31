#!/bin/sh

###############################################################
#   This script should be hooked when invoking SYNOShareDelete()
#   Usable environment variable:
#       SHARE_NAME, ENC_ACTION={encrypt|decrypt}, RESULT
###############################################################

case $1 in
    --sdk-mod-ver)
        echo "2.0"
    ;;
    --name)
        echo "FileProtocol"
    ;;
    --pkg-ver)
		echo "1.0"
    ;;
    --vendor)
        echo "Synology Inc."
    ;;
    --pre)
    ;;
    --post)
		/usr/syno/sbin/synoservice --reload-by-type file_protocol
    ;;
    *)
        echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
    ;;
esac

#!/bin/sh

################################################
# SynoStorage SDK hook for volume mount
# Usable environment variable:
#       LOCATION, DEVICE, MOUNTPOINT, and RESULT
###############################################

case $1 in
        --sdk-mod-ver)
                echo "1.0"
        ;;
        --name)
                echo "synostorage volume hook"
        ;;
        --pkg-ver)
                echo "1.0"
        ;;
        --vendor)
                echo "Synology Inc."
        ;;
        --pre)
                /usr/syno/sbin/synostorage --vol-mounted ${LOCATION} ${DEVICE} ${MOUNTPOINT}
        ;;
        --post)
                if [ 0 -ne $RESULT ]; then
                        /usr/syno/sbin/synostorage --vol-unmounting ${LOCATION} ${DEVICE} ${MOUNTPOINT}
                fi
        ;;
        *)
                echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
        ;;
esac

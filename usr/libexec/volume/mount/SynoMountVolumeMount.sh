#!/bin/sh

################################################
# SynoMount SDK hook for volume mount
# Usable environment variable:
#       LOCATION, DEVICE, MOUNTPOINT, and RESULT
###############################################

case $1 in
        --sdk-mod-ver)
                echo "1.0"
        ;;
        --name)
                echo "synomount volume hook"
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
                        if [ 0 -eq $RESULT ]; then
                                /usr/syno/bin/synomount --mount-on-volume ${MOUNTPOINT};
                        fi
        ;;
        *)
                echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
        ;;
esac

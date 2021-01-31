#!/bin/sh

################################################
# SynoShare SDK hook for volume unmount
# Usable environment variable:
#	LOCATION, DEVICE, MOUNTPOINT, and RESULT
###############################################

case $1 in
        --sdk-mod-ver)
                echo "1.0"
        ;;
        --name)
                echo "WD mybook external device workaround"
        ;;
        --pkg-ver)
                echo "1.0"
        ;;
        --vendor)
                echo "Synology Inc."
        ;;
        --pre)
                /usr/syno/bin/synousbdisk -wd_mybook_wakeup
        ;;
        --post)

        ;;
        *)
                echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
        ;;
esac

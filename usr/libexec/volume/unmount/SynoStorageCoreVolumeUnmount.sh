#!/bin/bash

################################################
# SynoStorage SDK hook for volume unmount
# Usable environment variable:
#       LOCATION, DEVICE, MOUNTPOINT, and RESULT
###############################################

case $1 in
        --sdk-mod-ver)
                echo "1.0"
        ;;
        --name)
                echo "synostoragecore volume umount hook"
        ;;
        --pkg-ver)
                echo "1.0"
        ;;
        --vendor)
                echo "Synology Inc."
        ;;
        --pre)
				BTRFS_BIN="/sbin/btrfs"
				if [ 0 -eq "$RESULT" ] && [ -f "$BTRFS_BIN" ]; then
						"$BTRFS_BIN" scrub cancel "${MOUNTPOINT}" &> /dev/null ;
				fi
        ;;
        --post)

        ;;
        *)
                echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
        ;;
esac

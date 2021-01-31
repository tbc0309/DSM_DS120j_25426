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
                echo "synocheckshare, synosharesnap volume hook"
        ;;
        --pkg-ver)
                echo "1.0"
        ;;
        --vendor)
                echo "Synology Inc."
        ;;
        --pre)
			if [ 0 -eq $RESULT ]; then
				/usr/syno/bin/synocheckshare --vol-unmounting ${LOCATION} ${DEVICE} ${MOUNTPOINT};
				if [ -f "/usr/syno/sbin/synosharesnaptool" ]; then
					/usr/syno/sbin/synosharesnaptool misc vol-unmount ${LOCATION} ${DEVICE} ${MOUNTPOINT};
				fi
			fi
        ;;
        --post)

        ;;
        *)
                echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
        ;;
esac

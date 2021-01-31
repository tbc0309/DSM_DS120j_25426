#!/bin/bash

case $1 in
        --sdk-mod-ver)
                echo "1.0"
        ;;
        --name)
                echo "synostoragecore volume umount all hook"
        ;;
        --pkg-ver)
                echo "1.0"
        ;;
        --vendor)
                echo "Synology Inc."
        ;;
        --pre)
				if [ 0 -eq $RESULT ]; then
					/usr/syno/sbin/synostoragecore --cancel-all-fs-scrubbing &> /dev/null
				fi
        ;;
        --post)

        ;;
        *)
                echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
        ;;
esac

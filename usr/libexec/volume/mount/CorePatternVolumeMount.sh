#!/bin/sh

################################################
# SynoMount SDK hook for volume unmount
# Usable environment variable:
#       LOCATION, DEVICE, MOUNTPOINT, and RESULT
###############################################

case $1 in
        --sdk-mod-ver)
                echo "1.0"
        ;;
        --name)
                echo "Core file path mount volume hook"
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
                volume="$(/usr/syno/bin/servicetool --get-alive-volume)"
                if [ ! -d "$volume" ]; then
                    volume="/var/crash"
                fi
                echo "|/usr/syno/sbin/syno-dump-core.sh ${volume} %e %p %s" > /proc/sys/kernel/core_pattern
                /sbin/initctl start syno-move-coredump
        ;;
        *)
                echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
        ;;
esac

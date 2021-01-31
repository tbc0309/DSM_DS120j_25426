#!/bin/sh

PKG_NAME="File Transfer Log Volume Delete Hook"
PKG_VERSION="1.0"
PKG_VENDOR="Synology Inc."
SDK_MODVER="1.0"

case $1 in
    --sdk-mod-ver)
        echo ${SDK_MODVER}
    ;;
    --name)
        echo ${PKG_NAME}
    ;;
    --pkg-ver)
        echo ${PKG_VERSION}
    ;;
    --vendor)
        echo ${PKG_VENDOR}
    ;;
    --pre)
        SYNOLOG_FOLDER="/var/log/synolog"

        if [ "$(df "$SYNOLOG_FOLDER/.SMBXFERDB" | tail -1 | awk '{print $6}')" != "$MOUNTPOINT" ]; then
            exit
        fi

        XFERLOG_DBSIZE=$(du -d0 -m "$MOUNTPOINT/@database/synolog" | awk '{print $1}')
        ALIVE_VOLUME="$(/usr/syno/bin/servicetool --get-alive-volume $XFERLOG_DBSIZE $MOUNTPOINT)"
        OLD_XFERLOG_FOLDER="$MOUNTPOINT/@database/synolog"
        XFERLOG_FOLDER="$ALIVE_VOLUME/@database/synolog"
        XFERLOG_DBS=".AFPXFERDB .DSMFMXFERDB .FTPXFERDB .SMBXFERDB .TFTPXFERDB .WEBDAVXFERDB"


        if [ "${ALIVE_VOLUME:0:7}" = "/volume" ]; then
            # move xferlog to another enough space volume
            logger -p 3 "Move xferlog: $OLD_XFERLOG_FOLDER -> $XFERLOG_FOLDER."
            [ -d "$XFERLOG_FOLDER" ] || mkdir -p "$XFERLOG_FOLDER"
            for db in $XFERLOG_DBS; do
                mv "$OLD_XFERLOG_FOLDER/$db" "$XFERLOG_FOLDER/$db"
                ln -sf "$XFERLOG_FOLDER/$db" "$SYNOLOG_FOLDER/$db"
            done
            chown -R system:log "$XFERLOG_FOLDER"
        else
            # no enough space, compress old xferlog to any alive volume
            ALIVE_VOLUME="$(/usr/syno/bin/servicetool --get-alive-volume 0 $MOUNTPOINT)"
            XFERLOG_FOLDER="$ALIVE_VOLUME/@database/synolog"

            if [ "${ALIVE_VOLUME:0:7}" = "/volume" ]; then
                logger -p 3 "No enough volume. Compress xferlog to $XFERLOG_FOLDER/xferlog.txz."
                [ -d "$XFERLOG_FOLDER" ] || mkdir -p "$XFERLOG_FOLDER"
                /bin/tar cf "$XFERLOG_FOLDER/xferlog.txz" "$OLD_XFERLOG_FOLDER"
                for db in $XFERLOG_DBS; do
                    ln -sf "$XFERLOG_FOLDER/$db" "$SYNOLOG_FOLDER/$db"
                done
            else
                logger -p 3 "No alive volume. Drop all xferlog ..."
                for db in $XFERLOG_DBS; do
                    unlink "$SYNOLOG_FOLDER/$db"
                done
            fi
        fi
    ;;
    --post)
    ;;
    *)
        echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
    ;;
esac

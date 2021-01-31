#!/bin/sh

PKG_NAME="File Transfer Log Volume Create Hook"
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
    ;;
    --post)
        SYNOLOG_FOLDER="/var/log/synolog"
        XFERLOG_FOLDER="$MOUNTPOINT/@database/synolog"
        XFERLOG_DBS=".AFPXFERDB .DSMFMXFERDB .FTPXFERDB .SMBXFERDB .TFTPXFERDB .WEBDAVXFERDB"
        SQLITE="/bin/sqlite3"

        [ "$RESULT" -eq 0 ] || exit

		## check xferlog path link exists and is a working link
		if [ -L "$SYNOLOG_FOLDER/.SMBXFERDB" ] && [ -f "$SYNOLOG_FOLDER/.SMBXFERDB" ]; then
			exit
		fi

		mkdir -p "$XFERLOG_FOLDER"
		for db in $XFERLOG_DBS; do
			# init sqlite db
			if [ ! -f "$XFERLOG_FOLDER/$db" ]; then
				CREATE_TABLE="CREATE TABLE logs (
					id integer primary key,
					time int default NULL,
					ip text default NULL,
					username text default NULL,
					cmd text default NULL,
					filesize int default NULL,
					filename text default NULL,
					isdir integer default 0);"
				if ! $SQLITE "$XFERLOG_FOLDER/$db" "$CREATE_TABLE"; then
					echo "Create \"$db\" failed."
				fi
			fi
			/bin/chmod 660 "$XFERLOG_FOLDER/$db"
			ln -sf "$XFERLOG_FOLDER/$db" "$SYNOLOG_FOLDER/$db"
		done
		chown -R system:log "$XFERLOG_FOLDER"
    ;;
    *)
        echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
    ;;
esac

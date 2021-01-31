#!/bin/sh

PKG_NAME="synologan alert database volume delete hook"
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
		SYNOLOGAN_ALERT_DATABASE="/var/lib/synologan/database/alert.sqlite"

		if [ ! -L "$SYNOLOGAN_ALERT_DATABASE" ]; then
			exit
		fi

		SYNOLOGAN_ALERT_DATABASE_REALPATH="$(readlink $SYNOLOGAN_ALERT_DATABASE)"

		if [ "$(df "$SYNOLOGAN_ALERT_DATABASE_REALPATH" | tail -1 | awk '{print $6}')" != "$MOUNTPOINT" ]; then
			logger -p 3 "[$SYNOLOGAN_ALERT_DATABASE_REALPATH] is not on [$MOUNTPOINT], skip..."
			exit
		fi

		/usr/syno/sbin/synoservice --pause-by-reason synologanalyzer volume-action-hook

		DB_SIZE="$(du -m "$SYNOLOGAN_ALERT_DATABASE_REALPATH" | awk '{print $1}')"
		REQUIRED_SIZE="$(($DB_SIZE * 2))"
		ROOT_SIZE="$(df -m | grep  '/$' | awk '{print $4}')"
		ALIVE_VOLUME="$(/usr/syno/bin/servicetool --get-alive-volume-for-winbindd $REQUIRED_SIZE $MOUNTPOINT)"

		if [ ! -d "$ALIVE_VOLUME" ]; then
			rm -f "$SYNOLOGAN_ALERT_DATABASE"

			if [ "$ROOT_SIZE" -gt "$REQUIRED_SIZE" ]; then
				logger -p 3 "Begin to move [$SYNOLOGAN_ALERT_DATABASE_REALPATH] to [$SYNOLOGAN_ALERT_DATABASE]."
				cp -f "$SYNOLOGAN_ALERT_DATABASE_REALPATH" "$SYNOLOGAN_ALERT_DATABASE"
				logger -p 3 "Finish moving [$SYNOLOGAN_ALERT_DATABASE_REALPATH] to [$SYNOLOGAN_ALERT_DATABASE]."
			else
				logger -p 3 "No available place to store [$SYNOLOGAN_ALERT_DATABASE]."
			fi

			exit
		fi

		SYNOLOGAN_ALERT_DATABASE_NEWPATH="$(realpath -sm "$ALIVE_VOLUME/${SYNOLOGAN_ALERT_DATABASE_REALPATH:${#MOUNTPOINT}}")"

		logger -p 3 "Begin to move [$SYNOLOGAN_ALERT_DATABASE_REALPATH] to [$SYNOLOGAN_ALERT_DATABASE_NEWPATH]."
		mkdir -p $(dirname $SYNOLOGAN_ALERT_DATABASE_NEWPATH)
		cp -f "$SYNOLOGAN_ALERT_DATABASE_REALPATH" "$SYNOLOGAN_ALERT_DATABASE_NEWPATH"
		ln -sf "$SYNOLOGAN_ALERT_DATABASE_NEWPATH" "$SYNOLOGAN_ALERT_DATABASE"
		logger -p 3 "Finish moving [$SYNOLOGAN_ALERT_DATABASE_REALPATH] to [$SYNOLOGAN_ALERT_DATABASE_NEWPATH]."
	;;
	--post)
		/usr/syno/sbin/synoservice --resume-by-reason synologanalyzer volume-action-hook
	;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac

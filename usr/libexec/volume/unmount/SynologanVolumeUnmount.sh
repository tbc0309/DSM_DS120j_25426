#!/bin/sh

PKG_NAME="synologan alert database volume unmount hook"
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
	;;
	--post)
	;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac

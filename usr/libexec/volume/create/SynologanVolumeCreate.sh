#!/bin/sh

PKG_NAME="synologan alert database volume create hook"
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
		SYNOLOGAN_SERVICE="synologanalyzer"
		SYNOLOGAN_ALERT_DATABASE="/var/lib/synologan/database/alert.sqlite"

		if [ "$RESULT" -ne 0 ]; then
			exit
		fi

		if [ -L "$SYNOLOGAN_ALERT_DATABASE" ] && [ -f "$SYNOLOGAN_ALERT_DATABASE" ]; then
			exit
		fi

		/usr/syno/sbin/synoservice --restart "$SYNOLOGAN_SERVICE"
	;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac

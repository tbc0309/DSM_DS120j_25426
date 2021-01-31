#!/bin/sh

PKG_NAME="synologan alert database volume mount hook"
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
		/usr/syno/sbin/synoservice --resume-by-reason synologanalyzer volume-action-hook
	;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac

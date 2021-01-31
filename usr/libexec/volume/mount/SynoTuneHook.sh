#!/bin/sh

PKG_NAME="Syno Tuned"
PKG_VERSION="1.0"
PKG_VENDOR="Synology Inc."
SDK_MODVER="1.0"

case $1 in
	--sdk-mod-ver)
		#Print SDK support version
		echo ${SDK_MODVER}
	;;
	--name)
		#Print package name
		echo ${PKG_NAME}
	;;
	--pkg-ver)
		#Print package version
		echo ${PKG_VERSION}
	;;
	--vendor)
		#Print package vendor
		echo ${PKG_VENDOR}
	;;
	--pre)
	;;
	--post)
		/usr/syno/sbin/synotune --run
	;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac


#!/bin/sh
CONFIG_DIR="/etc/sysconfig/miniupnpd"

case $1 in
	--sdk-mod-ver)
	#Print SDK support version
	echo "1.0";
	;;
	--name)
	#Print package name
	echo "miniupnpd-1.x"
	;;
	--pkg-ver)
	#Print package version
	echo "1.0";
	;;
	--vendor)
	#Print package vendor
	echo "Synology";
	;;
	--pre)
		if [ "${OLD_TOPOLOGY}" = "router" ]; then
			synoservicecfg -stop miniupnpd-handler
		fi
	;;
	--post)
		if [ "${NEW_TOPOLOGY}" = "router" ] && [ -d ${CONFIG_DIR} ] && [ "$(ls -A $DIR)" ]; then
			synoservicecfg -start miniupnpd-handler
		fi
	;;
	*)
	echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac


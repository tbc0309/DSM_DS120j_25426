#!/bin/sh

case $1 in
	--sdk-mod-ver)
	#Print SDK support version
	echo "1.0";
	;;
	--name)
	#Print package name
	echo "miniupnpd"
	;;
	--pkg-ver)
	#Print package version
	echo "1.0";
	;;
	--vendor)
	#Print package vendor
	echo "Synology";
	;;
	--post)
	UPSTREAM_IFNAME=`ls /etc/sysconfig/miniupnpd | cut -d '-' -f 2`
	if [ "${IFNAME}" = "${UPSTREAM_IFNAME}" -o "${IFNAME}" = "lbr0" ]; then
		restart miniupnpd-handler
	fi 
	;;
	*)
    echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac


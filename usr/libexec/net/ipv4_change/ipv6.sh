#!/bin/sh

case $1 in
	--sdk-mod-ver)
	#Print SDK support version
	echo "1.0";
	;;
	--name)
	#Print package name
	echo "ipv6"
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
	if [ -e "/etc/sysconfig/networking/ipv6-${IFNAME}" ]; then
		/usr/syno/sbin/synonetdtool --init-ipv6-router ${IFNAME} ${NEW_ADDRESS}
	fi
	;;
	*)
	echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac


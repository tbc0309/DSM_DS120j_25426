#!/bin/sh

case $1 in
	--sdk-mod-ver)
	#Print SDK support version
	echo "1.0";
	;;
	--name)
	#Print package name
	echo "SynorouterClient"
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
	if [ "${IFNAME}" == "ppp0" ]; then
		start miniupnpd-handler
	fi
	;;
	*)
	echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac


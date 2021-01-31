#!/bin/sh
SYNONETD_TOOL="/usr/syno/sbin/synonetdtool"

case $1 in
	--sdk-mod-ver)
	#Print SDK support version
	echo "1.0";
	;;
	--name)
	#Print package name
	echo "DSM Networking"
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
	;;
	--post)
	enable_multi_gateway=`/bin/get_key_value /etc/synoinfo.conf multi_gateway`
	if [ "xyes" = "x${enable_multi_gateway}" ]; then
	{
		${SYNONETD_TOOL} --disable-multi-gateway
		${SYNONETD_TOOL} --disable-multi-gateway-v6
		${SYNONETD_TOOL} --enable-multi-gateway
		${SYNONETD_TOOL} --enable-multi-gateway-v6
	} &
	fi
	;;
	*)
	echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac


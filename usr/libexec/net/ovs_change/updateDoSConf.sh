#!/bin/sh
SZD_FW_SECURITY_ROOT="/etc/fw_security"

case $1 in
	--sdk-mod-ver)
	#Print SDK support version
	echo "1.0";
	;;
	--name)
	#Print package name
	echo "webapi-DoS";
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
	# Before create the ovs interface, copy dos conf from ethx.conf to ovs_ethx.conf
	if [ "xcreate" = "x$ACTION" ]; then
		for i in `ls $SZD_FW_SECURITY_ROOT | grep eth.\.conf`; do
			cp $SZD_FW_SECURITY_ROOT/${i} $SZD_FW_SECURITY_ROOT/ovs_${i};
		done
	fi
	# Before delete the ovs interface, copy dos conf from ovs_ethx.conf to ethx.conf
	if [ "xdelete" = "x$ACTION" ]; then
		for i in `ls $SZD_FW_SECURITY_ROOT | grep ovs_eth.\.conf`; do
			cp $SZD_FW_SECURITY_ROOT/${i} $SZD_FW_SECURITY_ROOT/${i/#ovs_/};
		done
	fi
	;;
	--post)
	;;
	*)
	echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac

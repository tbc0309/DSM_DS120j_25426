#!/bin/sh
#For event hook which only has post call: ipv4/6_change, if_link_up/down
LOGGER="/usr/bin/logger"
IPROUTE2_CONFIG="/etc/iproute2/config"
. /etc/iproute2/script/gateway-mgt-function
. /etc/iproute2/script/policy_routing

case $1 in
	--sdk-mod-ver)
	#Print SDK support version
	echo "1.0";
	;;
	--name)
	#Print package name
	echo "";
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
	# do nothing when interface change on shutdown step
	if /usr/syno/bin/synobootseq --is-shutdown > /dev/null 2>&1 ; then
		exit
	fi
	routing_table_remove
	routing_table_build
	;;
	*)
	echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac


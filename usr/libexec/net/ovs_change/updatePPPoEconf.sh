#!/bin/sh

case $1 in
	--sdk-mod-ver)
	#Print SDK support version
	echo "1.0";
	;;
	--name)
	#Print package name
	echo "SynoIptables";
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
	# pre stop pppoe
	/etc/rc.network stop-pppoe
	;;
	--post)
	# do nothing when interface change on shutdown step
	if /usr/syno/bin/synobootseq --is-shutdown > /dev/null 2>&1 ; then
		return
	fi
	# After we create the OVS interface, we should modified the interface name in /etc/ppp/pppoe.conf
	if [ "xcreate" = "x$ACTION" ]; then
		sed -i 's/=eth/=ovs_eth/g' /etc/ppp/pppoe.conf
		if [ -n /etc/etc/sysconfig/pppoe-relay/lbr0 ]; then
			sed -i 's/=eth/=ovs_eth/g' /etc/sysconfig/pppoe-relay/lbr0
			restart pppoerelay
		fi
		/etc/rc.network start-pppoe
	fi
	# After we remove the OVS interface, we should modified the interface name in /etc/ppp/pppoe.conf
	if [ "xdelete" = "x$ACTION" ]; then
		sed -i 's/=ovs_eth/=eth/g' /etc/ppp/pppoe.conf
		if [ -n /etc/etc/sysconfig/pppoe-relay/lbr0 ]; then
			sed -i 's/=ovs_eth/=eth/g' /etc/sysconfig/pppoe-relay/lbr0
			restart pppoerelay
		fi
		/etc/rc.network start-pppoe
	fi
	;;
	*)
	echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac

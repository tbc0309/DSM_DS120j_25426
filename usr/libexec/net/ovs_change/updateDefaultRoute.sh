#!/bin/sh

change_to_ovs()
{
	local file=$1

	if [ -n "${file}" ]; then
		sed -i 's/DEVICE=eth/DEVICE=ovs_eth/g' ${file}
		sed -i 's/DEVICE=bond/DEVICE=ovs_bond/g' ${file}
	fi
}

change_from_ovs()
{
	local file=$1

	if [ -n "${file}" ]; then
		sed -i 's/DEVICE=ovs_eth/DEVICE=eth/g' ${file}
		sed -i 's/DEVICE=ovs_bond/DEVICE=bond/g' ${file}
	fi
}

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
	# After we create the OVS interface, we should modified the interface name in /etc/iproute2/config/default-gateway
	if [ "xcreate" = "x$ACTION" ]; then
		change_to_ovs /etc/iproute2/config/default-gateway
		change_to_ovs /etc/iproute2/config/default-gateway-6
	fi
	# After we remove the OVS interface, we should modified the interface name in /etc/iproute2/config/default-gateway
	if [ "xdelete" = "x$ACTION" ]; then
		change_from_ovs /etc/iproute2/config/default-gateway
		change_from_ovs /etc/iproute2/config/default-gateway-6
	fi
	;;
	*)
	echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac

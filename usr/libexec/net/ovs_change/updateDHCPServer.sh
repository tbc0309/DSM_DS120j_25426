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
	;;
	--post)
	# do nothing when interface change on shutdown step
	if /usr/syno/bin/synobootseq --is-shutdown > /dev/null 2>&1 ; then
		return
	fi
	# After we create the OVS interface, we should copy the original interface's
	# DHCP server config into the OVS interface.
	if [ "xcreate" = "x$ACTION" ]; then
		interface=`cat /etc/dhcpd/dhcpd.conf | grep interface | grep -E "(eth|bond)" | cut -d "=" -f2`
		for ifn in $interface;
		do
			/usr/syno/sbin/synonet --dhcp_server_change_interface $ifn ovs_${ifn}
		done
		/etc/rc.network nat-restart-dhcp
	fi
	# After we remove the OVS interface, we should copy the OVS's DHCP server config
	# into the original interface.
	if [ "xdelete" = "x$ACTION" ]; then
		interface=`cat /etc/dhcpd/dhcpd.conf | grep interface | grep -E "(eth|bond)" | cut -d "=" -f2`
		for ifn in $interface;
		do
			/usr/syno/sbin/synonet --dhcp_server_change_interface $ifn ${ifn#ovs_*}
		done
		/etc/rc.network nat-restart-dhcp
	fi
	;;
	*)
	echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac

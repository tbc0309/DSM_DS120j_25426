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
	# firewall/TC rule into the OVS interface.
	if [ "xcreate" = "x$ACTION" ]; then
		# we use the ovs-vsctl to get all OVS interface and use ${iface#ovs_} to
		# remove the prefix ovs_
		for iface in `ovs-vsctl list-br`
		do
			synofirewall --change-adapter ${iface#ovs_}  $iface
			tctool -change_interface ${iface#ovs_}  $iface
		done
	fi
	# After we remove the OVS interface, we should copy the OVS's firewall/TC rule
	# into the original interface.
	if [ "xdelete" = "x$ACTION" ]; then
		# We don't know which interface has become the OVS before,
		# We use the synofirewall --enum-adapter to enum all interface which
		# may be controled by firewall.
		# We try to copy the ovs_$iface into the $ifcae, If the $ovs_iface doesn't
		# contain any rules, it won't override the $iface's rules.
		# eg. synofirewall --change-adapter ovs_pppoe pppoe.
		# Since the ovs_pppoe doesn't exist, the pppoe's rules won't be override.
		# That's the reason why we don't need to check which interface has become OVS before.
		for iface in `synofirewall --enum-adapter | tail -n+2`
		do
			synofirewall --change-adapter ovs_$iface $iface
			tctool -change_interface ovs_$iface $iface
		done
	fi
	;;
	*)
	echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac

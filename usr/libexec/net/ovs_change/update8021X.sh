#!/bin/sh

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
		return
	fi

	# After we create the OVS interface, we should copy the original interface's
	# 802.1X config into the OVS interface.
	if [ "xcreate" = "x$ACTION" ]; then
		interface=`/bin/ls /usr/syno/etc/8021X/ | /bin/grep cfg-eth | cut -d '-' -f 2`
		for ifn in $interface;
		do
			master=`/usr/syno/bin/synogetkeyvalue /etc/sysconfig/network-scripts/ifcfg-${ifn} MASTER`
			if [ -z $master ]; then
				/usr/syno/sbin/syno8021Xtool --change_interface $ifn ovs_${ifn}
			fi
		done
	fi
	# After we remove the OVS interface, we should copy the OVS's 802.1X config
	# into the original interface.
	if [ "xdelete" = "x$ACTION" ]; then
		interface=`/bin/ls /usr/syno/etc/8021X/ | /bin/grep cfg-ovs_eth | cut -d '-' -f 2`
		for ifn in $interface;
		do
			/usr/syno/sbin/syno8021Xtool --change_interface $ifn ${ifn#ovs_*}
		done
	fi
	;;
	*)
	echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac

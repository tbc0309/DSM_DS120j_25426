#!/bin/sh

case $1 in
	--sdk-mod-ver)
		#Print SDK support version
		echo "1.0";
		;;
	--name)
		#Print package name
		echo "802.1X";
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
		NEW_SLAVES=`echo $SLAVES | sed 's/,/ /g'`
		if [ "xcreate" = "x$ACTION" ]; then
			if [ "xovs" = "x$TYPE" ]; then
				for slave_ifn in $NEW_SLAVES;
				do
					interface=`ls /usr/syno/etc/8021X/ | grep cfg-ovs_eth | cut -d '-' -f 2`
					for ifn in $interface;
					do
						if [ "$slave_ifn" = "$ifn" ]; then
							/usr/syno/sbin/syno8021Xtool --change_interface $ifn ${ifn#ovs_*}
						fi
					done
				done
				/usr/syno/sbin/syno8021Xtool --copy_config_for_bond $TYPE $NEW_SLAVES
			else
				for slave_ifn in $NEW_SLAVES;
				do
					stop 8021x-client IFACE=$slave_ifn
				done
			fi
		fi
		if [ "xdelete" = "x$ACTION" ]; then
			if [ "xovs" = "x$TYPE" ]; then
				for slave_ifn in $NEW_SLAVES;
				do
					interface=`ls /usr/syno/etc/8021X/ | grep cfg-eth | cut -d '-' -f 2`
					for ifn in $interface;
					do
						if [ "${slave_ifn#ovs_*}" = "$ifn" ]; then
							/usr/syno/sbin/syno8021Xtool --change_interface $ifn ovs_${ifn}
						fi
					done
				done
			fi
		fi
		;;
	--post)
		NEW_SLAVES=`echo $SLAVES | sed 's/,/ /g'`
		# After we create bond, we should copy the 802.1X config of first interface
		# into the other interface.
		if [ "xcreate" = "x$ACTION" ]; then
			bootproto=`get_key_value /etc/sysconfig/network-scripts/ifcfg-${MASTER} BOOTPROTO`
			if [ "xovs" != "x$TYPE" ]; then
				for slave_ifn in $NEW_SLAVES;
				do
					ENABLE_8021X=`get_key_value /usr/syno/etc/8021X/cfg-${slave_ifn} enable`
					if [ "${ENABLE_8021X}" = "yes" ]; then
						stop 8021x-client IFACE=${slave_ifn}
						start 8021x-client IFACE=${slave_ifn}
					fi
				done
			fi
			if [ "xdhcp" = "x$bootproto" ]; then
				restart dhcp-client IFACE=${MASTER}
			fi
		fi
		;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
		;;
esac


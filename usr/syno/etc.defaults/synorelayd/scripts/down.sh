#!/bin/sh

cat /dev/null > /tmp/.syno_quickconnect_tunnel_info

/usr/syno/sbin/synonetdtool --del-policy-route-rule -4 QuickConnect tun1000
/usr/syno/sbin/synonetdtool --refresh-route-table   -4 tun1000 ${ifconfig_local}

if [ "x" != "x${ifconfig_ipv6_local}" ] ; then
	/usr/syno/sbin/synonetdtool --del-policy-route-rule -6 QuickConnect tun1000
	/usr/syno/sbin/synonetdtool --refresh-route-table   -6 tun1000 ${ifconfig_ipv6_local}
fi

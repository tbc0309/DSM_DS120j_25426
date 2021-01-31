#!/bin/sh

# log information
/bin/touch     /tmp/.syno_quickconnect_tunnel_info
/bin/chmod 644 /tmp/.syno_quickconnect_tunnel_info

/bin/echo "peer_ip=${route_network_1}"        >  /tmp/.syno_quickconnect_tunnel_info
/bin/echo "local_ip=${ifconfig_local}"        >> /tmp/.syno_quickconnect_tunnel_info
/bin/echo "peer_ipv6=${ifconfig_ipv6_remote}" >> /tmp/.syno_quickconnect_tunnel_info
/bin/echo "local_ipv6=${ifconfig_ipv6_local}" >> /tmp/.syno_quickconnect_tunnel_info
/bin/echo "vpn_gateway=${route_vpn_gateway}"  >> /tmp/.syno_quickconnect_tunnel_info

/usr/syno/sbin/synonetdtool --add-policy-route-rule -4 QuickConnect tun1000 NULL NULL ${route_vpn_gateway}
/usr/syno/sbin/synonetdtool --refresh-route-table -4 tun1000 ${ifconfig_local}

if [ "x" != "x${ifconfig_ipv6_netbits}" ] && [ "x" != "x${ifconfig_ipv6_remote}" ] && [ "x" != "x${ifconfig_ipv6_local}" ] ; then
	/usr/syno/sbin/synonetdtool --add-policy-route-rule -6 QuickConnect tun1000 NULL ${ifconfig_ipv6_netbits} ${ifconfig_ipv6_remote}
	/usr/syno/sbin/synonetdtool --refresh-route-table -6 tun1000 ${ifconfig_ipv6_local}
fi

# notify synorelayd
/bin/kill -SIGUSR2 $1

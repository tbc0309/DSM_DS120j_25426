#!/bin/sh
# Copyright (c) 2000-2012 Synology Inc. All rights reserved.
# For iptables rule

support_pci_wifi=`get_key_value /etc/synoinfo.conf support_pci_wifi`
if [ "yes" != "$support_pci_wifi" ]; then
	exit 0
fi

SYNO_LOG_FILE="/var/log/messages"
SYNOINFO="/etc/synoinfo.conf"
HOST_GATEWAY=''
HOST_NET_IF="br0"

DATE=`date +"%h %e %X"`

NET_TOPOLOGY=`/bin/get_key_value ${SYNOINFO} net_topology`
if [ "x${NET_TOPOLOGY}" = "x" ]; then
	exit 0
elif [ "x${NET_TOPOLOGY}" = "xrouter" ]; then
	HOST_NET_IF="lbr0"
fi

HOST_GATEWAY=`ifconfig ${HOST_NET_IF} 2> /dev/null |grep inet\ addr|cut -d ':' -f2|cut -d ' ' -f1`
if [ -z "${HOST_GATEWAY}" ]; then
	echo $DATE `basename $0`: "Unable to get gateway" >> ${SYNO_LOG_FILE}
	exit 1
fi

IPTABLES_TOOL="/usr/syno/bin/iptablestool"
SERVICE="guest_net"

KERNEL_VERSION=`uname -r`

case "$KERNEL_VERSION" in
"2.4.22-uc0")
	KERNEL_MODULES_CORE="ip_tables.o iptable_filter.o"
	KERNEL_MODULES_COMMON="ip_conntrack.o ipt_state.o ipt_multiport.o iptable_nat.o ipt_REDIRECT.o"
	IPV6_MODULES=""
	;;
"2.6.15")
	KERNEL_MODULES_CORE="ip_tables.ko iptable_filter.ko ip_conntrack.ko ip_nat.ko"
	KERNEL_MODULES_COMMON="ipt_multiport.ko ipt_state.ko"
	IPV6_MODULES=""
	;;
"2.6.24")
	KERNEL_MODULES_CORE="x_tables.ko ip_tables.ko iptable_filter.ko nf_conntrack.ko nf_conntrack_ipv4.ko"
	KERNEL_MODULES_COMMON="xt_multiport.ko xt_tcpudp.ko xt_state.ko"
	IPV6_MODULES="ip6_tables.ko ip6table_filter.ko nf_conntrack_ipv6.ko"
	;;
"2.6.3"[2-6]*)
	KERNEL_MODULES_CORE="x_tables.ko ip_tables.ko iptable_filter.ko nf_conntrack.ko nf_defrag_ipv4.ko nf_conntrack_ipv4.ko"
	KERNEL_MODULES_COMMON="xt_multiport.ko xt_tcpudp.ko xt_state.ko"
	IPV6_MODULES="ip6_tables.ko ip6table_filter.ko nf_conntrack_ipv6.ko"
	;;
"2.6.3"[7-9]*|"3."*)
	KERNEL_MODULES_CORE="x_tables.ko ip_tables.ko iptable_filter.ko nf_conntrack.ko nf_defrag_ipv4.ko nf_conntrack_ipv4.ko"
	KERNEL_MODULES_COMMON="xt_multiport.ko xt_tcpudp.ko xt_state.ko"
	IPV6_MODULES="ip6_tables.ko ip6table_filter.ko nf_defrag_ipv6.ko nf_conntrack_ipv6.ko"
	;;
*)
	echo "******iptables: Kernel version not supported******"
	;;
esac

reverse_syno() {
	local modules=$1
	local mod
	local ret=""

	for mod in $modules; do
	    ret="$mod $ret"
	done

	echo $ret
}

module()
{
	local operation=''
	local modules="${KERNEL_MODULES_CORE} ${KERNEL_MODULES_COMMON} ${IPV6_MODULES}"

	if [ "-I" = $action ]; then
		operation="--insmod"
	else
		operation="--rmmod"
		modules=`reverse_syno "$modules"`
	fi

	if [ -f $IPTABLES_TOOL ]; then
		$IPTABLES_TOOL $operation $SERVICE $modules
	else
		echo $DATE `basename $0`: "Unable to use iptablestool" >> ${SYNO_LOG_FILE}
		exit 1
	fi
}

lanBlock()
{
	if [ "${NET_TOPOLOGY}" = "router" ]; then
		`iptables -D FORWARD -i ${GUEST_NET_IF} -o ${HOST_NET_IF} -j ACCEPT` # remove a useless rule from internetBlock()

		`iptables $action FORWARD -i ${GUEST_NET_IF} -o ${HOST_NET_IF} -j DROP && \
			iptables $action FORWARD -i ${HOST_NET_IF} -o ${GUEST_NET_IF} -j DROP`
	else # bridge mode
		local route_host_br=`route -n|grep ${HOST_NET_IF} |grep -v gbr |grep -v UG |sed -n 1p | sed -e 's/[ ]\+/ /g'`
		local ip=`echo ${route_host_br} | cut -d ' ' -f1`
		local netmask=`echo ${route_host_br} | cut -d ' ' -f3`

		`iptables -D FORWARD -i ${GUEST_NET_IF} -d ${ip}/${netmask} -j ACCEPT` # remove a useless rule from internetBlock()
		`iptables $action FORWARD -i ${GUEST_NET_IF} -d ${ip}/${netmask} -j DROP`
	fi

	if [ "-D" != $action -a $? != "0"  ]; then
		echo $DATE `basename $0`: "Failed to set lanblock" >> ${SYNO_LOG_FILE}
		exit 1
	fi
}

DSBlock()
{
	#allow dns and dhcp, disallow others from gbr
	local result=`iptables $action INPUT -i ${GUEST_NET_IF} -j DROP && \
		iptables $action INPUT -i ${GUEST_NET_IF} -p udp --dport 53 -j ACCEPT && \
		iptables $action INPUT -i ${GUEST_NET_IF} -p tcp --dport 53 -j ACCEPT && \
		iptables $action INPUT -i ${GUEST_NET_IF} -p udp --dport 67 -j ACCEPT`

	if [ "-D" != $action -a $? != "0"  ]; then
		echo $DATE `basename $0`: "Failed to set DSBlock" >> ${SYNO_LOG_FILE}
		exit 1
	fi
}

internetBlock()
{
	`iptables $action FORWARD -i ${GUEST_NET_IF}  -j DROP`

	if [ "${NET_TOPOLOGY}" = "router" ]; then
		`iptables $action FORWARD -i ${GUEST_NET_IF} -o ${HOST_NET_IF} -j ACCEPT` # useless when lanblock is enabled
	else # bridge mode
		local route_host_br=`route -n|grep ${HOST_NET_IF} |grep -v gbr |grep -v UG |sed -n 1p | sed -e 's/[ ]\+/ /g'`
		local ip=`echo ${route_host_br} | cut -d ' ' -f1`
		local netmask=`echo ${route_host_br} | cut -d ' ' -f3`

		`iptables $action FORWARD -i ${GUEST_NET_IF} -d ${ip}/${netmask} -j ACCEPT` # useless when lanblock is enabled
	fi

	if [ "-D" != $action -a $? != "0"  ]; then
		echo $DATE `basename $0`: "Failed to set internetBlock" >> ${SYNO_LOG_FILE}
		exit 1
	fi
}

httpOnly()
{
	local result=`iptables $action FORWARD -i ${GUEST_NET_IF} -p tcp -m multiport --dports 80,443 -j ACCEPT`

	if [ "-D" != $action -a $? != "0"  ]; then
		echo $DATE `basename $0`: "Failed to set httpOnly" >> ${SYNO_LOG_FILE}
		exit 1
	fi
}

allBlock()
{
	if [ $action = "-D" ]; then
		internetBlock
		httpOnly
		lanBlock
		DSBlock
	else
		local MAC_ADDRESS=`cat /sys/class/net/${interface}/address`
		local WIFI_AP_CONF="/usr/syno/etc/wifi/wifi_ap_${MAC_ADDRESS}"
		local GUEST_ALLOW_ACCESS_LAN=`get_section_key_value ${WIFI_AP_CONF} general guest_allow_access_lan`
		local GUEST_ALLOW_ACCESS_HTTP_HTTPS_ONLY=`get_section_key_value ${WIFI_AP_CONF} general guest_allow_access_http_https_only`
		local LAN_BLOCK="1"
		local ACCES_DS="0"
		local INTERNET_BLOCK="0"
		local ALLOW_HTTP="1"
		if [ "x${GUEST_ALLOW_ACCESS_LAN}" = "xyes" ]; then
			LAN_BLOCK="0"
			ACCES_DS="1"
		fi

		if [ "x${GUEST_ALLOW_ACCESS_HTTP_HTTPS_ONLY}" = "xyes" ]; then
			INTERNET_BLOCK="1"
		fi

		if [ "x${INTERNET_BLOCK}" = "x1" ]; then
			internetBlock
			if [ "x${ALLOW_HTTP}" = "x1" ]; then
				httpOnly
			fi
		fi

		if [ "x${LAN_BLOCK}" = "x1" ]; then
			lanBlock
			if [ "x${ACCES_DS}" != "x1" ]; then
				DSBlock
			fi
		fi
	fi
}

act=$1
rule=$2
interface=$3
GUEST_NET_IF="gbr`echo $interface | cut -d 'n' -f2`"

case $act in
	ins)
		action="-I"
		;;
	del)
		action="-D"
		;;
	*)
		echo "Usage: $0 [ins|del] [lanblock|dsblock|internetblock|httponly|all|mod]"
		exit 1
esac

case $rule in
	lanblock)
		lanBlock
		;;
	dsblock)
		DSBlock
		;;
	internetblock)
		internetBlock
		;;
	httponly)
		httpOnly
		;;
	all)
		allBlock
		;;
	mod)
		module
		;;
	*)
		echo "Usage: $0 [ins|del] [lanblock|dsblock|internetblock|httponly|all|mod] [interface ex:wlan0]"
		exit 1
esac
exit 0

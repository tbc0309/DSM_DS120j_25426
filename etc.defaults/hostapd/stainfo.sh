#!/bin/sh
# Copyright (c) 2000-2012 Synology Inc. All rights reserved.

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/syno/sbin:/usr/syno/bin

STA_INFO_LOCK="/tmp/lock/lock_stainfo"
STA_CONN_LIST_LOCK="/tmp/lock/lock_sta_conn_list"
STA_INFO="/tmp/hostap-sta.info"
STA_CONN_LIST="/tmp/hostap-sta-conn-list.info"
ARP_INFO="/tmp/arp.temp"
BRIDGE_INFO="/tmp/bridge_info"
IFCFG_DIR="/etc/sysconfig/network-scripts/"

GUEST_NET_ACCESS_RULE_ENABLED=`grep guest_net /tmp/iptables_serv_mod_map 2> /dev/null | wc -l`
door_for_guest_net()
{
	local act=""
	if [ -z "$GUEST_NET_ACCESS_RULE_ENABLED" -o "$GUEST_NET_ACCESS_RULE_ENABLED" = "0" ]; then
		return;
	fi

	case $1 in
		open)
			act="-I"
			;;
		close)
			act="-D"
			;;
		*)
			return;
			;;
	esac

	iptables $act INPUT -i gbr -m state --state ESTABLISHED -j ACCEPT &> /dev/null
}

hostapd_cli_info()
{
	: > ${STA_INFO}
	for iterf in `hostapd_cli interface |sed '1,2d'`; do
		hostapd_cli -i $iterf all_sta | grep -v '=' | grep -v interface | \
		while read mib ;do
			echo $mib $iterf >> ${STA_INFO}
		done
	done
}

bridge_info()
{
	local bridge=''
	: > ${BRIDGE_INFO}

	brctl show | sed '1d' | \
	while read line; do
		local interf=`echo $line|awk '{print $4}'`
		if [ ! -z "$interf" ]; then
			bridge=`echo $line|awk '{print  $1}'`
		else
			interf=`echo $line|awk '{print $1}'`
		fi

		echo "$bridge $interf" >> ${BRIDGE_INFO}
	done
}

init_arp_info()
{
	local DNS_SERVER_LIST=`grep nameserver /etc/resolv.conf | awk '{print $2}'`
	for dns in $DNS_SERVER_LIST; do
		/bin/ping -W 1 -w 1 -c 1 $dns > /dev/null
		if [ 0 -eq $? ]; then
			arp -a > ${ARP_INFO}
			break
		fi
	done
}

sta_hostname()
{
	local DHCPD_LEASES="/etc/dhcpd/dhcpd.conf.leases"
	local DHCPD_INFO="/etc/dhcpd/dhcpd.info"

	local ret=""
	local dhcp_enable=`get_key_value $DHCPD_INFO enable`

	door_for_guest_net open
	while read line; do
		local ip=""
		local hostname=""
		local mac=`echo $line | cut -d' ' -f1`
		local breakline=""
		local interf=`echo $line | cut -d' ' -f4`
		local bridge=`grep ${interf} ${BRIDGE_INFO} | cut -d' ' -f1`
		local br_netmask=`get_key_value ${IFCFG_DIR}/ifcfg-${bridge} NETMASK`
		local br_ip=`get_key_value ${IFCFG_DIR}/ifcfg-${bridge} IPADDR`
		local subnet=`ipcalc -n ${br_ip} ${br_netmask}|cut -d'=' -f2`

		line=`echo $line | cut -d' ' -f-3`

		if [ "yes" == "${dhcp_enable}" -a -f "${DHCPD_LEASES}" ]; then
			local lease=`grep $mac $DHCPD_LEASES`

			if [ ! -z "$lease" ]; then
				local lease_ip=`echo $lease | awk {'printf $3'}`
				local lease_hostname=`echo $lease | awk {'printf $4'}`
				local lease_subnet=`[ ! -z "${lease_ip}" ] && ipcalc -n ${lease_ip} ${br_netmask}|cut -d'=' -f2`

				if [ "${lease_subnet}" = "${subnet}" ]; then
					hostname=${lease_hostname}
					ip=${lease_ip}
				fi
			fi
		fi

		if [ -f "${ARP_INFO}" ]; then
			local arp=`grep -i "${mac}.*${bridge}" ${ARP_INFO}`
			if [ ! -z "$arp" ]; then
				ip=`grep -m1 -i "${mac}.*${bridge}" ${ARP_INFO} | cut -d'(' -f2 | cut -d')' -f1`
				local hostname_arp=`grep -m1 -i "${mac}.*${bridge}" ${ARP_INFO} | awk {'print $1'}`
				if [ "?" !=  "$hostname_arp" ]; then
					hostname=$hostname_arp
				fi
			fi
		fi

		if [ -z "${hostname}" -a -n "${ip}" ]; then
			hostname=`nmblookup -A ${ip} | grep ACTIVE | grep -v GROUP | awk {'print $1'} | uniq | xargs`
		fi

		if [ -z "${hostname}" ]; then
			hostname="-"
		fi

		if [ -z "${ip}" ]; then
			ip="-"
		fi

		if [ ! -z "${ret}" ]; then
			breakline="\n"
		fi
		ret="${ret}${breakline}${line} ${ip} ${hostname}"

	done < ${STA_INFO}
	door_for_guest_net close

	(flock -x 201
		if [ -z "$ret" ]; then
			: > ${STA_CONN_LIST}
		else
			echo -e $ret > ${STA_CONN_LIST}
		fi
	) 201> ${STA_CONN_LIST_LOCK}
}

collect_sta_info()
{
	(flock -xn 200
		if [ ! "$?" = "0" ]; then
			return #being locked by another
		fi

		hostapd_cli_info
		bridge_info
		init_arp_info
		sta_hostname

	) 200> ${STA_INFO_LOCK}
}

read_sta_info()
{
	(flock -s 201
		[ -f "${STA_CONN_LIST}" ] && cat ${STA_CONN_LIST}
	) 201< ${STA_CONN_LIST_LOCK}
}

case "$1" in
collect-stainfo)
	collect_sta_info
	;;
*)
	read_sta_info
	;;
esac

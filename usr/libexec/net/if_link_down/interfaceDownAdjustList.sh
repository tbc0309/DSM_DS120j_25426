#!/bin/sh
. /etc/iproute2/script/gateway-mgt-function
. /etc/iproute2/script/policy_routing

ETHTOOL="/bin/ethtool"
SYNONETD_TOOL="/usr/syno/sbin/synonetdtool"
INTERFACE_UP_DOWN_LOCK="/tmp/interface_up_down_${IFNAME}.lock"
CARRIER_CONF="/sys/class/net/${IFNAME}/carrier"

delete_wireless_interface()
{
	local topology=`/bin/get_key_value /etc/synoinfo.conf net_topology`
	if [ "client" != "${topology}" ]; then
		return
	fi

	# wpa connect and disconnect will pop alot of up-down event
	# make sure wpa is really disconnect
	local wpa_ps=`/bin/ps -e ww | /bin/grep wpa_supplicant | /bin/grep -v wired | /bin/grep ${IFNAME}`
	if [ -n "$wpa_ps" ]; then
		local wpa_status=`/usr/sbin/wpa_cli -i ${IFNAME} status | /bin/grep wpa_state | /usr/bin/cut -d'=' -f2`
		if [ "xCOMPLETED" = "x${wpa_status}" ]; then
			return
		fi
	fi

	${SYNONETD_TOOL} --del-gateway-info -4 ${IFNAME}
	${SYNONETD_TOOL} --del-gateway-info -6 ${IFNAME}
	${SYNONETD_TOOL} --refresh-gateway -4
	${SYNONETD_TOOL} --refresh-gateway -6

	${SYNONETD_TOOL} --reset-ipv6-module ${IFNAME}

	local enable_multi_gateway=`/bin/get_key_value /etc/synoinfo.conf multi_gateway`
	if [ "xyes" = "x${enable_multi_gateway}" ]; then
		${SYNONETD_TOOL} --del-policy-route-rule -4 multi-gateway ${IFNAME}
	fi
	${SYNONETD_TOOL} --disable-route-table -4 ${IFNAME}
}

delete_6in4_tunnel_interface()
{
	if [ ! -e "/sys/class/net/6in4-${IFNAME}" ]; then
		return
	fi

	/sbin/ip tunnel del 6in4-${IFNAME}

	${SYNONETD_TOOL} --del-gateway-info -6 6in4-${IFNAME}
	${SYNONETD_TOOL} --refresh-gateway -6
}

delete_wired_interface()
{
	##For OVS bonding, we need to delete its slave gateway info manually.
	if [ "${IFNAME#ovs_bond*}" != "${IFNAME}" ]; then
		#remove the slave of ovs_bond.
		for ifs in `synogetkeyvalue /etc/sysconfig/network-scripts/ifcfg-${IFNAME} SLAVE_LIST`; do
			${SYNONETD_TOOL} --del-gateway-info -4 ${ifs}
			${SYNONETD_TOOL} --del-gateway-info -6 ${ifs}
			${SYNONETD_TOOL} --reset-ipv6-module ${ifs}
		done
	fi

	local isLinkDown=""
	if [ -f ${CARRIER_CONF} ]; then
		local isLinkDown=`cat ${CARRIER_CONF}`
	fi

	# OVS maintains the information and status in userspace instead of in kernel
	# space, so the kernel don't hold the correct value at ${CARRIER_CONF}.
	if [ "x" != "x${isLinkDown}" ] && [ "${IFNAME#ovs_bond*}" == "${IFNAME}" ]; then
		if [ "0" != "${isLinkDown}" ]; then
			return
		fi

		local IFCFG_FILE="/etc/sysconfig/network-scripts/ifcfg-${IFNAME}"
		if [ ! -f ${IFCFG_FILE} ]; then
			return
		fi
	fi


	${SYNONETD_TOOL} --del-gateway-info -4 ${IFNAME}
	${SYNONETD_TOOL} --del-gateway-info -6 ${IFNAME}
	#Disable OVS -> rc.network stop -> interface down -> hook event -> this script.
	#We can't know does the $IFNAME has the relation with the OVS status here, and only the synonetd knosw the policy/gateway info of OVS interface.
	#That's why we force remove the gateway of OVS interface.
	${SYNONETD_TOOL} --del-gateway-info -4 "ovs_${IFNAME}"
	${SYNONETD_TOOL} --del-gateway-info -6 "ovs_${IFNAME}"
	${SYNONETD_TOOL} --refresh-gateway -4
	${SYNONETD_TOOL} --refresh-gateway -6

	${SYNONETD_TOOL} --reset-ipv6-module ${IFNAME}

	local enable_multi_gateway=`/bin/get_key_value /etc/synoinfo.conf multi_gateway`
	if [ "xyes" = "x${enable_multi_gateway}" ]; then
		${SYNONETD_TOOL} --del-policy-route-rule -4 multi-gateway ${IFNAME}
	fi
	${SYNONETD_TOOL} --disable-route-table -4 ${IFNAME}
}

dhcp_adjust()
{
	IFCFG_FILE="/etc/sysconfig/network-scripts/ifcfg-${1}"
	BOOTPROTO=$(get_key_value "${IFCFG_FILE}" BOOTPROTO)

	if [ "${BOOTPROTO}" = "dhcp" ]; then
		IFF_UP=0x1
		if_flags=$(cat /sys/class/net/"${1}"/flags)
		if [ "0" = "$((if_flags & IFF_UP))" ]; then
			# Interface is down
			stop dhcp-client IFACE="${1}"
		else
			restart dhcp-client IFACE="${1}"
		fi
	fi
}

case $1 in
	--sdk-mod-ver)
	#Print SDK support version
	echo "1.0";
	;;
	--name)
	#Print package name
	echo "SynorouterClient"
	;;
	--pkg-ver)
	#Print package version
	echo "1.0";
	;;
	--vendor)
	#Print package vendor
	echo "Synology";
	;;
	--post)
	(
	i=0
	while [ 120 != $i ]; do
		if flock -n -x 10; then
			dhcp_adjust "${IFNAME}"
			if [ -d "/sys/devices/virtual/net/ovs_${IFNAME}" ]; then
				dhcp_adjust "ovs_${IFNAME}"
			fi

			echo ${IFNAME} | grep -q "^wlan"
			if [ $? -eq 0 ]; then
				delete_wireless_interface
				flock -u 10
				rm ${INTERFACE_UP_DOWN_LOCK}
				exit
			fi
			is_wired_interface ${IFNAME}
			if [ $? -eq 0 ]; then
				delete_wired_interface
				flock -u 10
				rm ${INTERFACE_UP_DOWN_LOCK}
				exit
			fi
			is_6in4_interface ${IFNAME}
			if [ $? -eq 0 ]; then
				${SYNONETD_TOOL} --disable-route-table -6 ${IFNAME}
				flock -u 10
				rm ${INTERFACE_UP_DOWN_LOCK}
				exit
			fi
			delete_6in4_tunnel_interface
			flock -u 10
			rm ${INTERFACE_UP_DOWN_LOCK}
			exit
		else
			i=$(($i+1))
			sleep 1
		fi
	done
	)10> $INTERFACE_UP_DOWN_LOCK

	if ! Is213Air ; then
		# do nothing when interface change on shutdown step
		if /usr/syno/bin/synobootseq --is-shutdown > /dev/null 2>&1 ; then
			exit
		fi
		routing_table_remove
		routing_table_build
	fi
	;;

	*)
	echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac


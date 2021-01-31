#!/bin/sh
. /etc/iproute2/script/gateway-mgt-function
. /etc/iproute2/script/policy_routing

SYNONETD_TOOL="/usr/syno/sbin/synonetdtool"
INTERFACE_UP_DOWN_LOCK="/tmp/interface_up_down_${IFNAME}.lock"
SYNONET="/usr/syno/sbin/synonet"
IPCALC="/bin/ipcalc"

is_wifi_client()
{
	echo ${IFNAME} | grep -q "^wlan"
	if [ $? -ne 0 ]; then
		return 1
	fi
	local topology=`/bin/get_key_value /etc/synoinfo.conf net_topology`
	if [ "client" != "${topology}" ]; then
		return 1
	fi
	# wpa connect and disconnect will pop alot of up-down event
	# make sure wpa is really connected
	local wpa_ps=`/bin/ps -e ww | /bin/grep wpa_supplicant | /bin/grep -v wired | /bin/grep ${IFNAME}`
	if [ -z "$wpa_ps" ]; then
		return 1
	fi

	return 0
}

add_interface()
{
	local GATEWAY="NULL"
	local DNS="NULL"
	local IFCFG_FILE="/etc/sysconfig/network-scripts/ifcfg-${IFNAME}"
	local DHCP_INFO="/etc/dhclient/ipv4/dhcpcd-${IFNAME}.info"
	local GATEWAY_DATABASE="/etc/iproute2/config/gateway_database"
	local AUTH_8021X_CONFIG="/usr/syno/etc/8021X/cfg-${IFNAME}"

	if [ ! -f ${IFCFG_FILE} ]; then
		return
	fi
	local BOOTPROTO=`get_key_value ${IFCFG_FILE} BOOTPROTO`
	if [ "${BOOTPROTO}" = "none" ]; then
		return
	fi

	local BRIDGE=`get_key_value ${IFCFG_FILE} BRIDGE`

	local ENABLE_8021X=`get_key_value ${AUTH_8021X_CONFIG} enable`

	if [ "${ENABLE_8021X}" = "yes" ]; then
		stop 8021x-client IFACE=${IFNAME}
		start 8021x-client IFACE=${IFNAME}
	fi

	if [ "${BOOTPROTO}" = "dhcp" -a -z "${BRIDGE}" -a "${ENABLE_8021X}" != "yes" ]; then
		if /usr/syno/bin/synobootseq --is-ready > /dev/null 2>&1 ; then
			local IPADDR=`get_key_value ${DHCP_INFO} IPADDR`
			local NETMASK=`get_key_value ${DHCP_INFO} NETMASK`
			if [ "$IPADDR" != "" ] && [ "$NETMASK" != "" ]; then
				local PREFIX=`$IPCALC -p $IPADDR $NETMASK | cut -d '=' -f 2`

				$SYNONET --set_ip -4 $IFNAME add $IPADDR/$PREFIX
			fi
		fi
		status dhcp-client IFACE=${IFNAME}
		if [ $? = 0 ]; then
			restart dhcp-client IFACE=${IFNAME}
		else
			start dhcp-client IFACE=${IFNAME}
		fi
	elif [ "${BOOTPROTO}" = "static" -a -z "${BRIDGE}" ]; then
		local IPADDR=`get_key_value ${IFCFG_FILE} IPADDR`
		local NETMASK=`get_key_value ${IFCFG_FILE} NETMASK`
		local PREFIX=`$IPCALC -p $IPADDR $NETMASK | cut -d '=' -f 2`

		$SYNONET --set_ip -4 $IFNAME add $IPADDR/$PREFIX

		GATEWAY=`get_section_key_value ${GATEWAY_DATABASE} ${IFNAME} gateway`
		if test -z "$GATEWAY" ; then
			GATEWAY="NULL"
		fi
		DNS=`get_section_key_value ${GATEWAY_DATABASE} ${IFNAME} dns`
		if test -z "$DNS" ; then
			DNS="NULL"
		fi
	fi

	${SYNONETD_TOOL} --add-gateway-info -4 -2 ${IFNAME} ${GATEWAY} ${DNS} ethernet

	if [ ! -z "${BRIDGE}" ]; then
		${SYNONETD_TOOL} --set-slave-data -4 ${IFNAME} yes
	fi

	set_default_gateway_interface

	${SYNONETD_TOOL} --refresh-gateway -4
}

add_interface_v6()
{
	local GATEWAY="NULL"
	local DNS="NULL"
	local IFCFG_FILE="/etc/sysconfig/network-scripts/ifcfg-${IFNAME}"
	if [ ! -f ${IFCFG_FILE} ]; then
		return
	fi
	local IPV6INIT=`get_key_value ${IFCFG_FILE} IPV6INIT`
	if [ "${IPV6INIT}" = "off" ]; then
		return
	fi

	local BRIDGE=`get_key_value ${IFCFG_FILE} BRIDGE`

	if [ "${IPV6INIT}" = "static" -a -z "${BRIDGE}" ]; then
		GATEWAY=`get_key_value ${IFCFG_FILE} IPV6_DEFAULTGW`
		if test -z "$GATEWAY" ; then
			GATEWAY="NULL"
		fi
		DNS=`get_key_value ${IFCFG_FILE} IPV6DNS`
		if test -z "$DNS" ; then
			DNS="NULL"
		fi
	fi

	${SYNONETD_TOOL} --add-gateway-info -6 -2 ${IFNAME} ${GATEWAY} ${DNS} ethernet

	if [ ! -z "${BRIDGE}" ]; then
		${SYNONETD_TOOL} --set-slave-data -6 ${IFNAME} yes
	fi

	set_default_gateway_interface

	${SYNONETD_TOOL} --refresh-gateway -6
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
	##If the openvswitch exists, we need to add the prefix ovs_ to the IFNAME
	if [ -d "/sys/devices/virtual/net/ovs_${IFNAME}" ]; then
		IFNAME="ovs_${IFNAME}"
	fi
	(
	i=0
	while [ 120 != $i ]; do
		if flock -n -x 10; then
			ifconfig ${IFNAME} > /dev/null 2>&1
			if [ $? -ne 0 ]; then
				flock -u 10
				rm ${INTERFACE_UP_DOWN_LOCK}
				exit;
			fi
			is_wifi_client
			WIFI_CLIENT=$?
			is_wired_interface ${IFNAME}
			WIRED_INTERFACE=$?
			if [ "$WIFI_CLIENT" -eq "0" -o "$WIRED_INTERFACE" -eq "0" ]; then
				add_interface
				add_interface_v6

				if [ -e "/etc/sysconfig/networking/ipv6-${IFNAME}" ]; then
					local IP=`/sbin/ifconfig ${IFNAME} | grep -Eo 'inet addr:([0-9]*\.){3}[0-9]*' | cut -d: -f 2`
					${SYNONETD_TOOL} --init-ipv6-router ${IFNAME} ${IP}
				fi
				flock -u 10
				rm ${INTERFACE_UP_DOWN_LOCK}
				exit
			fi
			#lbr0 & gbr0 need to set IP again to add route
			if [ "lbr0" = "${IFNAME}" -o "gbr0" = "${IFNAME}" ]; then
				IFCFG_FILE="/etc/sysconfig/network-scripts/ifcfg-${IFNAME}"
				IPADDR=`get_key_value ${IFCFG_FILE} IPADDR`
				NETMASK=`get_key_value ${IFCFG_FILE} NETMASK`
				PREFIX=`$IPCALC -p $IPADDR $NETMASK | cut -d '=' -f 2`

				$SYNONET --set_ip -4 $IFNAME add $IPADDR/$PREFIX
			fi
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


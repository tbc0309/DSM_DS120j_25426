#!/bin/sh

#
# Get the link speed of a network interface.
#
# @param ifname [IN]
#		A network interface name, e.g. eth0.
#
# @return
#		On success, returns 0, and prints the link speed of the
#		network interface to stdout.
#		Otherwise, returns 1.
#
get_nic_speed ()
{
	local ifname="$1"
	local if_file="/sys/class/net/${ifname}/speed"
	local if_speed

	if [ $# -lt 1 ]; then
		echo "get_nic_speed failed - bad parameters"
		return 1
	fi

	if [ ! -f "${if_file}" ]; then
		return 1
	fi

	if_speed=$(cat "${if_file}")
	if [ $? -ne 0 ]; then
		return 1
	fi

	echo "${if_speed}"
	return 0
}

#
# Get the MTU of a network interface.
#
# @param ifname [IN]
#		A network interface name, e.g. eth0.
#
# @return
#		On success, returns 0, and prints the MTU of the
#		network interface to stdout.
#		Otherwise, returns 1.
#
get_nic_mtu ()
{
	local ifname="$1"
	local if_file="/sys/class/net/${ifname}/mtu"
	local if_mtu

	if [ $# -lt 1 ]; then
		echo "get_nic_mtu failed - bad parameters"
		return 1
	fi

	if [ ! -f "${if_file}" ]; then
		return 1
	fi

	if_mtu=$(cat "${if_file}")
	if [ $? -ne 0 ]; then
		return 1
	fi

	echo "${if_mtu}"
	return 0
}

#
# Get the MTU configuration value of a network interface.
#
# @param ifname [IN]
#		A network interface name, e.g. eth0.
#
# @return
#		On success, returns 0, and prints the MTU configuration
#		value of the network interface to stdout.
#		Otherwise, returns 1.
#
get_nic_mtu_config ()
{
	local ifname="$1"
	local is_support_mtu
	local mtu_value

	if [ $# -lt 1 ]; then
		echo "get_nic_mtu_config failed - bad parameters"
		return 1
	fi

	is_support_mtu=`/bin/get_key_value /etc.defaults/synoinfo.conf supportMTU`
	if [ $? -ne 1 ]; then
		return 1
	fi

	if [ "${is_support_mtu}" != "yes" ] || [ ! -x "/usr/syno/bin/synoethinfo" ]; then
		# synoethinfo does not exist in network install mode
		return 1
	fi

	mtu_value=`/bin/get_key_value /etc/synoinfo.conf ${ifname}_mtu`
	if [ $? -ne 1 ]; then
		return 1
	fi

	echo "${mtu_value}"
	return 0
}

#
# Adjust the MTU of a network interface.
#
# This function is designed to make sure that MTU=1500 is always
# applied to NICs connected to 100 Mbps ethernet.
#
# @param ifname [IN]
#		A network interface name, e.g. eth0.
#
# @return
#		On success, returns 0.
#		Otherwise, returns 1.
#
adjust_mtu ()
{
	local ifname="$1"
	local nic_speed
	local current_mtu
	local expected_mtu

	if [ $# -lt 1 ]; then
		echo "adjust_mtu failed - bad parameters"
		return 1
	fi

	nic_speed=$(get_nic_speed "${ifname}")
	if [ $? -ne 0 ]; then
		return 1
	fi

	current_mtu=$(get_nic_mtu "${ifname}")
	if [ $? -ne 0 ]; then
		return 1
	fi

	expected_mtu=$(get_nic_mtu_config "${ifname}")
	if [ $? -ne 0 ]; then
		return 1
	fi

	# Note that the scemd polls MTU change and keeps the same as synoinfo.conf
	# Therefore, if you change the logic below, you should also pay attention to
	# scemd's, and make them rational.

	if [ ${nic_speed} -eq 100 ]; then
		# since 100 Mbps ethernet may not support MTU,
		# set the expected MTU to the default value 1500 or lower.
		if [ ${expected_mtu} -gt 1500 ]; then
			expected_mtu=1500
		fi
	fi

	if [ ${current_mtu} -ne ${expected_mtu} ]; then
		logger -p err "Adjust ${ifname} MTU from ${current_mtu} to ${expected_mtu}"
		ifconfig "${ifname}" mtu "${expected_mtu}"
	fi

	return 0
}

case $1 in
	--sdk-mod-ver)
	#Print SDK support version
	echo "1.0";
	;;
	--name)
	#Print package name
	echo "set MTU"
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
	adjust_mtu "${IFNAME#ovs_*}"
	;;
	*)
	echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac

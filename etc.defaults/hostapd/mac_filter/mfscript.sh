#!/bin/sh
# Copyright (c) 2000-2012 Synology Inc. All rights reserved.

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/syno/sbin:/usr/syno/bin

HOSTAPD_DIR="/etc/hostapd"
MAC_FILTER_DIR=${HOSTAPD_DIR}"/mac_filter"
MF_CONF=${MAC_FILTER_DIR}"/mf.conf"
MF_INFO=${MAC_FILTER_DIR}"/mf.info"
HOSTAP_MAC_FILE=${HOSTAPD_DIR}"/hostapd-mac.list"

activate_mac_filter()
{
	local enable=
	local policy=
	local hostapd_bak_conf=$1".bak"

	if [ ! -f "$1" -o ! -f "$MF_CONF" -o ! -f "$MF_INFO" ]; then
		return
	fi

	enable=`get_key_value $MF_INFO enable`
	policy=`get_key_value $MF_INFO policy`

	if [ -z "$enable" ]; then
		return
	fi

	if [ "yes" != "$enable" ]; then
		disable_mac_filter $1
		return
	fi

	if [ ! -f "${HOSTAP_MAC_FILE}" ]; then
		grep "mac=" $MF_CONF | cut -d"=" -f2 > ${HOSTAP_MAC_FILE}
	fi

	cat $1 | grep -v "macaddr_acl" | grep -v "_mac_file" > $hostapd_bak_conf

	if [ ! -f "$hostapd_bak_conf" -o ! -f "${HOSTAP_MAC_FILE}" ]; then
	   return
	fi

	case "$policy" in
		accept)
			echo "macaddr_acl=1" >> $hostapd_bak_conf		#deny unless in accept list
			echo "accept_mac_file=${HOSTAP_MAC_FILE}" >> $hostapd_bak_conf
			;;
		deny)
			echo "macaddr_acl=0" >> $hostapd_bak_conf		#accept unless in deny list
			echo "deny_mac_file=${HOSTAP_MAC_FILE}" >> $hostapd_bak_conf
			;;
	esac
	mv ${hostapd_bak_conf} $1
	return 0
}

disable_mac_filter()
{
	local hostapd_bak_conf=$1".bak"

	cat $1 | grep -v "macaddr_acl" | grep -v "_mac_file" > $hostapd_bak_conf
	echo "macaddr_acl=0" >> $hostapd_bak_conf

	mv ${hostapd_bak_conf} $1
	return 0
}

action=$1
shift;
case "$action" in
	start)
		activate_mac_filter "$@"
		;;
	stop)
		disable_mac_filter "$@"
		;;
	*)
	echo "Usage: $0 [start|stop]"
	;;
esac

exit 0

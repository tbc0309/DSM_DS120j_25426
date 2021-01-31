#!/bin/sh
# Copyright (c) 2000-2013 Synology Inc. All rights reserved.

DHCPD_DIR="/etc/dhcpd/"
LEASE_FILE="${DHCPD_DIR}/dhcpd.conf.leases"
LOG_FILE="${DHCPD_DIR}/dhcpd-leases.log"
TMP_FILE="${DHCPD_DIR}/tmp-dhcpd-leases.log"

del_leases() { # $2: mac
	local mac=$2
	grep -v "${mac}" ${LOG_FILE} > ${TMP_FILE}
	cp ${TMP_FILE} ${LOG_FILE}
}

renew_record() { # $1: expired $2 mac $3 ip $4 hostname $5 iface
	local record=$@
	local mac=$2
	local iface=$5

	grep -v "${mac}" ${LOG_FILE} > ${TMP_FILE}
	echo "${record}" >> ${TMP_FILE}
	cp ${TMP_FILE} ${LOG_FILE}
}

add_new_record() {
	local record="$@"
	local mac=$2

	# when disable dhcp-server and any lease is expired, then next time the dhcp client
	# renew the lease the action will be add, so remove the old record has same MAC address
	grep -v "${mac}" ${LOG_FILE} > ${TMP_FILE}
	cp ${TMP_FILE} ${LOG_FILE}

	if [ -s ${LOG_FILE} ]; then
		sed -i "1 i${record}" ${LOG_FILE}
	else
		echo ${record} >> ${LOG_FILE}
	fi
}

get_hostname_from_logfile() {
	local mac="$1"
	local filename="";
	local line="`grep \"${mac}\" ${LOG_FILE}`"
	local tokens=( $line )

	if [ 5 -eq ${#tokens[@]} ]; then
		filename=${tokens[3]}
	fi

	echo $filename
}

get_new_record() {
	local mac="$2"
	local ip="$3"
	local hostname="$4"
	local fileHostname=$(get_hostname_from_logfile $mac)

	if [ "x" = "x${hostname}" ] && [ "xold" = "x${ACTION}" ];then
		if [ "x" != "x${DNSMASQ_SUPPLIED_HOSTNAME}" ]; then
			hostname=${DNSMASQ_SUPPLIED_HOSTNAME}
		elif [ "x" != "x${fileHostname}" ]; then
			hostname=${fileHostname}
		fi
	fi

	NEW_RECORD="${DNSMASQ_LEASE_EXPIRES} ${mac} ${ip} ${hostname} ${DNSMASQ_INTERFACE}"
}

# record format: action mac ip hostname
NEW_RECORD=$@
ACTION=`echo ${NEW_RECORD} | awk '{print $1}'`

if [ "${DNSMASQ_INTERFACE}" = "" ]; then
	exit 0
fi
get_new_record ${NEW_RECORD}

case "${ACTION}" in
	old)
		renew_record ${NEW_RECORD}
		;;
	add)
		add_new_record ${NEW_RECORD}
		;;
	del)
		del_leases ${NEW_RECORD}
		;;
	*)
		;;
esac

exit 0

#!/bin/sh
# Copyright (c) 2000-2013 Synology Inc. All rights reserved.
#
# S98pppoerelay.sh - startup script for pppoe-relay
#
# This goes in /usr/syno/etc/rc.d and gets run at boot-time.

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/syno/sbin:/usr/syno/bin
NETWORK_SCRIPTS_CONFIG_DIR="/etc/sysconfig/network-scripts/"
NETWORK_INTERFACE_DIR="/sys/class/net/"
PPPOE_RELAY_CONFIG_DIR="/etc/sysconfig/pppoe-relay/"
PPPOE_RELAY_BIN="/usr/sbin/pppoe-relay"
LOG_FILE="/var/log/messages"
NETWORK_INTERFACES=""

echo_log ()
{
	if [ $# -eq 0 ]; then
		return
	fi

	echo "$0: $@" >> ${LOG_FILE}
}

# check and add interface into ${NETWORK_INTERFACES}
check_interfaces ()
{
	if [ $# -eq 1 ]; then
		NETWORK_INTERFACES=`ls ${NETWORK_INTERFACE_DIR}`
		local pppoe_relay_ifns=`ls ${PPPOE_RELAY_CONFIG_DIR}`

		for ifn in ${pppoe_relay_ifns}; do
			if [ ! -d ${NETWORK_INTERFACE_DIR}${ifn} ]; then
				NETWORK_INTERFACES="${NETWORK_INTERFACES} ${ifn}"
			fi
		done
	else
		NETWORK_INTERFACES="$@"
	fi
}

start_pppoe_relay_all ()
{
	for ifn in ${NETWORK_INTERFACES}; do
		start_pppoe_relay_on "${ifn}"
	done
}

start_pppoe_relay_on ()
{
	local ifn="$1"

	if [ -z "${ifn}" ]; then
		echo_log "Interface is empty."
		return
	fi

	local pppoe_relay_config="${PPPOE_RELAY_CONFIG_DIR}${ifn}"
	local network_script_config="${NETWORK_SCRIPTS_CONFIG_DIR}ifcfg-${ifn}"
	local network_interface="${NETWORK_INTERFACE_DIR}${ifn}"

	if [ ! -r ${pppoe_relay_config} -o ! -r ${network_script_config} ]; then
		return
	fi

	local pppoe_relay_enable=`/bin/get_key_value ${pppoe_relay_config} enable`
	local pppoe_relay_server=`/bin/get_key_value ${pppoe_relay_config} server`
	local local_lan_enable=`/bin/get_key_value ${network_script_config} LOCAL_LAN`
	if [ "x${pppoe_relay_enable}" != "xyes" -o "x${local_lan_enable}" != "xyes" -o ! -d ${network_interface} ]; then
		return
	fi

	${PPPOE_RELAY_BIN} -C ${ifn} -S ${pppoe_relay_server} >> ${LOG_FILE} 2>&1
}

stop_pppoe_relay_all ()
{
	for ifn in ${NETWORK_INTERFACES}; do
		stop_pppoe_relay_on "${ifn}"
	done
}

stop_pppoe_relay_on ()
{
	local ifn="$1"
	local i=0
	local max=10

	if [ -z "${ifn}" ]; then
		echo_log "Interface is empty."
		return
	fi

	while [ $i -lt $max ]; do
		local pids=`ps -aux | awk "/[p]ppoe-relay -C ${ifn}/{print \\$2}"`

		if [ -z "${pids}" ]; then
			break
		fi

		for pid in ${pids}; do
			/bin/kill -9 ${pid} 1>/dev/null 2>&1
		done

		sleep 1
		i=`expr $i + 1`
	done

	if [ $i -eq $max ]; then
		echo_log "Failed to kill pppoe-relay [${ifn}]"
	fi
}

reload_pppoe_relay_on ()
{
	local ifn="$1"

	local pppoe_relay_is_running=`ps -w | grep "${PPPOE_RELAY_BIN}" | grep "${ifn}" | grep -v grep | wc -l`

	if [ "x0" != "x${pppoe_relay_is_running}" ]; then
		local pppoe_relay_server=`/bin/get_key_value ${PPPOE_RELAY_CONFIG_DIR}${ifn} server`
		local pppoe_relay_config_correct=`ps -w | grep "${PPPOE_RELAY_BIN}" | grep "${ifn}" | grep "${pppoe_relay_server}" | grep -v grep | wc -l`

		if [ "x1" == "x${pppoe_relay_config_correct}" ]; then
			return
		fi

		stop_pppoe_relay_on "${ifn}"
	fi

	start_pppoe_relay_on "${ifn}"
}

reload_pppoe_relay_all ()
{
	for ifn in ${NETWORK_INTERFACES}; do
		reload_pppoe_relay_on "${ifn}"
	done
}


case "$1" in
start)
	check_interfaces "$@"
	stop_pppoe_relay_all
	start_pppoe_relay_all
	;;
stop)
	check_interfaces "$@"
	stop_pppoe_relay_all
	;;
restart)
	check_interfaces "$@"
	stop_pppoe_relay_all
	start_pppoe_relay_all
	;;
reload)
	check_interfaces "$@"
	reload_pppoe_relay_all
	;;
*)
	echo "usage: $0 { start | stop | restart }" >&2
	exit 1
	;;
esac

exit 0

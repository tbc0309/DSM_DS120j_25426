#!/bin/sh
# Copyright (c) 2000-2017 Synology Inc. All rights reserved.

SZF_ROUTER_CONF="/etc/portforward/router.conf"
SYNOROUTERTOOL="/usr/syno/sbin/synoroutertool"

is_specified_gw ()
{
	# check if section of router.conf pointer to current default gw
	if $SYNOROUTERTOOL --pf_conf_status; then
		return 0
	fi

	return 1
}

is_interface_gwif ()
{
	local ifname=$1
	local gateway_interface=`ip route | grep default | cut -d ' ' -f 5`
	local if_mac=''
	local gwif_mac=''

	if [ "x$gateway_interface" == "x" ]; then # routing table may not stable(like router rebooting situation)
		return 1
	fi

	if [ "x$ifname" == "x" ]; then
		return 1
	fi

	if_mac=$(synonet --get_mac_addr ${ifname} original | awk -F'Mac is: ' '{print $2}')
	gwif_mac=$(synonet --get_mac_addr ${gateway_interface} original | awk -F'Mac is: ' '{print $2}')

	if [ "x$if_mac" == "x" ]; then
		return 1
	fi

	if [ "x$gwif_mac" == "x" ]; then
		return 1
	fi

	if [ ! "$if_mac" == "$gwif_mac" ]; then
		return 1
	fi

	return 0
}

is_any_rule()
{
	if [ -f /etc/portforward/rule.conf ] && [ `grep "enabled=1" /etc/portforward/rule.conf | wc -l` != "0" ]; then
		return 0
	fi
	return 1
}

check_do_it ()
{
	#check $IFNAME
	if ! is_interface_gwif $IFNAME; then
		return 1
	fi

	# check if current default gateway address is match router.conf's section header
	if ! is_specified_gw; then
		return 1
	fi

	if ! is_any_rule; then
		return 1
	fi

	return 0
}

# 0: router is ready
# 1: timeout. wait for 3 min but router is still not ready
wait_router_protocol_ready()
{
    local TU=30
    local WAIT=180 # 3 min, I assume all router can ready in 3 min
	SECONDS=0
    for i in `seq 1 $WAIT`
    do
        timeout -k $TU $TU sh -c "$SYNOROUTERTOOL --pf_protocol_status > /dev/null 2>&1"
        if [ $? -eq 0 ]; then
            return 0
        fi

		if [ $SECONDS -ge $WAIT ];then
			break;
		fi

		sleep 1
    done
    return 1
}

wait_ds_default_gw_ready()
{
	local TU=1
	local WAIT=60
	local default_gw=''

	for i in `seq 1 $WAIT`
	do
		default_gw=`ip route | grep ^default | cut -d ' ' -f 5`
		if [ "x$default_gw" == "x" ]; then
			sleep 1
			continue
		fi
		return 0
	done
	return 1
}

start_daemon ()
{
	local daemon_name=$1
	# if daemon stopped, start it
	if ! synoservice --status ${daemon_name}; then
		if is_any_rule; then
			synoservice --start ${daemon_name}
			# always send notification(no save tag) when change gateway
			/usr/syno/bin/synonotify 'PF_GwChangedPFEnabled'
		fi
	fi
}

stop_daemon ()
{
	local daemon_name=$1
	# if daemon started, stop it
	if synoservice --status ${daemon_name}; then
		synoservice --stop ${daemon_name}
		# always send notification(no save tag) when change gateway
		/usr/syno/bin/synonotify 'PF_GwChangedPFDisabled'

		# reset notification tag to allow notification for next time
		# start_daemon. But start_daemon() may run with other actions like if up...
		# to let other actions can send notification normally we reset tag here.
		$SYNOROUTERTOOL --reset_notification
	fi
}

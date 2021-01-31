#!/bin/ash
# Copyright (c) 2000-2017 Synology Inc. All rights reserved.
. /usr/libexec/net/pf_common.sh

SZF_ROUTER_CONF="/etc/portforward/router.conf"

is_duplicated_event ()
{
	if [ ! -f /tmp/pf_pre_gateway ]; then
		echo "$GATEWAY" > /tmp/pf_pre_gateway
		return 1
	fi
	if diff <(echo "$GATEWAY") <(cat /tmp/pf_pre_gateway); then
		return 0
	fi
	echo "$GATEWAY" > /tmp/pf_pre_gateway
	return 1
}

change_daemon_status ()
{
	local daemon_name=$1
	if is_specified_gw; then
		start_daemon $daemon_name
	else
		stop_daemon $daemon_name
	fi
}

gateway_change_hook ()
{
	# stop upnpd/natpmpd if gateway changes to another gateway.
	# start upnpd/natpmpd if gateway changes back to configured gateway.

	if [ ! "x$ACTION" == "xNEW" ]; then
		return
	fi
	if [ ! "x$DESTINATION" == "x0.0.0.0" ]; then
		return
	fi

	if is_duplicated_event; then
		return
	fi

	# When unplug network, need to wait routing table stable.
	# Polling to see if default gw ready ?
	sleep 10
	if ! wait_ds_default_gw_ready; then
		return
	fi

	ROUTER_TYPE=`/bin/get_key_value $SZF_ROUTER_CONF router_type`
	if [ "$ROUTER_TYPE" == "upnp" ]; then
		SUPPORT_UPNP=`/bin/get_key_value $SZF_ROUTER_CONF support_router_upnp`
		if [ "$SUPPORT_UPNP" == "yes" ]; then
			change_daemon_status "upnpd"
		fi
	elif [ "$ROUTER_TYPE" == "natpmp" ]; then
		change_daemon_status "natpmpd"
	fi
}

post_up ()
{
	# Use lock to avoid event come in concurrently
	# When default gw chagned, there are three NEW/DEL events come in concurrently,
	# but only want to trigger gateway_change_hook once.
	# Use lock and is_duplicated_event() to avoid this situation.
	(
		flock -n 9

		gateway_change_hook

	) 9>/tmp/pf_gateway_change.lock
}

case $1 in
	--sdk-mod-ver)
		#Print SDK support version
		echo "1.0"
		;;
	--name)
		#Print package name
		echo "SynorouterClient"
		;;
	--pkg-ver)
		#Print package version
		echo "1.0"
		;;
	--vendor)
		#Print package vendor
		echo "Synology"
	;;
	--post)
		# do nothing when link updown on booting-up step
		if /usr/syno/bin/synobootseq --is-booting-up > /dev/null 2>&1 ; then
			exit
		fi
		# do nothing when link updown shutdown step
		if /usr/syno/bin/synobootseq --is-shutdown > /dev/null 2>&1 ; then
			exit
		fi

		post_up &
	;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--post"
	;;
esac


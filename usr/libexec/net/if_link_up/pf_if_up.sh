#!/bin/sh
# Copyright (c) 2000-2017 Synology Inc. All rights reserved.

. /usr/libexec/net/pf_common.sh

SZF_ROUTER_CONF="/etc/portforward/router.conf"
SYNOROUTERTOOL="/usr/syno/sbin/synoroutertool"

apply ()
{
	#When router reboot, can not re-apply portforward rule immediately
	#Need to wait miniupnpd on router to ready. But we can not known when
	# 1. miniupnpd on router is ready.
	# 2. interface on router which connec between router and DS is ready
	# 3. interface on DS which connect between router and DS is ready
	if ! wait_router_protocol_ready; then
		# if protocol not ready, apply must be failed
		$SYNOROUTERTOOL --send_notification 'PF_ReApplyError'
		return
	fi

	router_type=`/bin/get_key_value $SZF_ROUTER_CONF router_type`
	# restart daemon
	if [ "$router_type" == "upnp" ]; then
		support_upnp=`/bin/get_key_value $SZF_ROUTER_CONF support_router_upnp`
		if [ "$support_upnp" == "yes" ]; then
			synoservice --restart upnpd
		fi
	elif [ "$router_type" == "natpmp" ]; then
		synoservice --restart natpmpd
	fi
}

post_up ()
{
	sleep 30 # wait for routing table stable

	# To ensure default gw ready and then we can use check_do_it()
	# Because when interface up, routing table may not stable yet
	# check_do_it() need routing table stable.
	if ! wait_ds_default_gw_ready; then
		return
	fi

	# Use check_do_it to heck conf/env first to avoid unnessary UPnP/NatPmP packets on netowrk
	if ! check_do_it; then
		return
	fi

	# Use non-blocking lock to aggregate applys
	# (means if there are multiple applys at the same time, do it only once)
	(
	  flock -n 9 || exit 1

	  apply

	) 9>/tmp/pf_apply.lock
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


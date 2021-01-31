#!/bin/sh
# Copyright (c) 2000-2017 Synology Inc. All rights reserved.

. /usr/libexec/net/pf_common.sh

SZF_ROUTER_CONF="/etc/portforward/router.conf"
SYNOROUTERTOOL="/usr/syno/sbin/synoroutertool"

pre_up ()
{
	if ! check_do_it; then
		return
	fi

	ROUTER_TYPE=`/bin/get_key_value $SZF_ROUTER_CONF router_type`
	if [ ! "$ORIGIN_ADDRESS" == "$NEW_ADDRESS" ]; then #ip change
		if [ "$ROUTER_TYPE" == "upnp" ]; then
			SUPPORT_UPNP=`/bin/get_key_value $SZF_ROUTER_CONF support_router_upnp`
			if [ "$SUPPORT_UPNP" == "yes" ]; then
					$SYNOROUTERTOOL --apply_clean_ruleconf $ORIGIN_ADDRESS
			fi
		elif [ "$ROUTER_TYPE" == "natpmp" ]; then
			# make sure the following code not blocking ip change
			# For --pre of ip change event, 'change ip' needs to wait all hookscripts to be done.
			$SYNOROUTERTOOL --apply_clean_ruleconf
		fi
	fi
}

apply_post ()
{
	# ip may change when router is booting
	if ! wait_router_protocol_ready; then
		# if protocol not ready, apply must be failed
		$SYNOROUTERTOOL --send_notification 'PF_ReApplyError'
		return
	fi

	ROUTER_TYPE=`/bin/get_key_value $SZF_ROUTER_CONF router_type`
	if [ ! "$ORIGIN_ADDRESS" == "$NEW_ADDRESS" ]; then #ip change
		if [ "$ROUTER_TYPE" == "upnp" ]; then
			SUPPORT_UPNP=`/bin/get_key_value $SZF_ROUTER_CONF support_router_upnp`
			if [ "$SUPPORT_UPNP" == "yes" ]; then
				synoservice --restart upnpd
			fi
		elif [ "$ROUTER_TYPE" == "natpmp" ]; then
			synoservice --restart natpmpd
		fi
	fi
}

post_up ()
{
	# ip may change when router is booting
	if ! wait_ds_default_gw_ready; then
		return
	fi

	if ! check_do_it; then
		return
	fi

	# Use non-blocking lock to aggregate applys
	# (means if there are multiple applys at the same time, do it only once)
	(
	  flock -n 9 || exit 1

	  apply_post

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
	--pre)
		# do nothing when link updown on booting-up step
		if /usr/syno/bin/synobootseq --is-booting-up > /dev/null 2>&1 ; then
			exit
		fi
		# do nothing when link updown shutdown step
		if /usr/syno/bin/synobootseq --is-shutdown > /dev/null 2>&1 ; then
			exit
		fi
		pre_up
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
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac


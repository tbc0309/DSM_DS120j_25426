#!/bin/sh

IPTABLES_IF_LOCK_FILE="/tmp/iptables_interface_hook.lock"

case $1 in
	--sdk-mod-ver)
	#Print SDK support version
	echo "1.0";
	;;
	--name)
	#Print package name
	echo "SynoIptables";
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
	# do nothing when interface change on shutdown step
	if /usr/syno/bin/synobootseq --is-shutdown > /dev/null 2>&1 ; then
		exit
	fi
	# do nothing when booting, we'll run this in upstart when booting is done.
	if /usr/syno/bin/synobootseq --is-booting-up > /dev/null 2>&1 ; then
		exit
	fi
	(
	if flock -n -x 8; then
		## avoid exec many times when encounter series net interface change event
		sleep 5
		flock -u 8
		rm ${IPTABLES_IF_LOCK_FILE}
		/usr/syno/bin/syno_iptables_common force-reload > /dev/null 2>&1
		/usr/syno/bin/synotc_common force-reload > /dev/null 2>&1
	fi
	)8> ${IPTABLES_IF_LOCK_FILE} &
	;;
	*)
	echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac


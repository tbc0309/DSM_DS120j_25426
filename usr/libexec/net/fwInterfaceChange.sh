#!/bin/sh

FW_IF_LOCK_FILE="/tmp/firewall_interface_hook.lock"

case $1 in
	--sdk-mod-ver)
	#Print SDK support version
	echo "1.0";
	;;
	--name)
	#Print package name
	echo "SynoFirewall";
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
		return
	fi
	(
	if flock -n -x 8; then
		## avoid exec many times when encounter series net interface change event
		sleep 5
		flock -u 8
		rm ${FW_IF_LOCK_FILE}
		/usr/syno/bin/synofirewall --reload
	fi
	)8> ${FW_IF_LOCK_FILE} &
	;;
	*)
	echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac


#!/bin/sh
LOGGER="/usr/bin/logger"

log_msg()
{
	${LOGGER} -p warn -t "gateway_config_change hook event" "$1 "
}

case $1 in
	--sdk-mod-ver)
	#Print SDK support version
	echo "1.0";
	;;
	--name)
	#Print package name
	echo ""
	;;
	--pkg-ver)
	#Print package version
	echo "1.0";
	;;
	--vendor)
	#Print package vendor
	echo "Synology";
	;;
	--pre)
	;;
	--post)
	# do nothing when gateway config change on booting-up step
	if /usr/syno/bin/synobootseq --is-booting-up > /dev/null 2>&1 ; then
		exit
	fi
	# do nothing when gateway config change on booting-up step
	if /usr/syno/bin/synobootseq --is-shutdown > /dev/null 2>&1 ; then
		exit
	fi
	log_msg "${GATEWAY_OLD} to ${GATEWAY_NEW} on ${INTERFACE} over ${TYPE}"
	;;
	*)
    echo ""
	;;
esac


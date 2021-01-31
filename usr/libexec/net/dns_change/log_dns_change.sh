#!/bin/sh
LOGGER="/usr/bin/logger"

log_msg()
{
	${LOGGER} -p warn -t "dns_change hook event" "$1 "
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
		r
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
	# do nothing when ip change on booting-up step
	if /usr/syno/bin/synobootseq --is-booting-up > /dev/null 2>&1 ; then
		exit
	fi
	# do nothing when ip change shutdown step
	if /usr/syno/bin/synobootseq --is-shutdown > /dev/null 2>&1 ; then
		exit
	fi
	msg="(${NITEMS})"
	for i in `seq 1 ${NITEMS}`
	do
		DNSNAME="DNS_$i"
		eval DNS=\$$DNSNAME
		msg=${msg}" DNS$i=${DNS}";
	done
	log_msg "${msg}"
	;;
	*)
    echo ""
	;;
esac


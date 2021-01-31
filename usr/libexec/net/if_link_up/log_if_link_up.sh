#!/bin/sh
LOGGER="/usr/bin/logger"

log_msg()
{
	${LOGGER} -p warn -t "if_link_up hook event" "$1 "
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
	--post)
	# do nothing when ip change shutdown step
	if /usr/syno/bin/synobootseq --is-shutdown > /dev/null 2>&1 ; then
		exit
	fi
	log_msg ${IFNAME}
	;;
	*)
    echo ""
	;;
esac

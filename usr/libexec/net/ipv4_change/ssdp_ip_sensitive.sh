#!/bin/sh
case $1 in
	--sdk-mod-ver)
	#Print SDK support version
	echo "1.0";
	;;
	--name)
	#Print package name
	echo "ssdp";
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
	# do nothing when ip change on booting-up step
	if /usr/syno/bin/synobootseq --is-booting-up > /dev/null 2>&1 ; then
		exit
	fi
	# do nothing when ip change shutdown step
	if /usr/syno/bin/synobootseq --is-shutdown > /dev/null 2>&1 ; then
		exit
	fi
	# ignores the events comming from the interfaces for PPTP/L2TP server-side,
	# whose names are in the ranage of ppp201-299 and ppp301-399, because no
	# services interested them.
	echo $IFNAME | grep 'ppp[2-3]\{1\}[0-9]\{2\}' > /dev/null 2>&1
	if [ "$?" == "0" ] && [ "ppp200" != "$IFNAME" ] && [ "ppp300" != "$IFNAME" ]; then
		exit
	fi
	if [ "tun1000" = "$IFNAME" ]; then
		exit
	fi
	synoservice --restart ssdp >/dev/null 2>&1 || true
	;;
	*)
	echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--post"
	;;
esac


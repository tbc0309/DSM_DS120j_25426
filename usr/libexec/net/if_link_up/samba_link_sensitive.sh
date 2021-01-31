#!/bin/sh
case $1 in
	--sdk-mod-ver)
	#Print SDK support version
	echo "1.0";
	;;
	--name)
	#Print package name
	echo "samba link sensitive services";
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
	# do nothing when link updown on booting-up step
	if /usr/syno/bin/synobootseq --is-booting-up > /dev/null 2>&1 ; then
		exit
	fi
	# do nothing when link updown shutdown step
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
	synoservice --restart nmbd >/dev/null 2>&1 || true
	synoservice --restart winbindd >/dev/null 2>&1 || true
	;;
	*)
	echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac


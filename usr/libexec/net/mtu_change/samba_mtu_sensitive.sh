#!/bin/sh
case $1 in
	--sdk-mod-ver)
	#Print SDK support version
	echo "1.0";
	;;
	--name)
	#Print package name
	echo "samba mtu sensitive services";
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
	# do nothing when mtu change on booting-up step
	if /usr/syno/bin/synobootseq --is-booting-up > /dev/null 2>&1 ; then
		exit
	fi
	# do nothing when mtu change shutdown step
	if /usr/syno/bin/synobootseq --is-shutdown > /dev/null 2>&1 ; then
		exit
	fi
	synoservice --restart samba >/dev/null 2>&1 || true
	synoservice --restart nmbd >/dev/null 2>&1 || true
	synoservice --restart winbindd >/dev/null 2>&1 || true
	;;
	*)
	echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac


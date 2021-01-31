#!/bin/sh

case $1 in
	--sdk-mod-ver)
	#Print SDK support version
	echo "1.0";
	;;
	--name)
	#Print package name
	echo "avahi"
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
		# do nothing when ip change on booting-up step
		if /usr/syno/bin/synobootseq --is-booting-up > /dev/null 2>&1 ; then
			exit
		fi
		# do nothing when ip change shutdown step
		if /usr/syno/bin/synobootseq --is-shutdown > /dev/null 2>&1 ; then
			exit
		fi
		/usr/syno/sbin/synoservice --pause-by-reason avahi 'ipv6_change'
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
		/usr/syno/sbin/synoservice --resume-by-reason avahi 'ipv6_change'
	;;
	*)
	echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac


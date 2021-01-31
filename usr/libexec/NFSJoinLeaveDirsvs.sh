#!/bin/sh

case $1 in
	--sdk-mod-ver)
	#Print SDK support version
	echo "1.0";
	;;
	--name)
	#Print package name
	echo "synoNFS";
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
	/usr/syno/sbin/synoservice --status nfsd >/dev/null 2>&1
	if [ "$?" -ne 3 ] ; then
		 /usr/syno/etc/rc.sysv/S83nfsd.sh reloadidmap
	fi
	;;
	*)
	echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac


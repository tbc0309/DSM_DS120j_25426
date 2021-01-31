#!/bin/sh

case $1 in
	--sdk-mod-ver)
		#Print SDK support version
		echo "1.0";
		;;
	--name)
		#Print package name
		;;
	--pkg-ver)
		#Print package version
		;;
	--vendor)
		#Print package vendor
		;;
	--post)
		#Actions after disjoin
		/usr/syno/etc/rc.sysv/S99synogpoclient.sh stop
		;;
	*)
		echo "Usage: $0 --sdk_mod_ver|--name|--pkg_ver|--vendor|--post"
		;;
esac


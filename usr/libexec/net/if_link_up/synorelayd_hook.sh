#!/bin/sh

case $1 in
	--sdk-mod-ver)
		#Print SDK support versio
		echo "1.0";
	;;
	--name)
		#Print package name
		echo "synorelayd"
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
        # skip relay tunnel interface
        if [ "x${IFNAME}" = "xtun1000" ] ;then
            exit 0
        fi

        # reload
		if synoservice --status synorelayd > /dev/null 2>&1 ; then
			synoservice --reload synorelayd > /dev/null 2>&1 || true
		elif synoservice --status support-remote-access > /dev/null 2>&1; then
			synoservice --reload support-remote-access > /dev/null 2>&1 || true
		fi
	;;
	--pre)
	;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac


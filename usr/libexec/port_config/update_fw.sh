#!/bin/sh

post_up ()
{
	if [ "x$NOTIFY_FW" != "x1" ]; then
		return
	fi

	/usr/syno/bin/synofirewall --update
	/usr/syno/bin/synofirewall --reload
}

case $1 in
	--sdk-mod-ver)
        	#Print SDK support version
	        echo "2.0"
	;;
	--name)
        	#Print package name
	        echo "libsynoserviceconf"
	;;
	--pkg-ver)
        	#Print package version
	        echo "1.0"
	;;
	--vendor)
        	#Print package vendor
	        echo "Synology"
	;;
	--pre)
	;;
	--post)
	        post_up
	;;
	*)
	        echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac


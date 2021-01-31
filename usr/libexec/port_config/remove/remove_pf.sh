#!/bin/sh

post_up ()
{
	if [ "x$NOTIFY_PF" != "x1" ] || [ "x$PORT_CONFIG_CONTENT" = "x" ]; then
		return
	fi
	PORT_CONFIG_FILE="/tmp/$(basename $0).$$"

	echo "$PORT_CONFIG_CONTENT" > "$PORT_CONFIG_FILE"

	/usr/syno/sbin/synoroutertool --remove "$PORT_CONFIG_FILE"
	rm -f "$PORT_CONFIG_FILE"
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


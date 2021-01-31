#!/bin/sh

post_up ()
{
	if [ "x$NOTIFY_PF" != "x1" ] || [ "x$OLD_PORT_CONFIG_CONTENT" = "x" ] || [ "x$NEW_PORT_CONFIG_CONTENT" = "x" ]; then
		return
	fi
	OLD_PORT_CONFIG_FILE="/tmp/$(basename $0).oldsc.$$"
	NEW_PORT_CONFIG_FILE="/tmp/$(basename $0).newsc.$$"

	echo "$OLD_PORT_CONFIG_CONTENT" > "$OLD_PORT_CONFIG_FILE"
	echo "$NEW_PORT_CONFIG_CONTENT" > "$NEW_PORT_CONFIG_FILE"

	/usr/syno/sbin/synoroutertool --update "$OLD_PORT_CONFIG_FILE" "$NEW_PORT_CONFIG_FILE"
	rm -f "$OLD_PORT_CONFIG_FILE"
	rm -f "$NEW_PORT_CONFIG_FILE"
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


#!/bin/sh

case $1 in
	--sdk-mod-ver)
		#Print SDK support version
		echo "1.0";
	;;
	--name)
		#Print package name
		echo "DDNS"
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
		echo "--post";
	;;
	--pre)
		echo "[Logout MyDS Account] Disable Synology DDNS Service" >> /var/log/messages
		/usr/syno/sbin/synoddnsinfo --set-record-disable Synology
		/usr/syno/sbin/synoservice --stop heartbeat
		COUNT=`synoddnsinfo --get-hostname | wc -w`
		if [ $COUNT -eq 0 ]; then
			/usr/syno/sbin/synoservice --stop ddns
			/usr/syno/bin/synosetkeyvalue /tmp/ddns.info service_status_inprocess "no"
		else
			/usr/syno/sbin/synoservice --restart ddns
		fi
		/usr/syno/bin/synosetkeyvalue /tmp/ddns.status Synology "-"
		/usr/syno/bin/synosetkeyvalue /tmp/ddns.lastupdated Synology "-"
	;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac


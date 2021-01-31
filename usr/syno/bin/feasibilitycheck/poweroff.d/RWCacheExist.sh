#!/bin/bash
if [ "$2" != "cacheCheckShutdown" ]; then
	exit 0;
fi

supportSSDCache=`/usr/syno/bin/synogetkeyvalue /etc.defaults/synoinfo.conf support_ssd_cache`
if [ "yes" = "$supportSSDCache" ]; then

	#Example:
	#"dirty blocks(10), dirty percent(0)" want to get "10"
	#and sum total dirty blocks
	sum=`/sbin/dmsetup table | /bin/grep -o 'dirty blocks([0-9]*)' | /bin/grep -o '[0-9]*' | /bin/awk '{ SUM += $1} END { print SUM }'`
	if [ ! -z $sum ] && [ $sum -gt 0 ]; then
		exit 1
	fi
fi
exit 0

#!/bin/sh
# Copyright (c) 2000-2007 Synology Inc. All rights reserved.

case $1 in
	start)
		echo "We only disalbe WD idle3 timer when DS down, please call $0 stop"
	;;
	stop)
		echo "Disabling WD idle3 timer ..."
		for d in `/usr/syno/bin/synodiskport -internal` `/usr/syno/bin/synodiskport -eunit`
		do
			/usr/syno/bin/syno_disk_ctl --wd-idle -d /dev/$d
		done
		;;
	*)
		echo "Usage: $0 start|stop"
	;;
esac

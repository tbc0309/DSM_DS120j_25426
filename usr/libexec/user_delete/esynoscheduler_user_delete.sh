#!/bin/sh
# Copyright (c) 2000-2015 Synology Inc. All rights reserved.

case $1 in
	--sdk-mod-ver)
		echo "1.0"
	;;
	--name)
		echo "eTaskScheduler"
	;;
	--pkg-ver)
		echo "1.0"
	;;
	--vendor)
		echo "Synology Inc."
	;;
	--pre)
	;;
	--post)
		tasks_uid=`/bin/sqlite3 /usr/syno/etc/esynoscheduler/esynoscheduler.db "SELECT DISTINCT owner FROM task;"`
		if [ "$?" != "0" ]
		then
			/usr/bin/logger -p user.err -t "etaskscheduler_delete_user" "Fail to find distinct owner from esynoscheduler.db"
			exit 1
		fi

		for uid in $tasks_uid
		do
			user_info=`/usr/syno/sbin/synouser --getuid "${uid}" 2>&1`
			if [ "$?" == "0" ]
			then
				continue
			fi
			err_num=`echo "${user_info}" | grep "0x1D00"`
			if [ "$?" == "0" ]
			then
				/bin/sqlite3 /usr/syno/etc/esynoscheduler/esynoscheduler.db "UPDATE task SET enable=0 WHERE owner=${uid};"
			fi
		done
	;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac


#!/bin/sh
# Copyright (c) 2000-2013 Synology Inc. All rights reserved.

. /etc.defaults/rc.subr

ProcName="ftpd"
PidFile="/var/run/${ProcName}.pid"

case $1 in
	reload)
		/usr/syno/sbin/synoservicectl --status ftpd
		if [ 0 == $? ]; then
			/usr/bin/killall -HUP ftpd
		fi
		exit 0
	;;
	status)
		if pidof ftpd ; then
			if [ -f $PidFile ] ; then
				pid=`cat $PidFile`
				if [ 0 != `ps | grep $ProcName | grep $pid | wc -l` ]; then
					exit $LSB_STAT_RUNNING
				else
					exit $LSB_STAT_DEAD_FPID
				fi
			fi
			exit $LSB_STAT_RUNNING
		else
			if [ -f $PidFile ] ; then
				exit $LSB_STAT_DEAD_FPID
			else
				exit $LSB_STAT_NOT_RUNNING
			fi
		fi &> /dev/null
	;;
	*)
		echo "Usages: $0 [status|reload]"
	;;
esac

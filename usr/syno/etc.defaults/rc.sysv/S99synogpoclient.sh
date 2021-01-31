#!/bin/sh

EXEFILE="/usr/syno/sbin/synogpoclientd"
PIDFILE="/var/run/synogpoclientd.pid"

# Get pid
is_daemon_alive() {
	if [ -f "$1" ]; then
		local pid=`cat "$1"`

		/bin/kill -0 $pid >/dev/null 2>&1
		if [ "0" = "$?" ]; then
			echo "$pid";
			return 1;
		else
			echo "0";
			return 0;
		fi
	fi

	echo "0";
	return 0;
}

getpid() {
	pidnum=`is_daemon_alive $PIDFILE`
}

# Start syno gpo client
synogpoclientd_start() {
	Run=`/bin/get_key_value /etc/synoinfo.conf join_dsm_cms`
	Self=`/bin/get_key_value /etc/synoinfo.conf dsm_cms_self_join`
	Ready="/usr/syno/synoman/webapi/SYNO.CMS.lib"

	if [ "yes" != "$Run" ]; then
		echo "synogpoclientd: not join cms, need not start"
		return 1
	fi

	retry=5
	if [ "yes" = "$Self" ]; then
		while [ ! -f "$Ready" ] && [ $retry -gt 0 ];
		do
			echo "synogpoclientd: wait for self join ready"
			sleep 5;
			retry=`expr $retry - 1`
		done
	fi

	retry=5
	${EXEFILE}
	while [ $retry -gt 0 ] && [ "0" == `is_daemon_alive "$PIDFILE"` ];
	do
		sleep 1;
		retry=`expr $retry - 1`
	done

	if [ "0" == `is_daemon_alive "$PIDFILE"` ]; then
		echo "synogpoclientd start fail"
	else
		echo "synogpoclientd started"
	fi

}

# Stop syno gpo client
synogpoclientd_stop() {
	retry=30

	echo "synogpoclientd: try to stop"
	kill $pidnum

	while [ $retry -gt 0 ] && [ "0" != `is_daemon_alive "$PIDFILE"` ];
	do
		sleep 1;
		retry=`expr $retry - 1`
	done

	if [ "0" != `is_daemon_alive "$PIDFILE"` ] ; then
		kill -9 $pidnum
		echo "synogpoclientd still running, force kill"
	fi

	echo "synogpoclientd stopped"
	if [ -e "$PIDFILE" ] ; then
		rm "$PIDFILE"
	fi
}

case "$1" in
'start')
	getpid
	if [ "0" == "$pidnum" ] ; then
		synogpoclientd_start &
		RETVAL=0
	else
		echo "synogpoclientd is already running"
		RETVAL=1
	fi
	;;
'stop')
	getpid
	if [ "0" == "$pidnum" ] ; then
		echo "synogpoclientd is not running"
		RETVAL=1
	else
		synogpoclientd_stop
		RETVAL=0
	fi
	;;
'restart')
	getpid
	if [ "0" == "$pidnum" ] ; then
		echo "synogpoclientd is not running"
		synogpoclientd_start &
	else
		synogpoclientd_stop
		synogpoclientd_start &
	fi
	RETVAL=0
	;;
'status')
	getpid
	if [ "0" == "$pidnum" ] ; then
		echo "synogpoclientd is stopped"
		RETVAL=1
	else
		echo "synogpoclientd is running - Pid : $pidnum"
		RETVAL=0
	fi
	;;
*)
echo "Usage $0 { start | stop | restart | status }"
RETVAL=1
;;
esac
exit $RETVAL



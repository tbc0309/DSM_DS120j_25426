#!/bin/sh

EXEFILE="/usr/syno/sbin/synocacheclient"
PIDFILE="/var/run/synocmsclientd.pid"

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

# Start syno cache client
synocacheclient_start() {
	Run=`/bin/get_key_value /etc/synoinfo.conf join_dsm_cms`
	Self=`/bin/get_key_value /etc/synoinfo.conf dsm_cms_self_join`
	Ready="/usr/syno/synoman/webapi/SYNO.CMS.lib"

	if [ "yes" != "$Run" ]; then
		return 1
	fi

	retry=5
	if [ "yes" = "$Self" ]; then
		while [ ! -f "$Ready" ] && [ $retry -gt 0 ];
		do
			echo "start synocacheclient: wait for self join ready"
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
		echo "CMS cache client start fail"
	else
		echo "CMS cache client started"
	fi

}

# Stop syno cache client
synocacheclient_stop() {
	retry=30

	kill $pidnum

	while [ $retry -gt 0 ] && [ "0" != `is_daemon_alive "$PIDFILE"` ];
	do
		sleep 1;
		retry=`expr $retry - 1`
	done

	if [ "0" != `is_daemon_alive "$PIDFILE"` ] ; then
		kill -9 $pidnum
		echo "CMS cache client still running, force kill"
	fi

	echo "CMS cache client stopped"
	if [ -e "$PIDFILE" ] ; then
		rm "$PIDFILE"
	fi
}

case "$1" in
'start')
	getpid
	if [ "0" == "$pidnum" ] ; then
		synocacheclient_start &
		RETVAL=0
	else
		echo "CMS cache client is already running"
		RETVAL=1
	fi
	;;
'stop')
	getpid
	if [ "0" == "$pidnum" ] ; then
		echo "CMS cache client is not running"
		RETVAL=1
	else
		synocacheclient_stop
		RETVAL=0
	fi
	;;
'restart')
	getpid
	if [ "0" == "$pidnum" ] ; then
		echo "CMS cache client is not running"
		synocacheclient_start &
	else
		synocacheclient_stop
		synocacheclient_start &
	fi
	RETVAL=0
	;;
'status')
	getpid
	if [ "0" == "$pidnum" ] ; then
		echo "CMS cache client is stopped"
		RETVAL=1
	else
		echo "CMS cache client is running - Pid : $pidnum"
		RETVAL=0
	fi
	;;
*)
echo "Usage $0 { start | stop | restart | status }"
RETVAL=1
;;
esac
exit $RETVAL



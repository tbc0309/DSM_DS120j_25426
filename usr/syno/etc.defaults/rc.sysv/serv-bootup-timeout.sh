#!/bin/sh
# Copyright (c) 2000-2015 Synology Inc. All rights reserved.

PGUPGRADE_FLAG="/tmp/.UpgradePGSQLDatabase"

usage()
{
	cat << EOF
Usage: $(basename $0) [start]
EOF
}

start()
{
	# clean up to make sure no flag before we start check
	rm -rf /run/synoservice/bootup-ready-service/

	# Increase bootup timeout from 180 to 600 when pgsql is update database
	time=0
	while true; do
		if msg=`/usr/syno/sbin/synoservice --is-all-up`; then
			echo $msg
			logger -p user.err -t $(basename $0) "$msg"
			break;
		else
			echo $msg
		fi

		if [ -f "$PGUPGRADE_FLAG" -a "$time" -ge '600' ] || [ ! -f "$PGUPGRADE_FLAG" -a "$time" -ge '180' ]; then
			logger -p user.err -t $(basename $0) "Error! synoservices start timeout! ($msg)"
			break;
		fi
		sleep 3
		time=$(($time+3))
	done
	/usr/syno/sbin/synoservice --log-fail-service

	# Time out but pgsql still in upgrade operation, alert user
	if [ -f "$PGUPGRADE_FLAG" ]; then
		echo timeout > $PGUPGRADE_FLAG
		logger -p user.err -t `basename $0` "pgsql upgrade timeout."
		synodsmnotify @administrators dsmnotify:system_event widget:pgsql_upgrade_timeout
	fi
}

case "$1" in
	start) start;;
	*) usage >&2; exit 1;;
esac

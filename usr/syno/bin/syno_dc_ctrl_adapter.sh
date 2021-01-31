#!/bin/sh
# Copyright (c) 2003-2014 Synology Inc. All rights reserved.

# This is used for DC output scheduled tasks.


SERVICE_CTRL=/usr/syno/sbin/synoservicectl
SERVICE_NAME=dc-output

/usr/syno/sbin/synoservice --is-enabled $SERVICE_NAME
[ $? -eq 0 ] && exit 0

case "$1" in
	"on")
		$SERVICE_CTRL --start $SERVICE_NAME
		;;
	"off")
		$SERVICE_CTRL --stop $SERVICE_NAME
		;;
	"reset")
		$0 off
		sleep 3
		$0 on
		;;
esac

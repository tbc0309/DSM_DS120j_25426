#!/bin/sh

if [ -f "/var/run/dsmautoupdate.pid" ] || [ -f "/var/run/dsmautoupdate_prepare.pid" ]; then
	exit 1
fi

(flock -n 9 || exit 1) 9> /tmp/upgdsmlock
exit $?

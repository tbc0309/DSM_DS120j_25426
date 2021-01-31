#!/bin/sh

if [ -z "`/usr/syno/bin/synoiscsiwebapi lun list all | /bin/grep 'is_action_locked: true'`" ]; then
	exit
else
	exit 1
fi

#!/bin/sh

if [ -z "`/usr/syno/bin/synoiscsiwebapi target list "" all | /bin/grep 'status: connected'`" ]; then
	exit
else
	exit 1
fi

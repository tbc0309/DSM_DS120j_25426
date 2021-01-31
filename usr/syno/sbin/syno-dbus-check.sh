#!/bin/sh

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/syno/sbin:/usr/syno/bin
dbus_type=$1

if [ "session" != "$dbus_type" -a "system" != "$dbus_type" ]; then
	exit 1
fi

for i in $(seq 1 60)
do
	dbus-send --"$dbus_type" --type=method_call --print-reply --dest=org.freedesktop.DBus / org.freedesktop.DBus.Introspectable.Introspect
	if [ 0 = $? ]; then
		exit 0
	fi
	sleep 1
done

exit 1

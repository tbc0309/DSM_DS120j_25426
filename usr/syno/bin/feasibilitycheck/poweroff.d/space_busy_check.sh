#!/bin/sh

busy=$(/usr/syno/sbin/synostorage --is-space-busy)
if [ "yes" = "$busy" ]; then
	exit 1
fi

exit 0

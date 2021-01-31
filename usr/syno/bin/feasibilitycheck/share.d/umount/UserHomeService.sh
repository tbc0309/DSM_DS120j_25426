#!/bin/sh

Share=$1
EnableUserHome=`/bin/get_key_value /etc/synoinfo.conf userHomeEnable`

if [ "yes" = "${EnableUserHome}" -a "homes" = "${Share}" ]; then
	exit 1
fi

exit 0

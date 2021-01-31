#!/bin/sh

for item in `echo $MYDS_ABANDON_LIST | sed -n 1'p' | tr ',' '\n'`
do
    if [ "x$item" = "xddns" ] ; then
		echo "[ddns_unify] Disable DDNS Service" >> /var/log/messages
		/usr/syno/sbin/synoddnsinfo --set-record-disable Synology
		/usr/syno/etc/rc.d/S09DDNS.sh restart
		/usr/syno/bin/synosetkeyvalue /tmp/ddns.status Synology "-"
		/usr/syno/bin/synosetkeyvalue /tmp/ddns.lastupdated Synology "-"
	fi
done


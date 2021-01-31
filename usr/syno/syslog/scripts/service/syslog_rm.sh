#!/bin/sh
# Copyright (c) 2000-2014 Synology Inc. All rights reserved.

SYNO_FLAG_NO_LOG="/.nolog"

RemoveLog() {
	rm /var/log/synolog/.SYNOACCOUNTDB*
	rm /var/log/synolog/synobackup.log
	rm /var/log/synolog/synoconn.log
	rm /var/log/synolog/synoindex.log
	rm /var/log/synolog/synonetbkp.log
	rm /var/log/synolog/synobackup_server.log
	rm /var/log/synolog/synosys.log
	rm /usr/syno/etc/preference/admin/dsmnotify
}

if [ -f "${SYNO_FLAG_NO_LOG}" ]; then
	RemoveLog
	rm ${SYNO_FLAG_NO_LOG}
fi


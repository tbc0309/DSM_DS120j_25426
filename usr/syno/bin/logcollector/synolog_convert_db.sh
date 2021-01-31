#!/bin/bash
DEST="$1"
[ -d "${DEST}" ] || exit 1
mkdir -p "${DEST}/var/log/synolog/"
/usr/syno/sbin/synologconvert -o "${DEST}/var/log/synolog/synosys.log" /var/log/synolog/.SYNOSYSDB
/usr/syno/sbin/synologconvert -o "${DEST}/var/log/synolog/synoconn.log" /var/log/synolog/.SYNOCONNDB
exit 0

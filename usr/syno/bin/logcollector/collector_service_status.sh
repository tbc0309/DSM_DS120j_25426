#!/bin/sh

SZD_TMP=$1
# for service info
mkdir -p "$SZD_TMP"/result
/usr/syno/sbin/synoservice --status > "$SZD_TMP"/result/syno_service.result 2>&1

exit 0

#!/bin/sh

SZD_TMP=$1
mkdir -p "$SZD_TMP"/result/
/usr/sbin/ntpq -pn > "$SZD_TMP"/result/ntpq.result 2>&1

exit 0

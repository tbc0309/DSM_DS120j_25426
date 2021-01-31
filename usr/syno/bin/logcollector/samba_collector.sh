#!/bin/sh

SZD_TMP=$1
# for samba related info
mkdir -p "$SZD_TMP"/result
/usr/bin/smbstatus -v > "$SZD_TMP"/result/smbstatus.result 2>&1
/usr/syno/bin/domain_test.sh -a > "$SZD_TMP"/result/domain_test.result 2>&1

exit 0

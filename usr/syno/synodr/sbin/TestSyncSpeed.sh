#!/bin/sh
# Copyright (c) 2000-2015 Synology Inc. All rights reserved.

C_DD=/bin/dd
C_MKDIR=/bin/mkdir
C_MV=/bin/mv

TEMPPATH=/tmp
TESTDIR=/usr/syno/synoman/webman/modules/synodr
TESTFILE=10M

setup() {
	$C_DD if=/dev/zero of="$TEMPPATH/$TESTFILE" bs=1M count=10 &> /dev/null || exit 1
	$C_MKDIR -p $TESTDIR || exit 2
	$C_MV "$TEMPPATH/$TESTFILE" $TESTDIR &>/dev/null || exit 3
	echo -n $TESTFILE
}

if [ $# -ne 1 ]; then
	echo "argument number should be 1"
	exit 254
fi

CMD=$1

case $CMD in
	"setup")
		setup
		;;
	*)
		echo "Command not found."
		exit 254
		;;
esac

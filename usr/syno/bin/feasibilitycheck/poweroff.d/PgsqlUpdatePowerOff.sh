#!/bin/sh

PGUPGRADE_FLAG="/tmp/.UpgradePGSQLDatabase"

if [ -f $PGUPGRADE_FLAG ]; then
	exit 1
fi
exit 0

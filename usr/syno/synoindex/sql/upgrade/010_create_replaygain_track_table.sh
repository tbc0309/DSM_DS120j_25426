#!/bin/sh
# Copyright (c) 2000-2014 Synology Inc. All rights reserved.

. $(dirname "$0")/lib/common.sh

TABLE="replaygain_track"

TestTable $TABLE
Ret=$?

if [ $Ret = 1 ]; then
	echo "Create $TABLE table in $DATABASE DB"
	Script="$UPGRADE_DIR/010_create_replaygain_track_table.pgsql"

	ImportSqlScript "$Script"
	if [ $? != 0 ]; then
		echo "Failed to create $TABLE table in $DATABASE DB"
		exit 2 # error
	fi

	exit 10 # 10: need reindex music, 1: need reindex all
fi

exit 0 # no modification

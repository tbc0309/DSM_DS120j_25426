#!/bin/sh
# Copyright (c) 2000-2014 Synology Inc. All rights reserved.

. "$(dirname "$0")/lib/common.sh"

TABLE="voice_search"

TestTable $TABLE
Ret=$?

if [ $Ret = 1 ]; then
	echo "Add $TABLE table in $DATABASE DB"
	Script="$UPGRADE_DIR/011_create_voice_search_table.pgsql"

	ImportSqlScript "$Script"
	Ret=$?
	if [ $Ret -ne 0 ]; then
		echo "Failed to add $TABLE table in $DATABASE DB"
		exit 2 # error
	fi

	exit 10 # 10: need reindex music, 1: need reindex all
fi

exit 0 # no modification

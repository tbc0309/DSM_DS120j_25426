#!/bin/sh
# Copyright (c) 2000-2014 Synology Inc. All rights reserved.

PSQL="/usr/bin/psql"

ExecSqlCommand()
{
	$PSQL -U postgres mediaserver -c "$1" > /dev/null 2>&1
}

DATABASE="mediaserver"
TABLE="personal_directory"
UPGRADE_DIR="/usr/syno/synoindex/sql/upgrade"

echo "test $TABLE table in $DATABASE DB"
ExecSqlCommand "SELECT * FROM $TABLE LIMIT 1"
Ret=$?
if [ $Ret = 1 ]; then
	echo "Create personal library tables in $DATABASE DB"
	Script="$UPGRADE_DIR/008_create_personal_library_tables.pgsql"
	$PSQL -U postgres $DATABASE < $Script
	if [ $? != 0 ]; then
		echo "Failed to create personal library tables in $DATABASE DB"
		exit 2 # error
	fi

	exit 10 # 10: need reindex music, 1: need reindex all
fi

exit 0 # no modification

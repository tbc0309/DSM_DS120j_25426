#!/bin/sh
# Copyright (c) 2000-2014 Synology Inc. All rights reserved.

PSQL="/usr/bin/psql"
DATABASE="mediaserver"
UPGRADE_DIR="/usr/syno/synoindex/sql/upgrade"

ExecSqlCommand()
{
	$PSQL -U postgres $DATABASE -c "$1" > /dev/null 2>&1
}

ImportSqlScript()
{
	$PSQL -U postgres $DATABASE < "$1"
}

# Test column. Return 0 if the column exists.
# $1 table name
# $2 column name
TestColumn()
{
	echo "test $2 in $1 table in $DATABASE DB"
	ExecSqlCommand "SELECT $2 FROM $1 LIMIT 1"
	return $?
}

# Test table. Return 0 if the table exists.
# $1 table name
TestTable()
{
	echo "test $1 table in $DATABASE DB"
	ExecSqlCommand "SELECT * FROM $1 LIMIT 1"
	return $?
}

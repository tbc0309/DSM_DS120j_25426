#!/bin/sh
# Copyright (c) 2003-2013 Synology Inc. All rights reserved.

SYNOINFO_CONF="/etc/synoinfo.conf"
PSQL="/usr/bin/psql"
CREATEDB="/usr/bin/createdb"
CREATEUSER="/usr/bin/createuser"
SYNOPSQL="/usr/syno/bin/synopsql"
DATABASE="mediaserver"
DB_ADMIN="postgres"
DB_USER="MediaIndex"

syslog() {
    local ret=$?
    logger -p user.err -t $(basename $0) "$@"
    return $ret
}

create_db_user() {
	local user_exists=`$PSQL -U $DB_ADMIN -At  -c "SELECT count(1) FROM pg_roles WHERE rolname='$DB_USER'"`

	if [ "$user_exists" = "0" ]; then
		echo "Create pgsql user $DB_USER"
		$CREATEUSER -U $DB_ADMIN $DB_USER
	fi
}

change_owner() {
	echo "Change $DATABASE owner to $DB_USER"
	$SYNOPSQL --change-own "$DATABASE" "$DB_USER"
}

check_db_owner() {
	local wrong_owner_count=`$PSQL -U $DB_ADMIN -qAt $DATABASE -c "SELECT count(1) FROM pg_tables WHERE schemaname='public' AND tableowner != '$DB_USER'"`

	if [ "$wrong_owner_count" != "0" ]; then
		change_owner
	fi
}

case $1 in
"start")
	NeedReindex=0
	ReindexMusicOnly=0

	create_db_user

	$PSQL -U $DB_ADMIN $DATABASE -c "select 1 from music limit 1" > /dev/null 2>&1
	Ret=$?
	if [ $Ret = 2 ]; then
		echo "Create database: $DATABASE, owner: $DB_USER"
		$CREATEDB -U $DB_ADMIN $DATABASE
		if [ $? != 0 ]; then
			echo "Failed to create database"
			exit
		fi
		Script="/usr/syno/synoindex/sql/mediaserver.pgsql"
		Ret=1
	fi

	if [ $Ret = 1 ]; then
		$PSQL -U $DB_ADMIN $DATABASE < $Script
		if [ $? != 0 ]; then
			echo "Failed to initial media database"
			exit
		fi

		NeedReindex=1
	fi

	upgrades=`find /usr/syno/synoindex/sql/upgrade -maxdepth 1 -name "*.sh" | sort`
	for ThisArg in $upgrades;
	do
		$ThisArg
		Ret=$?
		if [ $Ret = 1 ]; then
			NeedReindex=1
		fi

		if [ "$Ret" = "10" ]; then
			NeedReindex=1
			ReindexMusicOnly=1
		fi
	done

	if [ $NeedReindex = 1 ]; then
		# run change owner to ensure owner of db, tables, sequences, views are DB_USER
		change_owner

		if [ $ReindexMusicOnly = 1 ]; then
			cmd="/usr/syno/bin/synoindex -R type_music -P MediaIndex"
		else
			cmd="/usr/syno/bin/synoindex -R media -P MediaIndex"
		fi

		`$cmd`

		message="Re-index triggered, cmd [$cmd]"
		syslog "$message"
		echo "$message"
	fi

	# check db owner is changed (for upgrade case)
	check_db_owner

	;;
*)
	echo "Usage: $0 start"
	;;
esac

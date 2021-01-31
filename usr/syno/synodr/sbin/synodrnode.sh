#!/bin/sh

NODE_ETC="/usr/syno/etc/synodr/"
NODE_ETC_DEFAULTS="/usr/syno/etc.defaults/synodr/"
NODE_DB=${NODE_ETC}"/node.db"
NODE_SQL_ROOT=${NODE_ETC_DEFAULTS}"/node_sql"
SYNODRCRED="/usr/syno/synodr/sbin/synodrcred"
INIT_SQL=${NODE_SQL_ROOT}"/init_db.sql"
INIT_TEMPCRED_SQL=${NODE_SQL_ROOT}"/init_temp_cred.sql"
V2_SQL=${NODE_SQL_ROOT}"/v2.sql"
DB_VER="2";

init_db()
{
	if [ ! -f ${INIT_SQL} ]; then
		logger -p user.info -t synodrnode "Failed to init synodrnode.db since ${INIT_SQL} is not existed"
	else
		sqlite3 ${NODE_DB} < ${INIT_SQL}
		logger -p user.info -t synodrnode "Init synodrnode.db done"
	fi
}

exec_db()
{
	local db_file=$1

	if [ ! -f $db_file ]; then
		logger -p user.err -t synodrnode "${db_file} is not existed to exec";
		exit 1;
	fi
	sqlite3 ${NODE_DB} < ${db_file}
}

upgrade_db()
{
	while true
	do
		local ver=`sqlite3 ${NODE_DB} "SELECT value FROM db_ver;"`;

		case ${ver} in
			1)
				exec_db ${V2_SQL}
				;;
			$DB_VER)
				break
				;;
			*)
				logger -p user.warn -t synodrnode "Failed to upgrade db since bad ver [${ver}]"
				break
				;;
		esac
		logger -p user.warn -t synodrnode "Upgrade ${NODE_DB} to ver[$(($ver+1))]"
	done
}

clear_temp_cred()
{
	if [ -f ${INIT_TEMPCRED_SQL} ]; then
		sqlite3 ${NODE_DB} < ${INIT_TEMPCRED_SQL}
		logger -p user.warn -t synodrnode "Clear temp credential of DRNode"
	fi
}

start()
{
	logger -p user.info -t synodrnode " ---> Start DRNode Check"

	if [ ! -f "${NODE_DB}" ]; then
		init_db
	else
		local existed=`sqlite3 ${NODE_DB} "SELECT 1 FROM sqlite_master WHERE type='table' AND name='db_ver';"`

		if [ -z "$existed" ]; then
			init_db
		else
			local ver=`sqlite3 ${NODE_DB} "SELECT value FROM db_ver;"`;
			if [ -z "$ver" ]; then
				init_db
			else
				upgrade_db
			fi
		fi

	fi

	clear_temp_cred

	logger -p user.info -t synodrnode " <--- Finish DRNode Check"
	/sbin/initctl emit --no-wait syno.drnode.ready
}

case "$1" in
start)
	start
;;
*)
	echo "usage: $0 [start]" >&2
	exit 1
;;
esac

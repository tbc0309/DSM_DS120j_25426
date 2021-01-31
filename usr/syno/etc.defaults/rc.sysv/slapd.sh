#!/bin/sh
#set -x
VERSION=2

PIDOF=/bin/pidof
ECHO=/bin/echo
CAT=/bin/cat
SLEEP=/bin/sleep
LOGGER=/usr/bin/logger
DB_RECOVER=/usr/bin/db_recover
LDAPSEARCH=/usr/bin/ldapsearch
SLAPD=/usr/sbin/slapd

pidfiledir=/var/run
NEWLDAP_ROOT=/var/packages/DirectoryServer/target
NEWDBDIR=$NEWLDAP_ROOT/etc/data
NEWLDAP_BDB=$NEWDBDIR/bdb
NEWLDAP_CONFDB=$NEWDBDIR/slapd.d

TestCanConnect() {
	local i=0
	while [ $i -lt 5 ] ; do
		$LDAPSEARCH -LLLxh 0 -b '' -s base > /dev/null 2>&1
		if [ $? -ne 255 ]; then
			return 0
		fi
		$SLEEP 1
		i=`expr $i + 1`
	done
	return 1
}

CheckPidExist()
{
	if [ -f "$1" ]; then
		Pid=`$CAT "$1"`
		if [ -n "$Pid" -a -d "/proc/$Pid" ]; then
			return 0
		fi
	fi
	return 1
}

case "$1" in
	start|'')
		if ! CheckPidExist $pidfiledir/slapd.pid && [ -x $SLAPD ]; then
			$ECHO "#################"
			$ECHO ' Starting Slapd'
			$ECHO "#################"

			/usr/bin/slapindex -F $NEWLDAP_CONFDB
			/sbin/initctl start slapd   #FIXME
			if ! TestCanConnect ; then
				/sbin/initctl stop slapd   #FIXME
				if [ -x $DB_RECOVER ] && ! pidof slapd > /dev/null 2>&1 ; then
					$LOGGER -p user.err -t `basename $0` "start slapd failed. try to db_recover."
					$DB_RECOVER -h $NEWLDAP_BDB
					$ECHO "start go restart"
					/sbin/initctl start slapd
				else
					$LOGGER -p user.err -t `basename $0` "db_recover not exists or slapd unexpected exists."
				fi
			fi

			# Create default ppolicy entry.
			/var/packages/DirectoryServer/target/tool/synoldapbrowser --migrate-olc-config
			/var/packages/DirectoryServer/target/tool/synoldapbrowser --support-overlay
		fi
	;;
	stop)
		$ECHO
		$ECHO "#################"
		$ECHO ' Stoping Slapd'
		$ECHO "#################"
		/sbin/initctl stop slapd   #FIXME
		;;
	restart)
		$0 stop
		$0 start
		;;
	reload)
		/sbin/initctl reload slapd
		;;
	status)
		/usr/syno/sbin/synoservicectl --status slapd
		exit $?
		;;
esac

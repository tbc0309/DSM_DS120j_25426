#!/bin/bash
# Copyright (c) 2000-2012 Synology Inc. All rights reserved.

init_env() {
	PATH="/usr/bin:/bin"
	PATH_LOG="/var/log"
	DOMAIN_DB_VERSION=6

	SZD_PID="/run/samba"
	if [ -e $SZD_PID -a ! -d $SZD_PID ]; then
		rm -f "$SZD_PID"
	fi
	if ! [ -e $SZD_PID ]; then
		mkdir -p "$SZD_PID"
	fi
}
init_lsb_status() { # void
	# XXX these defined in /etc/rc.subr just include to reference

	# According to LSB 3.1 (ISO/IEC 23360:2006), the `status` init-scripts
	# action should return the following exit status codes.
	#
	LSB_STAT_RUNNING=0      # program is running or service is OK
	LSB_STAT_DEAD_FPID=1    # program is dead and /var/run pid file exists
	LSB_STAT_DEAD_FLOCK=2   # program is dead and /var/lock lock file exists
	LSB_STAT_NOT_RUNNING=3  # program is not runnning
	LSB_STAT_UNKNOWN=4      # program or service status is unknown
	# 5-99                  # reserved for future LSB use
	# 100-149               # reserved for distribution use
	# 150-199               # reserved for application use
	# 200-254               # reserved

	# Non-status init-scripts actions should return an exit status of zero if
	# the action was successful. Otherwise, the exit status shall be non-zero.
	#
	LSB_SUCCESS=0           # successful
	LSB_ERR_GENERIC=1       # generic or unspecified error
	LSB_ERR_ARGS=2          # invalid or excess argument(s)
	LSB_ERR_UNIMPLEMENTED=3 # unimplemented feature (for example, `reload`)
	LSB_ERR_PERM=4          # user had insufficient privilege
	LSB_ERR_INSTALLED=5     # program is not installed
	LSB_ERR_CONFIGURED=6    # program is not configured
	LSB_NOT_RUNNING=7       # program is not running
	# 8-99                  # reserved for future LSB use
	# 100-149               # reserved for distribution use
	# 150-199               # reserved for application use
	# 200-254               # reserved
}
source /etc/rc.subr || init_lsb_status

set_smbd_affinity() {
	uname -a | grep -i "qoriq\|evansport\|comcerto2k\|armada375\|monaco" > /dev/null 2>&1
	local support_smb_affinity="$?"

	if [ 0 -eq ${support_smb_affinity} ]; then
		for each_pid in `pidof smbd`; do
			/usr/bin/taskset -p 2 $each_pid > /dev/null 2>&1
		done
	fi
}

# util functions
syslog() { # logger args
	local ret=$?
	logger -p user.err -t $(basename $0)\($$\) "$@"
	return $ret
}
message() { # echo args
	local ret=$?
	echo "$@"
	return $ret
} >&2
warn() { # echo args
	local ret=$?
	local H="[33m" E="[0m"
	echo -en "$H$@" ; echo "$E"
	return $ret
} >&2

is_alive() { # <pid> [proc name]
	local pid=${1:?"error params"}
	local procname="$2"

	if [ ! -r "/proc" -o -z "${procname:-}" ]; then
		kill -0 "$pid" 2>/dev/null
	else
		bin_file=`readlink "/proc/$pid/exe"`
		[ x"$(basename "$bin_file")" = x"$procname" ]
	fi
}
is_any_running() {
	local i=
	for i in "$@"; do
		if pidof $i >/dev/null; then
			return 0
		fi
	done
	return 1
}

is_ad_mode(){
	local ROLE=`/usr/syno/bin/synogetkeyvalue /etc/samba/smb.conf "server role"`

	if [ -f "/run/samba/synoadserver" ]; then
		return 0;
	fi
	if [ "active directory domain controller" = "${ROLE,,}" ]; then
		return 0;
	fi
	return 1;
}

check_enum_db_migrate() {
	# check enum DB
	if [ ! -f /usr/syno/etc/private/.db.domain_user ]; then
		return 0;
	fi
	local DBVERSION=$(/bin/sqlite3 /usr/syno/etc/private/.db.domain_user "SELECT Version FROM dominfo LIMIT 1;" 2> /dev/null)
	if [ "$DBVERSION" != "$DOMAIN_DB_VERSION" ]; then
		#db version not match. need to delete old db for rebuild all
		unlink_domain_db
		return 0
	fi
	return 1
}
unlink_domain_db() {
	for LINK in `ls /usr/syno/etc/private/.db.domain_*_full.*`
	do
		local FILE=""
		if [ -h "$LINK" ]; then
			FILE=`readlink $LINK`
			rm "$LINK"
		fi
		if [ -e "$FILE" ]; then
			rm "$FILE"
		fi
	done
	rm -f /usr/syno/etc/private/.db.domain_group /usr/syno/etc/private/.db.domain_user
}
check_full_db_migrate() {
	if [ -f '/tmp/domain_user.pid' -o -f '/tmp/domain_group.pid' ]; then
		return 0
	fi

	local SECURITY=`/usr/syno/bin/synogetkeyvalue /etc/samba/smb.conf security`
	if [ "$SECURITY" = "domain" ]; then
		#not AD domain. Don't need to build full db
		return 1;
	elif [ "$SECURITY" = "" ]; then
		local SERVERROLE=`/usr/syno/bin/synogetkeyvalue /etc/samba/smb.conf "server role"`
		if ! is_ad_mode; then
			#not AD server, maybe something wrong
			return 1
		fi
	fi
	local NT4ENUM=`/usr/syno/bin/synogetkeyvalue /etc/samba/smbinfo.conf "enable nt4 enum"`
	if [ "$NT4ENUM" = "yes" ]; then
		#enable nt4 enum; don't need to build full db
		return 1
	fi

	local first_vol=`get_first_volume`
	if [ "$first_vol" = "/var/lib/samba" ]; then
		#no volume no full db
		return 1
	fi
	/bin/ls /usr/syno/etc/private/.db.domain_*_full.* > /dev/null 2>&1
	if [ $? -ne 0 ]; then
		#not found full db. need to build full db
		return 0
	fi

	local FILES=`/bin/ls /usr/syno/etc/private/.db.domain_*_full.*`
	for FILE in $FILES; do
		local DBVERSION=$(/bin/sqlite3 ${FILE} "SELECT Version FROM dominfo;" 2>/dev/null)
		if [ "$DBVERSION" != "$DOMAIN_DB_VERSION" ]; then
			#db version not match. need to delete old db for rebuild full db
			unlink_domain_db
			return 0
		fi
	done
	return 1
}

# return 0: need to update domain db
# return others: no need to update
check_domain_migrate() {
	#DSM 4.2 -> 4.3 migrate domain user/group related data base
	if [ ! -e /usr/syno/etc/private/.db.domain_user -o ! -e /usr/syno/etc/private/.db.domain_group ]; then
		return 0
	fi
	# BUG#92556 no need to rebuild with NT4 enum or in NT4 domain
	#DSM 5.2 --> 6.0 add domain user/group full db
	check_full_db_migrate
	if [ $? = 0 ]; then
		return 0;
	fi

	#check old db here
	check_enum_db_migrate
	return $?
}
proc_ppid() {
	local pid=$1;
	local ppid="";
	if [ -z $pid ]; then
		pid=$$;
	fi
	if [ -f "/proc/$pid/status" ]; then
		echo `grep "PPid" /proc/$pid/status | cut -d: -f2`
	else
		return 1;
	fi
}
proc_info() { # <proc name> [pid file]
	local procname=${1:?"error params"}
	local pidfile=${2:-"$SZD_PID/$procname.pid"}

	local pid= running= i=
	if [ -r "$pidfile" ]; then
		pid=`cat "$pidfile"`
		if is_alive "$pid" "$procname"; then
			running="R"
		fi
	fi
	if pidof "$procname" >/dev/null; then
		running=${running:-"?"}
	else
		running="-"
	fi

	if [ ! "$_proc_info_header_dumped" ]; then
		printf "%-15s %-7s %4s  other pids\n" "procname" "pidfile" "stat"
		_proc_info_header_dumped=y
	fi

	printf "%-15s %-7s %4s  " "$procname" "$pid" "$running"
	for i in `pidof "$procname"`; do
		[ "$i" -eq "$pid" ] && continue

		echo -n "$i("`proc_ppid "$i"`") "
	done
	echo ""
}
proc_stop() {
	local procname=${1:?"error params"}
	local pidfile=${2:-"$SZD_PID/$procname.pid"}

	message -n "stop $procname ... "

	if ! pidof "$procname" >/dev/null; then
		message "not running"
		return ${LSB_NOT_RUNNING:-7}
	fi

	if ! [ -f "$pidfile" ]; then
		warn "no pid file, but process exist"
	fi
	/sbin/stop $procname
}
proc_wait_stop() {
	local procname=${1:?"error params"}
	local retry=10
	local d1=`date +%s`

	while [ $retry -gt 0 ] && pidof "$procname" >/dev/null; do
		sleep 1
		retry=$((retry-1))
	done

	local d2=`date +%s`

	if pidof "$procname" >/dev/null; then
		killall -9 "$procname"
		warn "$procname still running, wait $((d2 - d1)) sec, force kill"
	else
		message "$procname stoped ($((d2 - d1)) sec)"
	fi
}
proc_signal() { # <signal> <proc name>
	local sig=${1:?"error params"}
	local procname=${2:?"error params"}
	local pidfile=${3:-"$SZD_PID/$procname.pid"}

	if [ -f "$pidfile" ]; then
		local pid=`cat "$pidfile"`
		if ! kill -$sig $pid; then
			warn "dead pid file"
		fi
	fi
}
get_first_volume()
{
	local VPATH=""
	VPATH=`/usr/syno/bin/servicetool --get-alive-volume-for-winbindd`
	if [ "$?" = "0" ]; then
		VPATH="/var/lib/samba"
	fi
	echo $VPATH
}

# lsb util functions
lsb_status() { # <proc name> [pid file]
	local procname=${1:?"error params"}
	local pidfile=${2:-"$SZD_PID/$procname.pid"}

	if [ -f "$pidfile" ]; then
		local pid=`cat "$pidfile"`
		if is_alive "$pid" "$procname"; then
			printf "%-15s %s\n" "$procname:" running
			return ${LSB_STAT_RUNNING:-0}
		else
			warn "dead pid file: $pidfile"
			printf "%-15s %s\n" "$procname:" stopped
			return ${LSB_STAT_DEAD_FPID:-1}
		fi
	fi

	printf "%-15s %s\n" "$procname:" stopped
	return ${LSB_STAT_NOT_RUNNING:-3}
}

file_size() {
	local File="$1"
	local size=0
	if [ -f "$1" ]; then
		size=`/usr/syno/bin/synoacltool -stat $File | grep "File size:" | awk '{ print $3;}'`
	fi
	echo $size
}

ARRAY_INSTALL_PATH=(
"/var/cache/samba" "755"   #no this directory will let smbd start fail
"/var/log/samba" "755"     #no this directory will let smbd log to stdout
"/etc/samba/private" "755" #no this directory will open/create secrets.tdb fail and force smb_panic
)
install_dir_recover() {
	local count=0
	while [ ! -z "${ARRAY_INSTALL_PATH[$count]}" ];
	do
		local dir_path="${ARRAY_INSTALL_PATH[$count]}"
		local mode="${ARRAY_INSTALL_PATH[$(($count+1))]}"
		if [ ! -d "$dir_path" ]; then
			syslog "$dir_path not exist. create it."
			/bin/mkdir -p "$dir_path"
			/bin/chmod "$mode" "$dir_path"
		fi
		count=$(($count+2))
	done
}

# below path will create by smbd/nmbd/winbindd. But if dir exist with wrong perm, the daemon will start fail.
ARRAY_PERM_PATH=(
"/run/samba/ncalrpc/np" "700"
"/run/samba/ncalrpc" "755"
"/run/samba/msg.lock" "755"
"/run/samba/msg.sock" "700"
"/run/samba/winbindd" "755"
"/run/samba/nmbd" "755"
"/var/lib/samba/winbindd_privileged" "750"
)
perm_recover() {
	local count=0
	while [ ! -z "${ARRAY_PERM_PATH[$count]}" ];
	do
		local target_path="${ARRAY_PERM_PATH[$count]}"
		local mode="${ARRAY_PERM_PATH[$(($count+1))]}"
		if [ -e "$target_path" ]; then
			local st_mode=`/usr/syno/bin/synoacltool -stat "$target_path" | grep Mode | awk '{print $2;}'`
			st_mode=$(($st_mode%1000))
			if [ "$st_mode" != "$mode" ]; then
				syslog "$dir_path wrong mode $st_mode. correct to $mode."
				/bin/chmod $mode $target_path
			fi
		fi
		count=$(($count+2))
	done
}

samba_file_dir_check() {
	# install path check and recover
	install_dir_recover

	# samba create path check permission
	perm_recover

	#check smb.conf
	local smbconfsize=`file_size /etc/samba/smb.conf`
	if [ "$smbconfsize" = 0 ]; then
		syslog "/etc/samba/smb.conf is empty or not exist. Recover by /etc.defaults/samba/smb.conf"
		/bin/mv /etc/samba/smb.conf /etc/samba/smb.conf.bad > /dev/null 2>&1
		/bin/cp -f /etc.defaults/samba/smb.conf /etc/samba/smb.conf
	fi
}

# smb util functions
smb_is_enabled() { # <void>
	/usr/syno/sbin/synoservice --is-enable samba > /dev/null
	[ $? = 1 ]
}
smb_remove_share_tdbs() {
	# those tdb will be used by nmbd, smbd, winbindd
	rm -f /run/samba/messages.tdb /run/samba/serverid.tdb
}
smb_remove_smbd_temp_tdbs() {
	rm -f /run/samba/brlock.tdb /run/samba/connections.tdb \
		/run/samba/login_cache.tdb "/var/cache/samba/printing/*.tdb" \
		/run/samba/sessionid.tdb /run/samba/locking.tdb \
		/run/samba/unexpected.tdb /run/samba/deferred_open.tdb \
		/var/cache/samba/notify_onelevel.tdb
}
smb_remove_winbindd_temp_tdbs() {
	#We default enable winbindd offline logon
	#so we cannot remove winbindd_cache.tdb when restart winbindd.
	#The netsamlogon_cache.tdb may be cannot be delete for auth.
	#But netsamlogon_cache.tdb has too much cache issue.

	local cache_size=0
	if [ ! -f /var/lib/samba/winbindd_cache.tdb ]; then
		return
	fi

	#winbind_cache.tdb too large will cause the winbindd check very long time
	#If size > 200MB(200*1024*1024 = 209715200 Byte), we need delete it to keep performance
	cache_size=`file_size /var/lib/samba/winbindd_cache.tdb`
	if [ "$cache_size" != "" -a "$cache_size" -gt 209715200 ]; then
		#when cache size too large, we should clear it before starting winbindd
		rm -f `/usr/bin/realpath /var/lib/samba/winbindd_cache.tdb`
	fi
	rm -f /var/cache/samba/winbindd_cache.tdb* /var/lib/samba/winbindd_cache.tdb*
}
smb_remove_smbd_winbindd_share_tdbs() {
	if is_any_running smbd winbindd; then
		return 1
	fi
	rm -f /var/cache/samba/netsamlogon_cache.tdb /run/samba/gencache_notrans.tdb \
		  /run/samba/gencache.tdb /var/lib/samba/group_mapping.tdb
}
smb_remove_temp_tdbs() { # <void>
	if is_any_running smbd nmbd winbindd; then
		return 1
	fi

	message "remove temp tdbs"

	smb_remove_smbd_temp_tdbs
	smb_remove_winbindd_temp_tdbs
	smb_remove_smbd_winbindd_share_tdbs
	smb_remove_share_tdbs
}
smb_check_tdb() { # <tdb file>
	local tdbfile=${1:?"error param"}
	local backup=/usr/bin/tdbbackup

	message -n "check tdb: $tdbfile ... "

	if [ -f "$tdbfile" ]; then
		if $backup -v "$tdbfile" >/dev/null 2>&1; then
			# tdb is good make another backup
			mv -f "$tdbfile.bkp" "$tdbfile.bkp.old"
			if $backup -s ".bkp" "$tdbfile" >/dev/null 2>&1; then
				message "done"
				rm -f "$tdbfile.bkp.old"
			else
				warn "backup failed"
				mv -f "$tdbfile.bkp.old" "$tdbfile.bkp"
			fi
		elif [ -f "$tdbfile.bkp" ]; then
			warn "corrupt, restore"
			if ! $backup -v -s ".bkp" "$tdbfile" >/dev/null; then
				warn "restore failed, remove it"
				rm -f "$tdbfile"
			fi
		else
			warn "corrupt, remove it"
			rm -f "$tdbfile"
		fi
	elif [ -f "$tdbfile.bkp" ];then
		warn "lost, use backup tdb"
		if ! $backup -v -s ".bkp" "$tdbfile" > /dev/null; then
			warn "restore failed"
		fi
	else
		message "not exist"
	fi

	return 0
}

smb_prestart_smbd() {
	local smbspool=/var/spool/samba i=
	local printer_tdbs="ntprinters.tdb ntforms.tdb ntdrivers.tdb"

	# FIXME remove smbspool
	[ -d "$smbspool" ] && rm -f "$smbspool/*"

	# check private dir
	smb_check_tdb /etc/samba/private/secrets.tdb

	# check smb tdb
	for i in account_policy.tdb share_info.tdb registry.tdb; do
		smb_check_tdb /var/lib/samba/$i
	done

	samba_file_dir_check
}

smb_poststart_smbd() {
	{
	/bin/sleep 1
	set_smbd_affinity
} &
}

smb_poststop_smbd() {
	local retry=10
	while [ $retry -gt 0 ] && pidof "smbd" >/dev/null; do
		sleep 1
		retry=$((retry-1))
	done
	smb_remove_smbd_temp_tdbs
	smb_remove_smbd_winbindd_share_tdbs
	proc_wait_stop smbd
}

smb_prestart_nmbd() {
	/usr/syno/bin/synobootseq --is-ready >/dev/null 2>&1
	if [ "$?" != "0" ]; then
		/usr/syno/sbin/synowin -checkwins
	fi
	samba_file_dir_check
}

check_winbindd_valid() {
	local winbindcache="$1"
	if ! [ -e /usr/syno/etc/private/.db.domain_user -o -e /usr/syno/etc/private/.db.domain_group ]; then
		#no user/group db means joining new domain --> remove old winbindd_cache.tdb
		return 1
	fi
	# check winbindd_cache.tdb VERSION key
	/usr/bin/tdbtool $winbindcache keys | grep WINBINDD_CACHE_VERSION > /dev/null 2>&1
	if [ "$?" != "0" ]; then
		return 1
	fi

	# winbindd_cache.tdb integrity check
	/usr/bin/tdbtool $winbindcache check | grep "failed" > /dev/null 2>&1
	if [ "$?" = "0" ]; then
		return 1
	fi
	return 0
}
smb_prestart_winbindd() {
	smb_check_tdb /var/lib/samba/winbindd_idmap.tdb
	samba_file_dir_check
	local szd_volume=`get_first_volume`
	if [ "x$szd_volume" != "x" ]; then
		local winbindcache="$szd_volume/winbindd_cache.tdb"

		check_winbindd_valid "$winbindcache"
		if [ "$?" != "0" ]; then
			rm -f "$winbindcache"
		fi

		touch "$winbindcache"
		#samba3 winbindd_cache use cache_dir
		ln -s "$winbindcache" /var/cache/samba/winbindd_cache.tdb
		#samba4 winbindd_cache use stat_dir
		ln -s "$winbindcache" /var/lib/samba/winbindd_cache.tdb
	fi
	check_domain_migrate
	if [ $? -eq 0 ]; then
		touch "/tmp/domain_updating"
	fi
}

build_domain_db_retry() {
	# this function will run at background
	# don't echo / print to stdout or stderr.
	# Or it will cause the bash error when service framework run it
	local count=1
	#wait winbindd ready
	if ! is_ad_mode; then
		/bin/sleep 5
	fi
	while [ $count -le 5 ]; do
		/bin/ps -C synowin -o %a | grep updateDomain > /dev/null 2>&1
		if [ $? -ne 0 ] ; then
			/usr/syno/sbin/synowin -updateDomain 2>&1 > /dev/null
		fi
		#wait for building the domain user/group db
		while pidof synowin > /dev/null 2>&1 ; do
			sleep 1;
		done
		check_domain_migrate
		if [ $? -ne 0 ]; then
			# build success; break to rm domain_updating flag
			break
		fi
		count=$(($count+1))
		# genchache.tdb negative timeout is 60s
		/bin/sleep 60
	done
	if [ -e "/tmp/domain_updating" ]; then
		rm "/tmp/domain_updating"
	fi
	return
}

smb_poststart_winbindd() {
	check_domain_migrate
	if [ $? -eq 0 ]; then
		if /bin/ps -C synowin -o %a | grep updateDomain > /dev/null 2>&1; then
			#synowin is building skip this action
			echo "synowin is building"
			return
		fi
		build_domain_db_retry &
		return
	fi
	if [ -e "/tmp/domain_updating" ]; then
		rm "/tmp/domain_updating"
	fi

}

smb_poststop_winbindd() {
	local retry=10
	while [ $retry -gt 0 ] && pidof "winbindd" >/dev/null; do
		sleep 1
		retry=$((retry-1))
	done
	smb_remove_winbindd_temp_tdbs
	smb_remove_smbd_winbindd_share_tdbs
	proc_wait_stop winbindd
	rm -f /run/samba/winbind_domain_list*
}

smb_start_nmbd() {
	message -n "start nmbd ... "

	if pidof nmbd >/dev/null; then
		warn "nmbd is running: `pidof nmbd`"
		return 1
	fi

	if /sbin/start nmbd > /dev/null 2>&1; then
		message "ok"
		return 0
	else
		warn "failed"
		return 1
	fi
}
smb_start_winbindd() {
	local log=
	message "start winbindd ... "


	if pidof winbindd >/dev/null; then
		warn "winbindd is running: `pidof winbindd`"
		return 1
	fi

	if /sbin/start winbindd > /dev/null 2>&1; then
		message "done"
		return 0
	else
		warn "failed"
		return 1
	fi
}
smb_start_smbd() {
	local smbspool=/var/spool/samba i=
	message "start smbd ... "


	if pidof smbd >/dev/null; then
		warn "smbd is running: `pidof smbd`"
		return 1
	fi

	if /sbin/start smbd > /dev/null 2>&1; then
		message "done"
		return 0
	else
		warn "failed"
		return 1
	fi
}

# actions
usage() { # void
	local H="[1m"
	local E="[0m"
	cat <<EOF
Usage: `basename $0` <actions>
Actions:
 $H start$E [options]            start samba by runkey in synoinfo.conf with
                             options.
 $H stop$E                       stop samba daemons
 $H restart$E                    restart service. equal to stop && start
 $H reload,hup$E                 reload config smb.conf
 $H force-reload$E
 $H status$E                     show running status for samba daemon
 $H info$E                       show detail informations
 $H -h,--help,usage$E            show this help message
EOF
}
start() { # [options]
	local opt OPTARG OPTIND smb_opts="-D $@"
	if ! smb_is_enabled; then
		warn "samba is not configured for running"
		return ${LSB_ERR_CONFIGURED:-6}
	fi

	smb_remove_temp_tdbs

	smb_start_nmbd $smb_opts

	local security=`get_key_value /etc/samba/smb.conf security`
	case $security in
		domain|ads) smb_start_winbindd $smb_opts;;
	esac

	smb_start_smbd $smb_opts
}
stop() { # [options]
	local smb_running nmbd_running winbindd_running

	proc_stop smbd
	if [ $? -ne ${LSB_NOT_RUNNING:-7} ]; then
		proc_wait_stop smbd &
	fi

	proc_stop winbindd
	if [ $? -ne ${LSB_NOT_RUNNING:-7} ]; then
		proc_wait_stop winbindd &
	fi

	proc_stop nmbd
	if [ $? -ne ${LSB_NOT_RUNNING:-7} ]; then
		proc_wait_stop nmbd &
	fi

	wait
	smb_remove_temp_tdbs
}
status() { # void
	lsb_status nmbd
	lsb_status winbindd
	lsb_status smbd
	local ret=$?
	return $ret
}
restart() { # <void>
	stop
	start "$@"
}
reload() {
	proc_signal hup nmbd
	proc_signal hup winbindd
	proc_signal hup smbd
}

info() { # <void>
	if mount | grep -q "smb"; then
		echo mount
	else
		echo not mount
	fi
	echo ====== proc info ======
	proc_info smbd
	proc_info nmbd
	proc_info winbindd

	echo ====== smbstatus ======
	/usr/bin/smbstatus -d 0

	echo ====== tdbs ======
	echo `find /run /var/cache/samba /usr/syno/etc/ -name "*.tdb"`

	#file_dump /etc/resolv.conf
	#file_dump /usr/syno/etc/smb.conf "workgroup"
	#file_dump /var/log/winlock.state
	#file_dump /usr/syno/etc/private/workgroup
}

init_env
if [ $# -eq 0 ]; then
	action=status
else
	action=$1
	shift
fi

# dispatch actions
case $action in
	start|stop|status|usage|restart|reload)
		$action "$@"
		;;
	hup)
		reload "$@"
		;;
	force-reload)
		exit ${LSB_ERR_UNIMPLEMENTED:-3}
		;;
	-h|--help)
		usage "$@"
		;;
# for debugging
	info)
		$action "$@"
		;;
	test_*)
		local fn=${action#test_}
		$fn "$@"
		;;
	prestart_smbd)
		smb_prestart_smbd
		;;
	poststart_smbd)
		smb_poststart_smbd
		;;
	poststop_smbd)
		smb_poststop_smbd
		;;
	prestart_nmbd)
		smb_prestart_nmbd
		;;
	poststop_nmbd)
		if ! is_ad_mode; then
			proc_wait_stop nmbd
		fi
		;;
	prestart_winbindd)
		smb_prestart_winbindd
		;;
	poststart_winbindd)
		smb_poststart_winbindd
		;;
	poststop_winbindd)
		smb_poststop_winbindd
		;;
	*)
		usage "$@" >&2
		exit ${LSB_ERR_ARGS:-2}
		;;
esac
# vim: noet:

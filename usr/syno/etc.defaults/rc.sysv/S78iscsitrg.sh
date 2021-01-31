#!/bin/sh
# Copyright (c) 2000-2016 Synology Inc. All rights reserved.

ISCSITRGT_LOCK="/tmp/S78iscsitrg.lock"

. /etc.defaults/rc.subr

lio_kernel_module_status()
{
	/sbin/lsmod | /bin/grep -q iscsi_target_mod
	if [ "$?" -eq "0" ]; then
		echo "0"
	else
		echo "-1"
	fi
}

iscsitrg_insmod()
{
	/usr/syno/bin/synoiscsiep --insmod iscsi > /dev/null 2>&1
}

iscsitrg_rmmod()
{
	/usr/syno/bin/synoiscsiep --rmmod iscsi > /dev/null 2>&1
}

## iSCSI target rc generic interface
iscsitrg_start()
{
	if [ "$(lio_kernel_module_status)" -ne "0" ]; then
		RCMsg "Running lunbackup garbage collection" \
		/usr/syno/bin/synolunbkp --gc

		/usr/syno/bin/synoiscsiep --startall iscsi > /dev/null 2>&1
	fi

	/sbin/initctl emit --no-wait syno.iscsi.ready
}

iscsitrg_stop()
{
	# Since synoservice won\'t let upstart do its job by placing override files,
	# we have to do this manually.
	/sbin/initctl stop iscsi_pluginengined
	/sbin/initctl stop scsi_plugin_server

	/usr/syno/bin/synoiscsiep --stopall iscsi
	if [ "$?" -ne "0" ]; then
		MsgFail "Stopping iSCSI LIO targets"
	else
		iscsitrg_rmmod
	fi

	if [ "yes" == "$(/usr/syno/bin/synogetkeyvalue /etc/synoinfo.conf runha)" ]; then
		/usr/syno/bin/synoiscsiep --oil
	fi

	#check the consistent between files and configs
	/usr/syno/bin/synocheckiscsitrg > /dev/null 2>&1
}

iscsitrg_restart()
{
	iscsitrg_stop
	iscsitrg_start
}

iscsitrg_status()
{
	local status="$(lio_kernel_module_status)"

	if [ "$status" -eq "0" ]; then
		RCMsg "iSCSI Service: running."
		return $LSB_STAT_RUNNING
	fi

	local targetcount=`synoiscsiep --target_cnt`

	if [ "$targetcount" -eq "0" ]; then
		RCMsg "iSCSI Service: stopped."
		# service framework is about to support enabled-but-not-running state,
		# but now we still need to pretend we are running for now.
		return $LSB_STAT_RUNNING
		#return $LSB_STAT_NOT_RUNNING
	fi

	return $LSB_STAT_NOT_RUNNING
}

check_support()
{
	local iscsitrg_support=`/bin/get_key_value /etc.defaults/synoinfo.conf support_iscsi_target`
	case "${iscsitrg_support}" in
		[Yy][Ee][Ss])
			return $LSB_SUCCESS
			;;
		*)
			RCMsg "iSCSI target is not supported."
			return $LSB_ERR_CONFIGURED
			;;
	esac
}

iscsitrg_unlock()
{
	/bin/rm "${ISCSITRGT_LOCK}"
}

iscsitrg_lock_trap_unset()
{
	trap - INT TERM EXIT ABRT
}

iscsitrg_lock_trap_set()
{
	trap 'iscsitrg_unlock' INT TERM EXIT ABRT
}

iscsitrg_lock()
{
	MAX_RETRY_COUNT=10
	retryCount=0

	while [ $retryCount -lt $MAX_RETRY_COUNT ]; do
		if [ -f ${ISCSITRGT_LOCK} ]; then
			local script_pid="`cat ${ISCSITRGT_LOCK}`"

			kill -0 $script_pid
			if [ $? -eq 0 ]; then
				MsgWarn "$0 (${script_pid}: \"`ps --no-headers -o comm ${script_pid}`\") is running. retry: ($retryCount / $MAX_RETRY_COUNT)"
			else
				MsgWarn "$0 ($script_pid) is NOT running."
				break
			fi
		else
			break
		fi

		sleep 3
		retryCount=$((retryCount + 1))
	done
	if [ $retryCount -eq $MAX_RETRY_COUNT ]; then
		MsgWarn "$0 Reach max retry count. exit!"
		return 1
	fi

	iscsitrg_lock_trap_set

	echo $$ > ${ISCSITRGT_LOCK}
	return 0
}

iscsitrg_subvol_converting()
{
	SUBVOL_CONV_STATUS_NORMAL=$(synowebapi --exec api=SYNO.Core.ISCSI.Node method=get additional="[\"is_subvol_conv_normal\",\"no_rod_key\",\"no_status\"]" 2>&1 | grep '\"is_subvol_conv_normal\" : true')

	if [ -z "$SUBVOL_CONV_STATUS_NORMAL" ]; then
		MsgWarn "Subvolume status is not normal"
		return 1
	fi

	return 0
}

[ "$#" -ne "0" ] && ! check_support && exit $?

iscsitrg_lock

lock_result=$?
[ "${lock_result}" -eq "1" ] && exit $LSB_STAT_RUNNING

iscsitrg_subvol_converting
subvol_conv_is_running=$?
[ "${subvol_conv_is_running}" -eq "1" ] && exit $LSB_ERR_GENERIC

case $1 in
	start)
		iscsitrg_start
		;;
	stop)
		iscsitrg_stop
		;;
	restart)
		iscsitrg_restart
		;;
	status)
		iscsitrg_status
		;;
	insmod)
		iscsitrg_insmod
		;;
	*)
		echo "Usage: `/usr/bin/basename $0` {start|stop|restart|status}"
		exit 1
esac

exit $?

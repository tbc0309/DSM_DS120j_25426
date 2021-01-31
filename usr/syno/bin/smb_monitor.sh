#!/bin/bash
# Copyright (c) 2019 Synology Inc. All rights reserved.

SYNOSERVICE="/usr/syno/sbin/synoservice"
SMBCONTROL="/usr/bin/smbcontrol"

usage()
{
	local H="[1m"
	local E="[0m"
	cat <<EOF
Usage: $(basename "$0") <actions>
Actions:
 $H --check_status$E        service is disable or okay: 0, something is error: 1.
 $H --ping$E                smbcontrol ping smbd
 $H -h, --help$E            show this help message
EOF
}

syslog() { # logger args
	logger -p user.err -t "$(basename "$0")($$)" "$@"
}

smb_is_enabled()
{
	${SYNOSERVICE} --is-enable samba > /dev/null 2>&1
	[[ 1 = "$?" ]]
}

smb_service_status()
{
	${SYNOSERVICE} --status samba > /dev/null 2>&1
}

smb_socket_is_created()
{
	local smbd_pid
	if ! smbd_pid=$(cat /run/samba/smbd.pid 2>&1); then
		syslog "smbd.pid is not set yet"
		return 1
	fi

	if [ -S "/run/samba/msg.sock/$smbd_pid" ]; then
		return 0
	else
		return 1
	fi
}

smb_ping()
{

	if ! smb_is_enabled; then
		return 0
	fi

	smb_service_status
	smb_status=$?

	case "${smb_status}" in
		0)
			if ! smb_socket_is_created; then
				syslog "socket is not created, skip the test"
				return 0
			fi
			smbd_pid=$(cat /run/samba/smbd.pid 2>&1)
			if ! ping_result=$($SMBCONTROL "${smbd_pid}" ping 2>&1); then
				syslog "${ping_result}"
				echo "=== debug message ==="
				echo "smbd pid: ${smbd_pid}"
				echo "pidof smbd"
				pidof smbd
				echo "ls /run/samba/msg.sock"
				ls -l /run/samba/msg.sock/
				echo "====================="
			else
				return 0
			fi
			if smb_service_status; then
				syslog "smbd ping failed"
				return 1
			fi
			return 0
			;;
		3)
			return 0
			;;
		*)
			syslog "smbd unknown error: $smb_status"
			return 1
			;;
	esac
}

case $1 in
	--check_status)
		smb_service_status
		;;
	--ping)
		smb_ping
		;;
	-h|--help)
		usage "$@"
		;;
	*)
		usage "$@" >&2
		exit "${LSB_ERR_ARGS:-2}"
		;;
esac

exit $?

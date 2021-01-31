#!/bin/sh
# Copyright (c) 2000-2016 Synology Inc. All rights reserved.

BIN_FLOCK=/usr/bin/flock
SBIN_INITCTL=/sbin/initctl
DSM_LOCK_FILE=/var/run/syslog-ng.lock
PKG_LOCK_FILE=/var/run/pkg-LogCenter-syslog.lock


case "$1" in
	reload)
		if [ ! -e ${BIN_FLOCK} ]; then
			logger -p err "${BIN_FLOCK} is not found..."
			exit 1
		fi
		if [ ! -e ${SBIN_INITCTL} ]; then
			logger -p err "${SBIN_INITCTL} is not found..."
			exit 1
		fi

		if ! /usr/syno/sbin/synoservicectl --status syslog-ng; then
			logger -p err "Job syslog-ng is not running, skip reload service action"
			exit 1
		else
			${BIN_FLOCK} -x ${DSM_LOCK_FILE} ${SBIN_INITCTL} reload syslog-ng
		fi

		if [ ! -f /var/packages/LogCenter/enabled ]; then
			logger -p debug "LogCenter is disable, skip reload service action"
		elif ! echo $(${SBIN_INITCTL} status pkg-LogCenter-syslog) | grep -q 'start/running'; then
			logger -p err "Job pkg-LogCenter-syslog is not running, skip reload service action"
		else
			#XXX: reload will cause synolog recv nothing with an unknown reason.
			${BIN_FLOCK} -x ${PKG_LOCK_FILE} ${SBIN_INITCTL} restart pkg-LogCenter-syslog
		fi
		;;
	*)
		echo "Usage $0 { reload }"
		exit 1
		;;
esac
exit 0

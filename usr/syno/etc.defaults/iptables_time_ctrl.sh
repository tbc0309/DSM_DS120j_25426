#!/bin/sh
# Copyright (c) 2000-2013 Synology Inc. All rights reserved.
# For iptables rule
TIME_CTRL_TOOL="/usr/syno/sbin/synotimecontrol"
TIME_CTRL_TOOL_TMP="/tmp/synotimecontrol"
TIME_CTRL_CONF="/etc/parental/timectrl.conf"

# return:
# 0 - disable
# 1 - enable
is_time_ctrl_rule_enable()
{
	if [ ! -f ${TIME_CTRL_CONF} ]; then
		return 0
	fi

	return 1
}

startTimeCtrl()
{
	is_time_ctrl_rule_enable
	if [ $? -eq 1 ]; then
		/bin/cp -f ${TIME_CTRL_CONF} /tmp/
		/bin/cp -f ${TIME_CTRL_TOOL} ${TIME_CTRL_TOOL_TMP}
		${TIME_CTRL_TOOL_TMP} --apply
	fi
}

stopTimeCtrl()
{
	if [ -f ${TIME_CTRL_TOOL_TMP} ]; then
		${TIME_CTRL_TOOL_TMP} --disable
	fi
}

case "$1" in
	start)
		startTimeCtrl
	;;
	stop)
		stopTimeCtrl
	;;
	*)
		echo "Usage: $0 [start|stop]"
		exit 1
	;;
esac
exit 0

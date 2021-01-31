#!/bin/sh
# Copyright (c) 2000-2013 Synology Inc. All rights reserved.

. /etc.defaults/rc.subr                 # for LSB definition and utilities
. /usr/syno/etc.defaults/rc.ssh.subr    # for SSH register key definition

RM="/bin/rm"
Rsync="/usr/bin/rsync"
RsyncPidFile="/var/run/rsyncd.pid"

StartSSHForRsync()
{
    ${SSHDUtils} --register ${ReferKeyRsync} ${ReferProcRsync} || true
    /sbin/start sshd 2>&1 >/dev/null || true
}

StopSSHForRsync()
{
    # Unregister rsync from ssh, and kill all relative process
    ${SSHDUtils} --unregister ${ReferKeyRsync} || true
}

StartRsyncDaemon()
{
    # Start rsyncd, it will write it pid into /var/log/rsyncd.pid
    if [ -x "$Rsync" ]; then
        $Rsync --daemon
    else
        echo "$Rsync is not executable."
    fi
}

StopRsyncDaemon()
{
    if [ -f "$RsyncPidFile" ]; then
        PROCESS_PID=`cat $RsyncPidFile`
        kill -9 $PROCESS_PID
        $RM $RsyncPidFile
    fi
}

case "$1" in
stop)
    StopRsyncDaemon
    StopSSHForRsync
    ;;
start)
    StartRsyncDaemon
    StartSSHForRsync
    ;;
restart)
    $0 stop
    sleep 1
    $0 start
    ;;
status)
    #FIXME!!! return slb status
    echo "Not implemnted now..."
    ;;
*)
    echo "usage: $0 { start | stop | restart | status}" >&2
    exit 1
    ;;
esac

#!/bin/sh

SZD_TMP="$1"
FILELIST=`ls /sys/class/scsi_host/host*/syno_port_thaw`
FILELIST=$FILELIST" "`ls /sys/class/scsi_host/host*/syno_pm_info`

mkdir -p $SZD_TMP
for file in $FILELIST;
do
	cp --parents $file $SZD_TMP
done

mkdir -p "$SZD_TMP/var/log/synolog"

/usr/syno/sbin/syno_disk_log_convert -o "$SZD_TMP/var/log/disk_log.html" /var/log/synolog/.SYNODISKDB
/usr/syno/sbin/syno_disk_testlog_convert -o "$SZD_TMP/var/log/disk_testlog.html" /var/log/synolog/.SYNODISKTESTDB

exit 0

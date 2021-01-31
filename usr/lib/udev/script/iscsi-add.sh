#!/bin/sh

# make /tmp/iscsi directory
if [ ! -d /tmp/iscsi ]; then
	mkdir /tmp/iscsi
fi

DEVPATH=$1
DEVNAME=$2

# get associated iqn
session=`echo ${DEVPATH} | awk -F "/" '{print $5}' | sed s/session//g`
iqn=`cat /sys/class/iscsi_session/session${session}/targetname`

# link iqn with the device node
ln -s /dev/${DEVNAME} /tmp/iscsi/${iqn}

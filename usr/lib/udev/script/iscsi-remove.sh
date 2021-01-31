#!/bin/sh

DEVPATH=$1

# get associated iqn
session=`echo ${DEVPATH} | awk -F "/" '{print $5}' | sed s/session//g`
iqn=`cat /sys/class/iscsi_session/session${session}/targetname`

# remove link
rm /tmp/iscsi/${iqn}

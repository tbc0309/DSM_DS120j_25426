#! /bin/sh
# Copyright (c) 2003-2014 Synology Inc. All rights reserved.
#
# Check the disk supports APM or not. If yes, set the APM setting.
#
# Usage:
#       DiskApmSet.sh APM_LEVEL DISK_DEV_NODE
#       ex: DiskApmSet.sh 255 /dev/sda      Disable APM on /dev/sda

# Check input valid
if [ -z $1 ] || [ -z $2 ]; then
	exit
fi

# Check the disk supports APM
if [ `/usr/bin/hdparm -B $2 | grep -c 'not supported'` -lt 1 ]; then
	# Set APM setting
	/usr/bin/hdparm -B $1 $2 > /dev/null 2>&1
fi

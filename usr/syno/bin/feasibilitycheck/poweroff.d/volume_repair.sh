#!/bin/sh

DecoveryCount=`grep -c recovery /proc/mdstat`

if [ 0 -lt ${DecoveryCount} ]; then
	exit 1
fi

exit 0

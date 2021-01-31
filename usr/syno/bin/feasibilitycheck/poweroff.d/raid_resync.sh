#!/bin/sh

ResyncCount=`grep -c resync /proc/mdstat`

if [ 0 -lt ${ResyncCount} ]; then
	exit 1
fi

exit 0

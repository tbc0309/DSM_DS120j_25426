#!/bin/sh
for item in `echo $MYDS_ABANDON_LIST | sed -n 1'p' | tr ',' '\n'`
do
	if [ "x$item" = "xquickconnect" ] ; then
		synoservice --stop synorelayd
	fi
done


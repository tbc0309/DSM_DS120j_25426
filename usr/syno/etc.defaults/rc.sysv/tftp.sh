#!/bin/sh

case "$1" in
'reload')
	/usr/syno/sbin/synoservicectl --restart opentftp
	RETVAL=0
	;;
*)
	echo "Usage $0 { reload }"
	RETVAL=1
;;
esac

exit $RETVAL

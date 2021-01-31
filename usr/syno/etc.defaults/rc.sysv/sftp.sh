#!/bin/sh
# Copyright (c) 2000-2014 Synology Inc. All rights reserved.

case $1 in
	reload)
		# use sshd
		/usr/syno/bin/synosshdutils --hup sftpd
		exit $?
	;;
	*)
		echo "Usages: $0 [reload]"
	;;
esac

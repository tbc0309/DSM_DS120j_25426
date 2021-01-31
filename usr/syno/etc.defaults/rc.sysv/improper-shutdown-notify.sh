#!/bin/sh
# Copyright (c) 2000-2019 Synology Inc. All rights reserved.

# the file was touched in /etc/rc
if [ -f /tmp/.ImproperShutdown ]; then
	/usr/syno/bin/synologset1 sys warn 0x11100001
	/usr/syno/bin/synonotify ImproperShutdown
	rm -f /tmp/.ImproperShutdown
fi

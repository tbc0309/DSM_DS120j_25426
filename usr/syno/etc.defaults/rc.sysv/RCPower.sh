#!/bin/sh
# Copyright (c) 2000-2003 Synology Inc. All rights reserved.

# workaround fix for #41575
if [ -f /var/.updater_enable_rcpower ]; then
	echo "Keep RCPower enable"
	exit
fi

Support=`/bin/grep -s ^supportrcpower /etc.defaults/synoinfo.conf | awk -F \" '{print $2}'`
SupportXA=`/usr/bin/get_key_value /etc.defaults/synoinfo.conf support_xa`

if [ "yes" == "$SupportXA" ]; then
	/usr/syno/bin/synoexternal -rcpoweron
	exit
fi

if [ "yes" = "$Support" ]; then
	Run=`/bin/grep -s ^enableRCPower /etc/synoinfo.conf | awk -F \" '{print $2}'`


	if [ "yes" = "$Run" ]; then
		/usr/syno/bin/synoexternal -rcpoweron
	else
		/usr/syno/bin/synoexternal -rcpoweroff
	fi
fi


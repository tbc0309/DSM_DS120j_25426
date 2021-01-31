#!/bin/sh
# Copyright (c) 2000-2014 Synology Inc. All rights reserved.
#
# This goes in /usr/syno/etc/rc.d and gets run at boot-time.

SYNOINFO_DEF="/etc.defaults/synoinfo.conf"
WIFI_TOPOLOGY_PREFIX="/usr/syno/etc/wifi/wifi_topology_"
WIFI_TOPOLOGY_CONF="${WIFI_TOPOLOGY_PREFIX}bridge ${WIFI_TOPOLOGY_PREFIX}router ${WIFI_TOPOLOGY_PREFIX}client"
CONF_TYPE="ds"

prepare_link() {
	local unique=`/bin/get_key_value $SYNOINFO_DEF unique`
	local val=`echo ${unique} | grep air | grep -v 213`

	if [ "x" != "x${val}" ]; then
		CONF_TYPE="air"
	fi
	for conf in ${WIFI_TOPOLOGY_CONF}; do
		`ln -fs ${conf}_${CONF_TYPE} ${conf}`
	done
}

case "$1" in

link_conf)
	prepare_link
;;

*)
echo "usage: $0 { link_conf }" >&2
exit 1
;;

esac


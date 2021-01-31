#!/bin/sh
# Copyright (c) 2000-2014 Synology Inc. All rights reserved.

# input args
IF_NAME=$1
NET_STATUS=$2 #CONNECTED or DISCONNECTED

# function start

case "$NET_STATUS" in
	CONNECTED)
		# this only happened when AP is down, then up
		/usr/libexec/net/if_link_up/interfaceUpAdjustList.sh --post ${IF_NAME}
		;;
	DISCONNECTED)
		# this only happened when wpa terminate
		# will be handle by interface hook
		;;
esac

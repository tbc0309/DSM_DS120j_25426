#!/bin/sh

###############################################################
#   This script should be hooked when invoking share_set hook.
#   Usable environment variable:
#       ORIGIN_SHARE_NAME, ORIGIN_SHARE_STATUS, ORIGIN_SHARE_PATH, SHARE_NAME, SHARE_STATUS, SHARE_PATH
###############################################################

BIN=/usr/syno/bin/synodrivehook

#At begining, acquire package settings
case $1 in
	--sdk-mod-ver)
		echo "2.0"
	;;
	--name)
		echo "SynoDrive"
	;;
	--pkg-ver)
		echo "1.0"
	;;
	--vendor)
		echo "Synology Inc."
	;;
	--pre)
		true
	;;
	--post)
		$BIN --share_set
	;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac


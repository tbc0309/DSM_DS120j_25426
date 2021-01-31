#!/bin/sh

###############################################################
#   This script should be hooked when invoking SYNOSchedTaskRemove()
#   Usable environment variable:
#
###############################################################

BIN=/usr/syno/bin/synoiscsiep

#At begining, acquire package settings
case $1 in
    --sdk-mod-ver)
	    echo "1.0" ;;
    --name)
	    echo "Synoiscsiep" ;;
    --pkg-ver)
	    echo "1.0" ;;
    --vendor)
	    echo "Synology Inc." ;;
    --pre)
	    $BIN --delete sst --tid ${ORG_TASK_ID};;
    --post)
		true ;;
    *)
	    echo "Usage: $0 --sdk_mod_ver|--name|--pkg_ver|--vendor|--pre|--post" ;;
esac

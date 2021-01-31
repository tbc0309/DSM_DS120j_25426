#!/bin/sh

###############################################################
#   This script should be hooked when invoking SYNOSchedTaskRemove()
#   Usable environment variable:
#       
###############################################################

SSD_TRIM_TBL=/usr/syno/etc/volume_trim_tbl
SSD_TRIM_DEL_ID="=${ORG_TASK_ID}$"

SSDTRIM_PKG_NAME="SSDTrim"
SSDTRIM_PKG_VERSION="1.0"
SSDTRIM_PKG_VENDOR="Synology Inc."
SSDTRIM_PKG_MODVER="1.0"

TASKSCHEDULER_PKG_MODVER="1.0"

#At begining, acquire package settings
case $1 in
    --sdk-mod-ver)
	#Print SDK support version
        echo ${TASKSCHEDULER_PKG_MODVER};
    ;;
    --name)
        #Print package name
        echo ${SSDTRIM_PKG_NAME};
    ;;
    --pkg-ver)
        #Print package version
        echo ${SSDTRIM_PKG_VERSION};
    ;;
    --vendor)
        #Print package vendor
        echo ${SSDTRIM_PKG_VENDOR};
    ;;
    --pre)
        #Actions before share set
        sed -i "/${SSD_TRIM_DEL_ID}"/d ${SSD_TRIM_TBL}
    ;;
    --post)
        #Actions after share set
    ;;
    *)
        echo "Usage: $0 --sdk_mod_ver|--name|--pkg_ver|--vendor|--pre|--post"
    ;;
esac


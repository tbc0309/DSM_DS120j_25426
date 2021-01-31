#!/bin/sh

###############################################################
#   This script should be hooked when invoking SYNOShareSnapXXXX()
#   XXXX: Create, Restore, Clone
#   Usable environment variable:
#       SHARE_NAME, SHARE_PATH, NEW_SHARE_NAME, NEW_SHARE_PATH, SNAPSHOT, ACTION, ENC_STATUS, RESULT
###############################################################

#At begining, acquire package settings
RETAINER_BINARY=/usr/syno/bin/synoretainer
SHARESNAP_BINARY=/usr/syno/sbin/synosharesnaptool

RETAINER_PKG_NAME="SynoRetainer"
RETAINER_PKG_VERSION="1.0"
RETAINER_PKG_VENDOR="Synology Inc."
RETAINER_PKG_MODVER="2.0"
RETAINER_SHARE_PREFIX="Share#"

case $1 in
	--sdk-mod-ver)
        echo ${RETAINER_PKG_MODVER}
	;;
	--name)
		#Print name
		echo ${RETAINER_PKG_NAME}
	;;
	--pkg-ver)
		echo ${RETAINER_PKG_VERSION}
	;;
	--vendor)
		#Print package vendor
		echo ${RETAINER_PKG_VENDOR}
	;;
	--pre)
		#Actions before share snapshot
		case $ACTION in
		CREATE)
			;;
		RESTORE)
			;;
		CLONE_SHARE)
			;;
		CLONE_SNAP)
			;;
		RECEIVE)
			;;
		*)
			;;
		esac
	;;
	--post)
		#Actions after share snapshot
		case $ACTION in
		CREATE)
			env "USERNAME=admin" ${RETAINER_BINARY} "${RETAINER_SHARE_PREFIX}" "${SHARE_NAME}"
			;;
		RESTORE)
			;;
		CLONE_SHARE)
			;;
		CLONE_SNAP)
			;;
		RECEIVE)
			#for receive/import
			${RETAINER_BINARY} "${RETAINER_SHARE_PREFIX}" "${SHARE_NAME}"
			;;
		*)
			;;
		esac
        ;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac

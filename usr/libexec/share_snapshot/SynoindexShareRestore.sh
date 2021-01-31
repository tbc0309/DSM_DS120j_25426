#!/bin/sh

###############################################################
#   This script should be hooked when invoking SYNOShareSnapXXXX()
#   XXXX: Create, Restore, Clone
#   Usable environment variable:
#       SHARE_NAME, SHARE_PATH, NEW_SHARE_NAME, NEW_SHARE_PATH, SNAPSHOT, ACTION, ENC_STATUS, RESULT
###############################################################

#Include common scripts
FILE_SYNOINDEX_INC_SCRP=/usr/libexec/SynoindexShareCommon.sh
. ${FILE_SYNOINDEX_INC_SCRP}

case $1 in
	--sdk-mod-ver)
	#Print SDK support version
	echo ${SYNOINDEX_PKG_MODVER}
	;;
	--name)
	#Print package name
	echo ${SYNOINDEX_PKG_NAME}
	;;
	--pkg-ver)
	#Print package version
	echo ${SYNOINDEX_PKG_VERSION}
	;;
	--vendor)
	#Print package vendor
	echo ${SYNOINDEX_PKG_VENDOR}
	;;
	--pre)
	#Actions before share snapshot action
	;;
	--post)
	#Actions after share snapshot action
		case $ACTION in
		CREATE)
			;;
		RESTORE)
			${BIN_SYNOINDEX} -R "${SHARE_PATH}"
			;;
		CLONE_SHARE)
			;;
		CLONE_SNAP)
			;;
		*)
			;;
		esac
	;;
	*)
	echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac


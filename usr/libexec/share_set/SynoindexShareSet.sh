#!/bin/sh

###############################################################
#   This script should be hooked when invoking share_set hook.
#   Usable environment variable:
#       ORIGIN_SHARE_NAME, SHARE_NAME, ORIGIN_SHARE_PATH, SHARE_PATH,
#       STATUS, RESULT
#
#   Note: The script should bear to be invoked multiple times
###############################################################

#Include common scripts
FILE_SYNOINDEX_INC_SCRP=/usr/libexec/SynoindexShareCommon.sh
. ${FILE_SYNOINDEX_INC_SCRP}

CheckDefaultShareCreate() {
	if [ "" = "${ORIGIN_SHARE_NAME}" ] && [ "" != "${SHARE_NAME}" ]; then
		IS_CREATE=1
		DO_INDEX_ADD=1
	fi
}

CheckShareNameChange() {
	# if origin share name is empty, skip it
	if [ "" = "${ORIGIN_SHARE_NAME}" ] ; then
		return
	fi

	# share name changed or share path changed
	if [ "${ORIGIN_SHARE_NAME}" != "${SHARE_NAME}" ] ||
	   [ "${ORIGIN_SHARE_PATH}" != "${SHARE_PATH}" ]; then
		IS_RENAME=1
	fi;
}

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
	#Actions before share set
	;;
	--post)
	#Actions after share set
	IS_CREATE=0
	IS_RENAME=0
	DO_INDEX_DEL=0
	DO_INDEX_REINDEX=0
	DO_INDEX_ADD=0

	if [ "0" != "${RESULT}" ]; then
		exit 0
	fi

	#Check hook condition
	CheckDefaultShareCreate
	CheckShareNameChange

	SYNOINDEX_SHARE_NAME_OLD=$ORIGIN_SHARE_NAME
	SYNOINDEX_SHARE_PATH_OLD=$ORIGIN_SHARE_PATH
	SYNOINDEX_SHARE_NAME=$SHARE_NAME
	SYNOINDEX_SHARE_PATH=$SHARE_PATH

	if [ "1" = "${IS_RENAME}" ]; then
		SynoindexShareRename
	elif [ "1" = "${IS_CREATE}" ]; then
		SynoindexShareCreate
	fi

	if [ "1" = "${DO_INDEX_DEL}" ]; then
		SynoindexRemove
	elif [ "1" = "${DO_INDEX_REINDEX}" ]; then
		SynoindexReindex
	elif [ "1" = "${DO_INDEX_ADD}" ]; then
		SynoindexAdd
	fi
	;;
	*)
	echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac


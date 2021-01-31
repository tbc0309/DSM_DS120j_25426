#!/bin/sh

###############################################################
#   This script should be hooked when invoking SYNOShareDelete()
#   Usable environment variable:
#       NITEMS, SHARE_NAME_X, SHARE_PATH_X, SHARE_SSTATUS_X
###############################################################

#Include common scripts
SYNOSDUTILS="/usr/syno/bin/synosdutils"
SYNOSERVICE="/usr/syno/sbin/synoservice"
SYNOSDUTILS_NAME="synosdutils"
SYNOSUTILS_VENDOR="Synology Inc."
SYNOSDUTILS_VERSION="1.0"
SDK_MODVER="2.0"

#At begining, acquire package settings
case $1 in
	--sdk-mod-ver)
		#Print SDK support version
		echo ${SDK_MODVER}
	;;
	--name)
		#Print synosdutils name
		echo ${SYNOSDUTILS_NAME}
	;;
	--pkg-ver)
		#Print synosdutils version
		echo ${SYNOSDUTILS_VERSION}
	;;
	--vendor)
		#Print synosdutils vendor
		echo ${SYNOSDUTILS_VENDOR}
	;;
	--pre)
		#Actions before share del
		echo "synosdutils share delete pre hook!"
	;;
	--post)
		# do nothing when booting-up
		if /usr/syno/bin/synobootseq --is-booting-up > /dev/null 2>&1 ; then
			exit
		fi
		# do nothing when when shutdown
		if /usr/syno/bin/synobootseq --is-shutdown > /dev/null 2>&1 ; then
			exit
		fi
		#Actions after share del
		for INDEX in $(seq 1 1 $NTIMES); do
			eval "SHARE_OP_RESULT=\$SHARE_OP_RESULT_$INDEX"
			eval "SHARE_NAME=\$SHARE_NAME_$INDEX"
			RES="`${SYNOSDUTILS} time-machine --share-status | /bin/grep ${SHARE_NAME}`"
			if [ "0x0000" == "${SHARE_OP_RESULT}" ] && [ -n ${RES} ]; then
				${SYNOSDUTILS} time-machine --rm-share "${SHARE_NAME}"
			fi
		done
		${SYNOSERVICE} --restart avahi
	;;
	*)
		echo "Usage: $0 --sdk_mod_ver|--name|--pkg_ver|--vendor|--pre|--post"
	;;
esac


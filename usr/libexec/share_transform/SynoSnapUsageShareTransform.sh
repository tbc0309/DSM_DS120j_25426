#!/bin/sh

###############################################################
#   This script should be hooked when invoking SYNOShareTransform()
#   Usable environment variable:
#       SHARE_NAME, SHARE_PATH, TRANS_DIRECT, RESULT
#
###############################################################

BIN="$(which synobtrfssnapusage)"

case $1 in
	--sdk-mod-ver)
		echo "2.0" ;;
	--name)
		echo "ShareSnapshot Caculator" ;;
	--pkg-ver)
		echo "1.0" ;;
	--vendor)
		echo "Synology Inc." ;;
	--pre)
		;;
	--post)
		${BIN} --clean-share-task ${SHARE_NAME}
		;;
	*)
		echo "Usage: $0 --sdk_mod_ver|--name|--pkg_ver|--vendor|--pre|--post" ;;
esac

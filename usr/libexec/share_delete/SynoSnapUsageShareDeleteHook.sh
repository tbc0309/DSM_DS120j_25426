#!/bin/sh

###############################################################
#   This script should be hooked when invoking SYNOShareDelete()
#   Usable environment variable:
#       NITEMS, SHARE_NAME_X, SHARE_PATH_X, SHARE_OP_RESULT_X
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
		INDEX=1
		NITEMS=$((NITEMS + 1))
		while [ "${INDEX}" != "${NITEMS}" ]
		do
			eval "SHARE_OP_RESULT=\$SHARE_OP_RESULT_$INDEX"
			eval "SHARE_NAME=\$SHARE_NAME_$INDEX"

			if [ "${SHARE_OP_RESULT}" == "0x0000" ]; then
				${BIN} --clean-share-task ${SHARE_NAME}
			fi
			INDEX=$((INDEX + 1))
		done

		;;
	*)
		echo "Usage: $0 --sdk_mod_ver|--name|--pkg_ver|--vendor|--pre|--post" ;;
esac

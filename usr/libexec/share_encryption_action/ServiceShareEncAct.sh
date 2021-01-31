#!/bin/sh

###############################################################
#   This script should be hooked when invoking SYNOShareEncShareUnmountPure() and SYNOShareEncShareMount()
#   Usable environment variable:
#       SHARE_NAME, ENC_ACTION={encrypt|decrypt}, RESULT
###############################################################

case $1 in
	--sdk-mod-ver)
		echo "2.0"
	;;
	--name)
		echo "ServiceShareEncAct"
	;;
	--pkg-ver)
		echo "1.0"
	;;
	--vendor)
		echo "Synology Inc."
	;;
	--pre)
		if [ "encrypt" == "${ENC_ACTION}" ]
		then
			synoservice --share-forbid ${SHARE_NAME}
		fi
	;;
	--post)
		if [ "encrypt" == "${ENC_ACTION}" ] && [ "0" != "${RESULT}" ]
		then
			synoservice --share-permit ${SHARE_NAME}
		fi
		if [ "decrypt" == "${ENC_ACTION}" ] && [ "0" == "${RESULT}" ]
		then
			synoservice --share-permit ${SHARE_NAME}
		fi
	;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac

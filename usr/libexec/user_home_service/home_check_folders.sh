#!/bin/sh
case $1 in
	--sdk-mod-ver)
	echo "1.0";
	;;
	--name)
	echo "home_check_folders";
	;;
	--pkg-ver)
	echo "1.0";
	;;
	--vendor)
	echo "Synology";
	;;
	--pre)
	;;
	--post)
		if [ "0" == "$RESULT" ] && [ "enable" == "$SYNO_HOME_ACTION" ]
		then
			synouserhome --check-all-folders $SYNO_AUTH_TYPE
		fi
	;;
	*)
	echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac


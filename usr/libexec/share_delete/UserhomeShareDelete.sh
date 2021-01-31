#!/bin/sh

case $1 in
	--sdk-mod-ver)
	#Print SDK support version
	echo "2.0";
	;;
	--name)
	#Print package name
	echo "UserhomeShareDelete";
	;;
	--pkg-ver)
	#Print package version
	echo "1.0";
	;;
	--vendor)
	#Print package vendor
	echo "Synology Inc.";
	;;
	--pre)
	INDEX=1
	while [ "${INDEX}" -le "${NITEMS}" ]
	do
		eval "SHARE_NAME=\$SHARE_NAME_$INDEX"
		if [ "$SHARE_NAME" == "homes" ]; then
			servicetool --clear-user-home-setting
		fi
		INDEX=$((INDEX + 1))
	done
	;;
	--post)
	;;
	*)
	echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac


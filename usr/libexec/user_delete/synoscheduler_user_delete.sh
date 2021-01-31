#!/bin/sh
# Copyright (c) 2000-2015 Synology Inc. All rights reserved.

case $1 in
	--sdk-mod-ver)
		echo "1.0"
	;;
	--name)
		echo "TaskScheduler"
	;;
	--pkg-ver)
		echo "1.0"
	;;
	--vendor)
		echo "Synology Inc."
	;;
	--pre)
	;;
	--post)
		/usr/syno/bin/synoschedtask --disable-owner-does-not-exist-task
	;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac


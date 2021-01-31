#!/bin/sh
#set -x

case "$1" in
	start)
		;;
	reload)
		stop synowsdiscoveryd
		start synowsdiscoveryd
		reload synowstransferd
		;;
	status)
		pidof -x synowsdiscoveryd && pidof synowstransferd
		exit $?
		;;
	stop)
		;;
esac

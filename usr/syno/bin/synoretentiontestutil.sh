#!/bin/sh
# Copyright (c) 2000-2014 Synology Inc. All rights reserved.

BIN_NAME='synoretentiontestutil'

set_time()
{
	synoservice -stop ntpd-client
	echo -n "Set date to: "
	date --set "$@"
}

testutil_take()
{
	if [ "$#" -lt 2 ]; then
		echo "Arg format error, prefix and name needed."
		usage
		exit 1
	fi
	PREFIX=$1
	NAME=$2
	shift 2

	LOCK="N"
	if [ "$1" == "--locked" ]; then
		LOCK="Y"
		shift
	fi

	case $PREFIX in
		"Lun#")
			if [ "$LOCK" == "Y" ]; then
				LOCK_PARAMS="--lock true"
			else
				LOCK_PARAMS="--lock false"
			fi
			;;
		"Share#")
			if [ "$LOCK" == "Y" ]; then
				LOCK_PARAMS="lock=true"
			else
				LOCK_PARAMS="lock=false"
			fi
			;;
		*)
			echo "Storage type must be lun or share."
			exit 1
			;;
	esac

	if [ "$#" -lt 1 ]; then
		echo "Arg format error, cannot get time."
		usage
		exit 1
	fi
	set_time "$@"

	case $PREFIX in
		"Lun#")
			LUN_ID=$(synoretention-lun idbyname "$NAME")
			if [ 0 -ne $? ]; then
				echo "Failed to get lun id by name ${NAME}."
				exit 1
			fi
			synoiscsiep --create snap --lid "$LUN_ID" $LOCK_PARAMS --type crash
			;;
		"Share#")
			synosharesnapshot create "$NAME" $LOCK_PARAMS
			;;
		*)
			echo "Storage type must be lun or share."
			exit 1
			;;
	esac
}

testutil_list()
{
	if [ "$#" -ne 2 ]; then
		echo "Arg format error, prefix and name needed."
		usage
		exit 1
	fi
	PREFIX=$1
	NAME=$2
	shift 2

	echo "--- Retention Config ---"
	synoretentionconf --get "$PREFIX" "$NAME"
	case $PREFIX in
		"Lun#")
			echo "--- Snapshots ---"
			synoretention-lun listsnapshot "$NAME"
			;;
		"Share#")
			echo "--- Non Locked Snapshots ---"
			synosharesnapshot list "$NAME" lock=false
			echo "--- Locked Snapshots ---"
			synosharesnapshot list "$NAME" lock=true
			;;
		*)
			echo "Storage type must be lun or share."
			exit 1
			;;
	esac
}

testutil_run()
{
	if [ "$#" -lt 2 ]; then
		echo "Arg format error, prefix and name needed."
		usage
		exit 1
	fi
	PREFIX=$1
	NAME=$2
	shift 2

	if [ "$#" -lt 1 ]; then
		echo "Arg format error, cannot get time."
		usage
		exit 1
	fi
	set_time "$@"

	synoretainer "$PREFIX" "$NAME"
}

usage()
{
	echo "Copyright (c) 2000-2014 Synology Inc. All rights reserved."
	echo ""
	echo "+--- WARNING ------------------------------------------------+"
	echo "| This tool may change system time and stop the ntp client.  |"
	echo "+------------------------------------------------------------+"
	echo ""
	echo "Usage: $BIN_NAME [take|list|run]"
	echo ""
	echo "    $BIN_NAME take <Lun#|Share#> <name> [--locked] <as_time>"
	echo "        Adjust the system time to <as_time>, then take a snapshot."
	echo ""
	echo "    $BIN_NAME list <Lun#|Share#> <name>"
	echo "        List retention policy and all taken snapshots by storage type and name."
	echo ""
	echo "    $BIN_NAME run  <Lun#|Share#> <name> <as_time>"
	echo "        Adjust the system time to <as_time>, then run the retention policy."
	echo "        Retention policy could be set by \"synoretentionconf\"."
	echo ""
	echo "    Time string is local time, with format: \"YYYY-MM-DD hh:mm:ss\"."
	echo "    Example:"
	echo "    > $BIN_NAME take Share# example_share --locked \"2010-02-05 09:13:00\""
}

OP=$1
case $OP in
	"take")
		shift
		testutil_take "$@"
		;;
	"list")
		shift
		testutil_list "$@"
		;;
	"run")
		shift
		testutil_run "$@"
		;;
	*)
		usage
		exit 1
		;;
esac

#!/bin/bash
# Copyright (c) 2000-2015 Synology Inc. All rights reserved.


QUOTA_PLUGIN=/usr/libexec/volume/mount/quota_volume_mount
MAX_JOB_NUM=$(nproc)


DoWork()
{
	local device= fstype= mnt= loc=
	local idx=

	for idx in $(seq 1 ${VOLUME_NUMBER:-0}); do
		eval "device=\$DEVICE_$idx"
		eval "fstype=\$TYPE_$idx"
		eval "loc=\$LOCATION_$idx"
		eval "mnt=\$MOUNTPOINT_$idx"

		env -i DEVICE=$device MOUNTPOINT=$mnt TYPE=$fstype LOCATION=$loc RESULT=$RESULT $QUOTA_PLUGIN $1 &

		while [ $MAX_JOB_NUM -le $(jobs | wc -l) ]; do
			wait -n  # Wait for any child.
		done
	done

	wait  # Wait for all children.
}


case "$1" in
	--sdk-mod-ver|--name|--pkg-ver|--vendor)
		$QUOTA_PLUGIN $1
		;;
	--pre)
		# Nothing to be done.
		;;
	--post)
		DoWork $1
		;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
		;;
esac

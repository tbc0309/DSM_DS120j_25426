#!/bin/sh
# Copyright (c) 2000-2017 Synology Inc. All rights reserved.

# check memory for Hardware Video Transcoding is reserved or not

ION_HEAPS_MEDIA=/sys/kernel/debug/ion/heaps/Media

if [ -f "$ION_HEAPS_MEDIA" ]; then
	if [ $((`cat "$ION_HEAPS_MEDIA" | grep GEN | head -1 | cut -c 41-51`)) -gt $((0x3200000)) ]; then
		echo "Memory is reserved for Video Transcoding"
		exit 1
	else
		echo "Memory is not reserved for Video Transcoding"
		exit 0
	fi
fi

echo "Model is not supported."
exit -1

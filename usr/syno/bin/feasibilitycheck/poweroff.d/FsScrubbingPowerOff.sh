#!/bin/sh

grep -q "running" /tmp/.btrfs_scrub.progress.* 2> /dev/null
if [ $? -eq 0 ] ; then
	exit 1 ;
fi
exit 0

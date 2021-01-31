#!/bin/sh

progress_files=$(ls /tmp/DSMTaskMgr/\@administrators/sharemove* 2>/dev/null)

for progress_file in $progress_files
do
	finished=$(jq .private.finished $progress_file)
	if [ "$finished" != "true" ]
	then
		exit 1
	fi
done

exit 0

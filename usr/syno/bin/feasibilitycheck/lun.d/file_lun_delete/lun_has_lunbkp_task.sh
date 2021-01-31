#!/bin/sh

# Delete soft feasibility checking if lunbkp task exist

delLunLid=$1
delLunUuid=$2
delLunName=$3
delLunRootPath=$4
delLunSize=$5
delLunType=$6

taskLunName=$(cat /usr/syno/etc/lunbkp/lunbkptask.conf | grep "lunname" | sed 's/lunname=//g')

for x in $taskLunName; do
    if [ "$x" == "$delLunName" ]; then
        exit 1
    fi
done

exit 0


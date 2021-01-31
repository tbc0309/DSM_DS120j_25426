#!/bin/sh
# Copyright (c) 2000-2015 Synology Inc. All rights reserved.

if [ $# -ne 3 ]; then
	echo "argument number should be 3"
	exit 254
fi

URL=$1
TRIES=$2	# number of retries passed to wget's `--tries`
TIMEOUT=$3	# timeout in second, passed to wget's `--timeout`

# get the last two line of the output
# strip the date time info
# match (??? ?B/s) and preserve the error message.
wget --delete-after --no-check-certificate "$URL" "--tries=$2" "--timeout=$3" 2>&1 | grep "^[0-9]\+-" \
	| cut -d " " -f 3- \
	| sed "s/^[^(]*(\([0-9.]\+ [KM]\?B\/s\)).*$/\1/g" | tr -d "\n"

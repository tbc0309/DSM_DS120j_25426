#!/bin/bash
# Copyright (c) 2000-2019 Synology Inc. All rights reserved.

log ()
{
	/bin/logger --priority user.err --tag "coredump" "$*"
}

# Check params
if [ $# -lt 4 ]; then
	log "Insufficient parameters: $# given"
	exit 1
fi
PATH_DUMPDIR=$1
FILE_NAME=$2
PID_DUMP=$3
SIGNAL_DUMP=$4

if [ ! -d "${PATH_DUMPDIR}" ]; then
	log "Directory does not exist: [${PATH_DUMPDIR}]"
	exit 1;
fi
if [ -z "${FILE_NAME}" -o "${FILE_NAME}" != "`basename \"${FILE_NAME}\"`" ]; then
	log "Invalid file name [${FILE_NAME}]"
	exit 1
fi

log "Process ${FILE_NAME}[${PID_DUMP}] dumped core on signal [${SIGNAL_DUMP}]."

umask 0077
PATH_OUTPUT="${PATH_DUMPDIR}/@${FILE_NAME}.core.gz"
PATH_TMP="${PATH_OUTPUT}.${PID_DUMP}"

/bin/gzip -1 > "${PATH_TMP}"
if [ 0 -ne $? ]; then
	log "Failed to compress core file [${PATH_TMP}]"
	/bin/rm -f "${PATH_TMP}"
	exit 1
fi
/bin/mv "${PATH_TMP}" "${PATH_OUTPUT}"

#!/bin/sh

if [ "" != $1 ]; then 
	BOOT_STATUS=`/usr/syno/bin/synobootseq --is-ready`
	RET=$?
	while [ $RET -ne 0 ]
	do
		sleep 5
		BOOT_STATUS=`/usr/syno/bin/synobootseq --is-ready`
		RET=$?
	done

	/usr/syno/bin/synonotify $1
fi

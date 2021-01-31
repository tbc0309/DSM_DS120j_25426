#!/bin/sh
# Copyright (c) 2000-2014 Synology Inc. All rights reserved.

CheckADTDevice()
{
	file=/sys/class/hwmon/
	for f in $file*
	do
		if [ -d $f/device ]; then
			name=`cat $f/device/name`
			if [ "$name" == "adt7490" ];then
				return 1
			fi
		fi
	done
	return 0
}

SYNOLoadAdt7490()
{
	local supportadt7490=`get_key_value $SYNOINFO_DEF supportadt7490`
	local PLATFORM=`get_key_value $SYNOINFO_DEF unique | cut -d"_" -f2`

	if [ "$supportadt7490" = "yes" ]; then
		if [ "$PLATFORM" = "denverton" ]; then
			SYNOLoadModules hwmon-vid
		fi
		if [ "$PLATFORM" = "v1000" ]; then
			SYNOLoadModules hwmon-vid
		else
			SYNOLoadModules i2c-i801
		fi
		SYNOLoadModules adt7475

		for retry_count in `seq 1 3`
		do
			CheckADTDevice
			if [ $? -eq 0 ]; then
				echo Can not detect ADT device, Retry: $retry_count...
				sleep 1
				SYNOUnloadModules i2c-i801 adt7475
				sleep 1
				SYNOLoadModules i2c-i801 adt7475
			else
				break
			fi
		done
	fi
}

SYNOUnloadAdt7490()
{
	local supportadt7490=`get_key_value $SYNOINFO_DEF supportadt7490`
	local PLATFORM=`get_key_value $SYNOINFO_DEF unique | cut -d"_" -f2`

	if [ "$supportadt7490" = "yes" ]; then
		SYNOUnloadModules adt7475
		if [ "$PLATFORM" = "v1000" ]; then
			SYNOUnloadModules hwmon-vid
		else
			SYNOUnloadModules i2c-i801
		fi

		if [ "$PLATFORM" = "denverton" ]; then
			SYNOUnloadModules hwmon-vid
		fi
	fi
}

findADTPath()
{
	ret=0
	unset ADTDIRS
	file=/sys/class/i2c-dev/i2c-*/device/*-002[c-e]
	for f in $file
	do
		if [ ! -f "$f/name" ]; then
			continue
		fi
		name=`cat $f/name`
		if [ "$name" == "adt7490" ];then
			ADTDIRS="${ADTDIRS} $f"
			ret=1
		fi
	done
	return ${ret}
}

# here we assume adt master will always 0x2e, because due to adt7490's spec, only 0x2e address can be fixed
findADTMaster()
{
	unset ADTMASTER
	adtmasters=/sys/class/i2c-dev/i2c-*/device/*-002e

	local device2e
	local device2c

	if [ -f /sys/class/i2c-dev/i2c-*/device/*-002e/name ]; then
		device2e=`cat /sys/class/i2c-dev/i2c-*/device/*-002e/name`
		if [ "$device2e" == "adt7490" ]; then
			adtmasters=/sys/class/i2c-dev/i2c-*/device/*-002e
		fi
	elif [ -f /sys/class/i2c-dev/i2c-*/device/*-002c/name ]; then
		device2c=`cat /sys/class/i2c-dev/i2c-*/device/*-002c/name`
		if [ "$device2c" == "adt7490" ]; then
			adtmasters=/sys/class/i2c-dev/i2c-*/device/*-002c
		fi
	fi

	for f in $adtmasters
	do
		# use only 1 master
		ADTMASTER="$f"
		break
	done
}

SoftLink7490fanInput()
{
	local supportadt7490=`get_key_value $SYNOINFO_DEF supportadt7490`

	if [ "$supportadt7490" != "yes" ]; then
		return
	fi
	adtfanTmpPath="/tmp/ADTFanPath/"
	findADTPath
	# no adt path found
	if [ 1 -ne $? ]; then
		return
	fi
	findADTMaster
	if [ -z ${ADTMASTER} ]; then
		return
	fi
	/bin/mkdir -p ${adtfanTmpPath}
	# soft link master adt7490
	masterfiles=`ls ${ADTMASTER}/*`
	for masterfile in ${masterfiles}
	do
		ln -s ${masterfile} ${adtfanTmpPath}/
	done
	# assume other fan input comes from 5
	fanCnt=5
	# soft link slave adt7490
	for ADTDIR in ${ADTDIRS}
	do
		# skip master itself
		if [ "${ADTDIR}" == "${ADTMASTER}" ]; then
			continue
		fi
		slaveFans=`ls ${ADTDIR}/fan*_input`
		for slavefan in ${slaveFans}
		do
			ln -s ${slavefan} ${adtfanTmpPath}/fan${fanCnt}_input
			fanCnt=`expr ${fanCnt} + 1`
		done
	done
}


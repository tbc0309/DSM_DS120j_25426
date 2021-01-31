#!/bin/sh

DEVPATH=$1
FIRMWARE=$2

FIRMWARE_FULL_PATH=""
FIRMWARE_DIR="/lib/firmware"
SYSFS="/sys"

if [ ! -e ${SYSFS}/${DEVPATH}/loading ]; then
	sleep 1s
fi

if echo ${FIRMWARE} | grep "${FIRMWARE_DIR}" > /dev/null; then
	# For intelce-utilities project, its drivers pass a full path in $FIRMWARE variable
	# And the path can't be changed due to it is stored in a configuration that shared with other application
	FIRMWARE_FULL_PATH=${FIRMWARE}
else
	FIRMWARE_FULL_PATH=${FIRMWARE_DIR}/${FIRMWARE}
fi

if [ -f "${FIRMWARE_FULL_PATH}" ]; then
	echo 1 > ${SYSFS}/${DEVPATH}/loading
	cp "${FIRMWARE_FULL_PATH}" "${SYSFS}/${DEVPATH}/data"
	echo 0 > ${SYSFS}/${DEVPATH}/loading
elif [ -f "${FIRMWARE_DIR}/backports_dvb/${FIRMWARE}" ]; then #For Backports dvb (3.10.x kernel only)
	echo 1 > ${SYSFS}/${DEVPATH}/loading
	cp "${FIRMWARE_DIR}/backports_dvb/${FIRMWARE}" "${SYSFS}/${DEVPATH}/data"
	echo 0 > ${SYSFS}/${DEVPATH}/loading
else
	echo -1 > ${SYSFS}/${DEVPATH}/loading
fi

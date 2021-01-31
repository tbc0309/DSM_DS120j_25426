#!/bin/sh

DEVNAME=$1
IsCardReader=0

GetDevName () {
	if [ "" = "`echo ${DEVNAME} | grep ^sd`" -a "" = "`echo ${DEVNAME} | grep ^usb`" ]; then
		DEVNAME="`ls /sys/${DEVPATH}/block`"
	fi

	#DEVNAME is essential
	if [ "" = "${DEVNAME}" ]; then
		echo "DEVNAME is empty ?" >> /tmp/usbdebug
		exit 0
	fi
}

CheckIsCardReader () {
	#This is new mechanism
	if [ -e /sys/block/${DEVNAME}/device/syno_cardreader ]; then
		if [ "1" = "`cat /sys/block/${DEVNAME}/device/syno_cardreader`" ]; then
			IsCardReader=1
		fi
	fi
}

GetBusNumDevNumAndGUID () {
	if [ -z "${DEVICE}" ]; then
		#To fix bug [16677], we should search usbdev number from the nearest dev entry.
		if [ "." != "${SYNO_ATTR_BUSNUM_DEVNUM}" ]; then
			DEVICE="/proc/bus/usb/"

			local Digtal=`echo ${SYNO_ATTR_BUSNUM_DEVNUM} | cut -d . -f 1 | wc -c`
			Digtal=$((${Digtal}-1))         # Remove the \n count
			Digtal=$((3-${Digtal}))         # How many zero do we need
			while [ "$Digtal" -gt 0 ]; do
				DEVICE="${DEVICE}0"
				Digtal=$((${Digtal}-1))
			done
			DEVICE=${DEVICE}`echo ${SYNO_ATTR_BUSNUM_DEVNUM} | cut -d . -f 1`
			DEVICE="${DEVICE}/"

			Digtal=`echo ${SYNO_ATTR_BUSNUM_DEVNUM} | cut -d . -f 2 | wc -c`
			Digtal=$((${Digtal}-1))         # Remove the \n count
			Digtal=$((3-${Digtal}))         # How many zero do we need
			while [ "$Digtal" -gt 0 ]; do
				DEVICE="${DEVICE}0"
				Digtal=$((${Digtal}-1))
			done
			DEVICE=${DEVICE}`echo ${SYNO_ATTR_BUSNUM_DEVNUM} | cut -d . -f 2`
		fi
	fi

	if [ -z "${DEVGUID}" ]; then
		local tmpPATH=""
		if [ -n "${PHYSDEVPATH}" ]; then
			tmpPATH="${PHYSDEVPATH}"
		elif [ -n "${DEVPATH}" ]; then
			tmpPATH="${DEVPATH}"
		fi
		local Len=`echo ${tmpPATH} | /usr/bin/wc -c`
		Len=$((${Len}-1))
		local LastChar=`echo ${tmpPATH} | cut -c ${Len}`
		DEVGUID="${SYNO_ATTR_SERIAL}${LastChar}"
	fi

	#DEVGUID is essential , but remove event doesn't have it , so we skip its check
	if [ "remove" != "${ACTION}" -a "" = "${DEVGUID}" ]; then
		echo "DEVGUID is empty ?" >> /tmp/usbdebug
		exit 0
	fi
}

GetDevName
CheckIsCardReader
GetBusNumDevNumAndGUID

case ${ACTION} in
add)
	if [ "USB" != "${SYNO_DEV_DISKPORTTYPE}" -a "USBHUB" != "${SYNO_DEV_DISKPORTTYPE}" ]; then
		echo "Skip empty SYNO_DEV_DISKPORTTYPE event" >> /tmp/usbdebug
		exit 0
	fi

	#Since there is redundant block event of card reader when booting in linux-2.6 , we filter it
	if [ "2.6" = "${SYNO_KERNEL_VERSION}" -a 1 -eq ${IsCardReader} -a "block" = "${SUBSYSTEM}" ]; then
		echo "Skip card reader's block event" >> /tmp/usbdebug
		exit 0
	fi
;;
change)
	KERNEL_MAJOR=`echo ${SYNO_KERNEL_VERSION} | cut -d . -f 1`

	#We only reserve the change event for card reader and RDX device
	if [ 1 -ne ${IsCardReader} ] && [ "x1" != "x${SYNO_IS_RDX}" ]; then
		exit 0
	fi

	#There will be two same change events for SD card and RDX.
	#Starting from linux-3.x, we can use DISK_MEDIA_CHANGE to filter one of them
	if [ 3 -le ${KERNEL_MAJOR} -a "1" != "${DISK_MEDIA_CHANGE}" ]; then
		exit 0
	fi

	#In linux-2.6, we could only use SYNO_DEV_DISKPORTTYPE to filter one of them
	if [ "2.6" = "${SYNO_KERNEL_VERSION}" -a "USB" = "${SYNO_DEV_DISKPORTTYPE}" -a "x1" != "x${SYNO_IS_RDX}" ]; then
		exit 0
	fi

	grep "${DEVNAME}" /proc/partitions
	if [ 0 -ne $? ]; then
		ACTION="remove"
	else
		ACTION="add"
	fi
;;
remove)
	#TBD
;;
*)
	exit 0
;;
esac

echo "ACTION=$ACTION , SYNO_DEV_DISKPORTTYPE=$SYNO_DEV_DISKPORTTYPE , SYNO_KERNEL_VERSION=$SYNO_KERNEL_VERSION , DEVICE=$DEVICE , DEVNAME=$DEVNAME , DEVGUID=$DEVGUID , SUBSYSTEM=$SUBSYSTEM , KERNEL_VERSION=$KERNEL_VERSION , DEVPATH=$DEVPATH , PHYSDEVPATH=$PHYSDEVPATH , SYNO_ATTR_BUSNUM_DEVNUM=$SYNO_ATTR_BUSNUM_DEVNUM , SYNO_ATTR_SERIAL=$SYNO_ATTR_SERIAL" >> /tmp/usbdebug
echo "" >> /tmp/usbdebug

export DEVICE=$DEVICE
export DEVNAME=$DEVNAME
export DEVGUID=$DEVGUID

/lib/udev/script/hotplugd-util.sh prepare-device-boot-info
/lib/udev/script/hotplugd-util.sh prepare_hotplug_event_file

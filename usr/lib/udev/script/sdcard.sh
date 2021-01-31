#!/bin/sh
#Set KERNELNAME to DEVNAME. this is weird!! DEVNAME should be: /dev/${KERNALNAME}
DEVNAME=$1
SUPPORT_MMC_BOOT=`get_key_value /etc.defaults/synoinfo.conf support_emmc_boot`

GetDEVNAME () {
	#DEVNAME is essential.
	if [ "" = "`echo ${DEVNAME} | grep ^mmc`" ]; then
			DEVNAME="`ls /sys/${PHYSDEVPATH}/block`"
			echo "Got DEVNAME which is different from "mmcblk[0-9]": ${DEVNAME}" >>  /tmp/mmcblkdebug
	fi
	if [ "" = "${DEVNAME}" ]; then
		echo "DEVNAME is empty ?" >>  /tmp/mmcblkdebug
		exit 0
	fi
}

#DEVGUID is essential, if it's blank, hotplugd-util.sh will generate it.
GetDEVGUID () {
	if [ -z "${DEVGUID}" ]; then
		# In old usb.sh, it will append last char of PHYSDEVPATH.
		# But the reason is unknown, thus we remove it.
		DEVGUID="${SYNO_ATTR_SERIAL}"
	fi

	#DEVGUID is essential , but remove event doesn't have it , so we skip its check
	if [ "remove" != "${ACTION}" -a "" = "${DEVGUID}" ]; then
		echo "DEVGUID is empty ?" >>  /tmp/mmcblkdebug
		exit 0
	fi
}
#DEVICE is essential, if it's blank, hotplugd-util.sh will generate it.
GetDEVICE () { #This is essential for now, while mmcblk device don't have it. NEED TO BE IMPROVED!!!!!!!
    if [ -z "${DEVICE}" ]; then
			DEVICE="/proc/bus/usb/000/000"
	fi
}

# Prevent from identifying EDS14's main flash as a sdcard external device.
if [ "${SUPPORT_MMC_BOOT}" == "yes" ]; then
	exit 0
fi

GetDEVNAME
GetDEVGUID
GetDEVICE

case ${ACTION} in
add)
    #ENV{SYNO_DEV_DISKPORTTYPE} comes from 05-system-env.rules.
	if [ "SDCARD" != "${SYNO_DEV_DISKPORTTYPE}" ]; then
		echo "Skip empty SYNO_DEV_DISKPORTTYPE event" >>  /tmp/mmcblkdebug
		exit 0
	fi
;;
change)

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

echo "ACTION=$ACTION , SYNO_DEV_DISKPORTTYPE=$SYNO_DEV_DISKPORTTYPE , SYNO_KERNEL_VERSION=$SYNO_KERNEL_VERSION , DEVICE=$DEVICE , DEVNAME=$DEVNAME , DEVGUID=$DEVGUID , SUBSYSTEM=$SUBSYSTEM , KERNEL_VERSION=$KERNEL_VERSION , DEVPATH=$DEVPATH , PHYSDEVPATH=$PHYSDEVPATH , SYNO_ATTR_BUSNUM_DEVNUM=$SYNO_ATTR_BUSNUM_DEVNUM , SYNO_ATTR_SERIAL=$SYNO_ATTR_SERIAL" >>  /tmp/mmcblkdebug
echo "" >>  /tmp/mmcblkdebug

export DEVNAME=$DEVNAME
export DEVGUID=$DEVGUID
export DEVICE=$DEVICE

#for now we still need this key file to be considered as cardreader.
echo "${PHYSDEVPATH}" > /tmp/cardreader;
/lib/udev/script/hotplugd-util.sh prepare_hotplug_event_file

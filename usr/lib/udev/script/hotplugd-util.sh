#!/bin/sh

wait_sysfs_ready()
{
	for i in `/usr/bin/seq 1 10`; do
		if `grep -q tmpfs /proc/mounts` ; then
			if `grep -q sysfs /proc/mounts` ; then
				if [ -d /sys/devices ] ; then
					break
				fi
			fi
		fi
		sleep 1
	done
}

get_device_guid()
{
	# Try disk first
	Len=`echo ${PHYSDEVPATH} | /usr/bin/wc -c`
	Len=$((${Len}-1))
	LastChar=`echo ${PHYSDEVPATH} | cut -c $Len`

	if [ -f "/sys/${PHYSDEVPATH}/../../../../serial" ]; then
		DEVGUID=`cat /sys/${PHYSDEVPATH}/../../../../serial`
	elif [ -f "/sys/${PHYSDEVPATH}/../serial" ]; then
		# Printer
		DEVGUID=`cat /sys/${PHYSDEVPATH}/../serial`
	elif [ -f "/sys/${PHYSDEVPATH}/syno_disk_serial" ]; then
		# esata
		DEVGUID=`cat /sys/${PHYSDEVPATH}/syno_disk_serial`
	fi
	DEVGUID="${DEVGUID}${LastChar}"
}

get_device()
{
	#To fix bug [16677], we should search usbdev number from the nearest dev entry.
	#So the search logic change to "/sys/${PHYSDEVPATH}/../", then "/sys/${PHYSDEVPATH}/../../../../".
	#ex: PHYSDEVPATH=/devices/pci0000:00/0000:00:0e.1/usb1/1-3/1-3:1.2/host11/target11:0:0/11:0:0:0
	#ex: PHYSDEVPATH=/devices/pci0000:00/0000:00:0e.1/usb1/1-3/1-3:1.1
	#ex: PHYSDEVPATH=/devices/platform/orion-ehci.0/usb1/1-1/1-1.2/1-1.2:1.2/host4/target4:0:0/4:0:0:0
	#ex: PHYSDEVPATH=/devices/platform/orion-ehci.0/usb1/1-1/1-1.2/1-1.2.1/1-1.2.1:1.0/host6/target6:0:0/6:0:0:0
	PHYSDEVPATH_TMP=`echo ${PHYSDEVPATH} | sed -e 's#/\(.*\)\([0-9]*-[0-9]*\(\.*[0-9]*\)*\)/.*#\1\2#'`

	local BusDev=
	if [ -d "/sys/${PHYSDEVPATH_TMP}/" ]; then
		BusDev=`(cd /sys/${PHYSDEVPATH_TMP}/; ls -d usb_device:usbdev*) |  cut -d : -f 2 | cut -c 7-`
		#(6281)kernel 2.6.38 change the device file position
		if [ -z "${BusDev}" ]; then
			BusDev=`(cd /sys/${PHYSDEVPATH_TMP}/; ls -d usb_device/usbdev*) | sed 's/\//:/g' |  cut -d : -f 2 | cut -c 7-`
		fi
	fi

	if [ -n "${BusDev}" ]; then
		DEVICE="/proc/bus/usb/"

		Digtal=`echo ${BusDev} | cut -d . -f 1 | wc -c`
		Digtal=$((${Digtal}-1))         # Remove the \n count
		Digtal=$((3-${Digtal}))         # How many zero do we need
		while [ "$Digtal" -gt 0 ]
		do
			DEVICE="${DEVICE}0"
			Digtal=$((${Digtal}-1))
		done
		DEVICE=${DEVICE}`echo ${BusDev} | cut -d . -f 1`
		DEVICE="${DEVICE}/"

		Digtal=`echo ${BusDev} | cut -d . -f 2 | wc -c`
		Digtal=$((${Digtal}-1))		# Remove the \n count
		Digtal=$((3-${Digtal}))		# How many zero do we need
		while [ "$Digtal" -gt 0 ]
		do
			DEVICE="${DEVICE}0"
			Digtal=$((${Digtal}-1))
		done
		DEVICE=${DEVICE}`echo ${BusDev} | cut -d . -f 2`
	fi
}

# create hotplug ticket for hotplugd
prepare_tmp_files()
{
	if [ "yes" = "${SUPPORT_DUAL_HEAD}" -a "$AHA_LOCAL_ROLE" = "$AHA_PASSIVE_ROLE_STR" ]; then
		return
	fi

	hotplug_event_tmp="/tmp/tmp.hotplug.${SEQNUM}"
	echo "ACTION=$ACTION" > ${hotplug_event_tmp}
	echo "DEVICE=$DEVICE" >> ${hotplug_event_tmp}
	echo "DEVGUID=$DEVGUID" >> ${hotplug_event_tmp}
	echo "DEVNAME=`basename $DEVNAME`" >> ${hotplug_event_tmp}
	echo "DEVPATH=`basename $DEVPATH`" >> ${hotplug_event_tmp}
	echo "SUBSYSTEM=$SUBSYSTEM" >> ${hotplug_event_tmp}
	echo "PHYSDEVPATH=$PHYSDEVPATH" >> ${hotplug_event_tmp}
	echo "INTERFACE=$INTERFACE" >> ${hotplug_event_tmp}

	mv ${hotplug_event_tmp} /tmp/hotplug.${SEQNUM}
}

# create eunit hotplug ticket for hotplugd
prepare_eunit_hotplug_event_file()
{
	if [ "yes" = "${SUPPORT_DUAL_HEAD}" -a "$AHA_LOCAL_ROLE" = "$AHA_PASSIVE_ROLE_STR" ]; then
		return
	fi

	hotplug_event_tmp="/tmp/tmp.hotplug.${SEQNUM}"
	echo "ACTION=$ACTION" > ${hotplug_event_tmp}
	echo "DEVICE=$DEVICE" >> ${hotplug_event_tmp}
	echo "DEVNAME=`basename $DEVNAME`" >> ${hotplug_event_tmp}
	echo "DEVGUID=$DEVGUID" >> ${hotplug_event_tmp}
	echo "SYNO_PMP_EVENT=$SYNO_PMP_EVENT" >> ${hotplug_event_tmp}
	echo "MODALIAS=$MODALIAS" >> ${hotplug_event_tmp}

	mv ${hotplug_event_tmp} /tmp/hotplug.${SEQNUM}
}

prepare_hotplug_event_file()
{
	wait_sysfs_ready
	if [ -z "${DEVICE}" ]; then
		get_device
	fi

	if [ -z "${DEVGUID}" -a "${ACTION}" != "remove" ]; then
		get_device_guid
	fi

	prepare_tmp_files

	if [ "yes" = "${SUPPORT_DUAL_HEAD}" ]; then
		isSasDisk=`echo $DEVNAME | grep sas`
		if [ -n "$isSasDisk" ]; then
			/usr/syno/synoaha/bin/synoaha --hotplug-disk-event $ACTION $DEVNAME
		fi

		if [ "$AHA_LOCAL_ROLE" = "$AHA_PASSIVE_ROLE_STR" ]; then
			# AHA passive mode does not run hotplugd, so directly notify scemd
			/usr/syno/bin/syno_scemd_connector --disk_hotplug ${ACTION} ${DEVNAME}
		fi
	fi
}

SUPPORT_DUAL_HEAD=`/bin/get_key_value /etc.defaults/synoinfo.conf support_dual_head`
if [ "yes" = "${SUPPORT_DUAL_HEAD}" ]; then
	AHA_LOCAL_ROLE=`/usr/syno/synoaha/bin/synoaha --get-local-role`
	AHA_PASSIVE_ROLE_STR=`/usr/syno/synoaha/bin/synoahastr --role-passive`
fi

case "$1" in
	'prepare_hotplug_event_file')
		prepare_hotplug_event_file

		# notify hotplugd
		kill -s USR1 `cat /var/run/hotplugd.pid | head -1`
		;;
	'prepare_eunit_hotplug_event_file')
		prepare_eunit_hotplug_event_file

		# notify hotplugd
		kill -s USR1 `cat /var/run/hotplugd.pid | head -1`
		;;
	'prepare-device-boot-info')
		# touch file if system is booting up
		/usr/syno/bin/synobootseq --is-booting-up
		if [ 0 -eq $? ] && [ "add" == "$ACTION" ]; then
			/bin/touch /tmp/synobootingup.$DEVNAME
		else
			/bin/rm -f /tmp/synobootingup.$DEVNAME
		fi
		;;
	'tune-vdsm-disks')
		# increase medium access retries to avoid disk being put to offline
		find /sys/block/$2/device/scsi_disk/*/max_medium_access_timeouts -exec sh -c 'echo 1024 > {}' \;
		;;
	'create-vdsm-volumes')
		# Create vdsm volume
		/usr/syno/bin/synobootseq --is-ready
		if [ 0 -eq $? ]; then
			/usr/syno/bin/volumetool --create-vdsm-volumes $2 &
		fi
		;;
	*)
		echo "Usages: $0 prepare_hotplug_event_file"
		echo "	      $0 prepare_eunit_hotplug_event_file"
	;;
esac

#!/bin/sh
# Copyright (c) 2000-2013 Synology Inc. All rights reserved.

USBMODEM_INFO="/tmp/usbmodem.info"
ADD_HANDLER_LOCK="/tmp/lock/lock_add_usbmodem_info"
TTYDEBUG="/tmp/ttydebug"

# copy from usb.agent
get_usbdev_number ()
{
	local BusDev=""
	local Digtal=""
	local busnum=""
	local devnum=""

	DEVICE=""
	#To fix bug [16677], we should search usbdev number from the nearest dev entry.
	#So the search logic change to "/sys/${PHYSDEVPATH}/../", then "/sys/${PHYSDEVPATH}/../../../../".
	#ex: PHYSDEVPATH=/devices/pci0000:00/0000:00:0e.1/usb1/1-3/1-3:1.2/host11/target11:0:0/11:0:0:0
	#ex: PHYSDEVPATH=/devices/pci0000:00/0000:00:0e.1/usb1/1-3/1-3:1.1
	#ex: PHYSDEVPATH=/devices/platform/orion-ehci.0/usb1/1-1/1-1.2/1-1.2:1.2/host4/target4:0:0/4:0:0:0
	#ex: PHYSDEVPATH=/devices/platform/orion-ehci.0/usb1/1-1/1-1.2/1-1.2.1/1-1.2.1:1.0/host6/target6:0:0/6:0:0:0
	local PHYSDEVPATH_TMP=`echo ${PHYSDEVPATH} | sed -e 's#/\(.*\)\([0-9]*-[0-9]*\(\.*[0-9]*\)*\)/.*#\1\2#'`
	for i in `/usr/bin/seq 1 5`; do
		#If sysfs kobject not ready, we will retry 5 times
		BusDev=`(cd /sys/${PHYSDEVPATH_TMP}/; ls -d usb_device:usbdev*) |  cut -d : -f 2 | cut -c 7-`
		#(6281)kernel 2.6.38 change the device file position
		if [ -z "${BusDev}" ]; then
			BusDev=`(cd /sys/${PHYSDEVPATH_TMP}/; ls -d usb_device/usbdev*) | sed 's/\//:/g' |  cut -d : -f 2 | cut -c 7-`
		fi
		# Fix file path on northstarplus & liinux 3.10
		if [ -z "${BusDev}" -a ! -z $BUSNUM -a ! -z $DEVNUM ]; then
			BusDev=`/usr/bin/printf "%d.%d" $BUSNUM $DEVNUM`
		fi
		if [ "${BusDev}" != "" ]; then
			break;
		fi
		sleep 1;
	done
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
}

# find out if the node can use for connection
# which have keyword "Interrupt" in node's path
get_usbmodem_node_type_interrupt ()
{
	local current_node_num=$1
	# ex: /sys/devices/pci0000:00/0000:00:1d.7/usb6/6-3/6-3:1.4/ttyUSB4
	#  -> /sys/devices/pci0000:00/0000:00:1d.7/usb6/6-3/6-3:1.4/
	local devdirpath=`/usr/bin/dirname /sys$PHYSDEVPATH`
	# ex: /sys/devices/pci0000:00/0000:00:1d.7/usb6/6-3/6-3:1.4/ep_86/type:Interrupt
	local interrupt_node_cnt=`/bin/grep -r Interrupt $devdirpath | /usr/bin/wc -l`

	echo "interrupt_node_cnt $interrupt_node_cnt" >> $TTYDEBUG

	get_usbmodem_info_file_name
	local file="${USBMODEM_INFO_FILE}"

	CONNECTNODE=`/bin/cat $file | /bin/grep CONNECTNODE= | /usr/bin/cut -d '=' -f2`

	# interrupt node is not found
	if [ 0 -eq $interrupt_node_cnt ]; then
		return
	fi

	# most dongle has only one port with Interrupt
	# for some dongle, ex: sierra at&t
	# has more than one Interrupt node, ex: ttyUSB3 & ttyUSB4
	# first one should be query node
	# let the last one replace the previous one
	if [ -z "$CONNECTNODE" ] || [ "$current_node_num" -ge "$CONNECTNODE" ] ; then
		CONNECTNODE=$current_node_num
	fi

	echo "CONNECTNODE $CONNECTNODE" >> $TTYDEBUG
}

get_usbmodem_id ()
{
	local PHYSDEVPATH_TMP=`echo ${PHYSDEVPATH} | sed -e 's#/\(.*\)\([0-9]*-[0-9]*\(\.*[0-9]*\)*\)/.*#\1\2#'`
	local enum_path="`ls -d /sys/${PHYSDEVPATH_TMP}/usb_device:usbdev*`"

	# for different kernel version, the enum path may be different
	if [ -z "${enum_path}" ]; then
		enum_path="`ls -d /sys/${PHYSDEVPATH_TMP}/usb_device/usbdev*`"
	fi
	# Fix file path on northstarplus & liinux 3.10
	if [ -z "${enum_path}" ]; then
		enum_path="`ls -d /sys/${PHYSDEVPATH_TMP}/`"
	fi

	local timeout=1

	while [ 3 -ge ${timeout} ]; do
		USB_VENDOR=`cat $enum_path/device/idVendor`
		USB_PRODUCT=`cat $enum_path/device/idProduct`

		# Fix file path on northstarplus & liinux 3.10
		if [ -z "${USB_VENDOR}" ]; then
			USB_VENDOR=`cat $enum_path/idVendor`
		fi
		if [ -z "${USB_PRODUCT}" ]; then
			USB_PRODUCT=`cat $enum_path/idProduct`
		fi

		if [ ! -z "${USB_VENDOR}" -a ! -z "${USB_PRODUCT}" ]; then
			break
		fi

		timeout=`expr $timeout + 1`
		sleep 1;
	done
}

check_device_to_skip ()
{
	# Vendor=04d8 ProdID=000a
	# this is LCD monitor used by bromolow, driver is cdc-acm, but it is not usbmodem
	if [ "x04d8" == "x${USB_VENDOR}" -a "x000a" == "x${USB_PRODUCT}" ]; then
		exit 0
	fi
}

enum_tty_node_on_same_device ()
{
	get_usbmodem_info_file_name
	local file="${USBMODEM_INFO_FILE}"
	# ex: /dev/ttyUSB0 -> 0
	local current_node_num=`/bin/echo $DEVNAME | /bin/sed 's/[^0-99]//g'`

	DEVICENODE=`/bin/cat $file | /bin/grep DEVICENODE= | /usr/bin/cut -d '=' -f2`

	if [ -z "$DEVICENODE" ]; then
		DEVICENODE=$current_node_num
	else
		local nodearray=$DEVICENODE','$current_node_num
		# replace comma with newline, do sort, replace newline with comma, delete the last comma
		DEVICENODE=`/bin/echo $nodearray | /bin/sed 's/,/\n/g' | /usr/bin/sort -n | /usr/bin/tr '\n' ',' | /bin/sed s/.$//g`
	fi

	echo "DEVICENODE $DEVICENODE" >> $TTYDEBUG

	get_usbmodem_node_type_interrupt $current_node_num
}

remove_tty_node_on_same_device ()
{
	file="$1"
	# ex: /dev/ttyUSB0 -> 0
	local current_node_num=`/bin/echo $DEVNAME | /bin/sed 's/[^0-99]//g'`

	DEVICENODE=`/bin/cat $file | /bin/grep DEVICENODE= | /usr/bin/cut -d '=' -f2 | /bin/sed 's/,/ /g'`

	if [ -z "$DEVICENODE" ]; then
		return
	fi

	# remove the node number from array
	# ex: DEVICENODE=0,1,2,3	current_node_num=1
	#		nodearray shoud be 0,2,3
	local nodearray=""
	for eachnode in $DEVICENODE; do
		if [ "x$eachnode" = "x$current_node_num" ]; then
			continue
		fi

		if [ -z "$nodearray" ]; then
			nodearray="$eachnode"
		else
			nodearray="$nodearray,$eachnode"
		fi
	done

	DEVICENODE=$nodearray

	echo "DEVICENODE $DEVICENODE" >> $TTYDEBUG

	get_usbmodem_node_type_interrupt $current_node_num
}

get_usbmodem_info_file_name ()
{
	local busname=`echo ${DEVICE} | sed 's/\// /g' | awk '{print $4 $5}' | sed -e 's/^[0]*//'`
	local file="${USBMODEM_INFO}${busname}"
	USBMODEM_INFO_FILE="${file}"
}

search_usbmodem_info_by_devicenode ()
{
	# clean global value
	_USBMODEM_INFO_FILE="${USBMODEM_INFO}*"
	local usbmodem_info="${USBMODEM_INFO}*"
	local tty_dev="`/usr/bin/basename ${DEVNAME}`"
	local tty_dev_num="`/bin/echo ${tty_dev} | /bin/sed 's/^tty[A|U][C|S][M|B]//g'`"
	#local enum_all_device_node_info=`/usr/bin/find -name "/tmp/${usbmodem_info}" -exec /bin/get_key_value {} DEVICENODE \; | tr "," " "`

	for each in `/bin/ls ${usbmodem_info}`; do
		for i in `/bin/get_key_value ${each} DEVICENODE | /usr/bin/tr "," " "`; do
			if [ ${i} -eq ${tty_dev_num} ]; then
				_USBMODEM_INFO_FILE="${each}"
				break 2
			fi
		done
	done
}

update_usbmodem_info()
{
	local file=""
	local tmp_file=""

	if [ "add" = "$1" ]; then
		get_usbmodem_info_file_name
		file="${USBMODEM_INFO_FILE}"
		tmp_file="${file}.tmp"

		enum_tty_node_on_same_device
	else
		search_usbmodem_info_by_devicenode
		file="${_USBMODEM_INFO_FILE}"
		tmp_file="${file}.tmp"

		remove_tty_node_on_same_device "$file"
	fi

	# if all the node is removed, rm the info file
	if [ -z ${DEVICENODE} ]; then
		/bin/rm -f ${file} > /dev/null 2>&1
		return
	fi

	echo "DEVICENODE=${DEVICENODE}" > ${tmp_file}
	#find /sys${PHYSDEVPATH}/.. -type d >> ${tmp_file}.${DEVNAME}.$$

	# add device node prefix
	echo "DEVICENODE_PREFIX=${DEVICENODE_PREFIX}" >> ${tmp_file}

	# add connect node
	echo "CONNECTNODE=${CONNECTNODE}" >> ${tmp_file}

	# add usb vendor id
	echo "USB_VENDOR=${USB_VENDOR}" >> ${tmp_file}
	echo "USB_PRODUCT=${USB_PRODUCT}" >> ${tmp_file}

	cp ${tmp_file} ${file}
	rm ${tmp_file}
}

find_tty_device_node_prefix ()
{
	DEVICENODE_PREFIX=`/bin/echo ${DEVNAME} | /bin/sed -e 's/[0-99]$//g'`

}

enum_usbmodem_info ()
{
	local usbmodem_info_list=`ls /tmp/usbmodem.info*`
	GLOBAL_USBMODEM_INFO_LIST="${usbmodem_info_list}"

	#echo "[${GLOBAL_USBMODEM_INFO_LIST}]" >> /tmp/_tmp_enum_usbmodem_info.$$
}

check_dongles_number ()
{
	local usbmodem_info_num=`ls -l /tmp/usbmodem.info* | wc -l`
	get_usbmodem_info_file_name
	local file="${USBMODEM_INFO_FILE}"
	enum_usbmodem_info
	local exist_file="${GLOBAL_USBMODEM_INFO_LIST}"

	#echo "file: [${file}] exist_file: [${exist_file}]" > /tmp/_tmp_check_dongles_number.$$

	if [ 1 -le ${usbmodem_info_num} -a "${file}" != "${exist_file}" ]; then
		exit 0
	fi
}

set_debug_record()
{
	echo "=========================" >> $TTYDEBUG
	echo "action=$action" >> $TTYDEBUG
	env >> $TTYDEBUG
}

add_handler ()
{

	[ ! -d /tmp/lock ] && /bin/mkdir /tmp/lock
	(flock -x 666
		set_debug_record
		get_usbmodem_id
		check_device_to_skip
		get_usbdev_number
		check_dongles_number
		find_tty_device_node_prefix
		update_usbmodem_info "add"
	) 666>${ADD_HANDLER_LOCK}
}

remove_handler ()
{
	[ ! -d /tmp/lock ] && /bin/mkdir /tmp/lock
	(flock -x 666
		# for now multi-dongle are not supported.
		set_debug_record
		get_usbmodem_id
		check_device_to_skip
		get_usbdev_number
		find_tty_device_node_prefix
		update_usbmodem_info "remove"
	) 666>${ADD_HANDLER_LOCK}
}

action=$1
shift;

case $action in
	add)
		add_handler
		;;
	remove)
		remove_handler
		;;
	*)
		;;
esac

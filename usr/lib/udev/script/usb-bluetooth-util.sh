#!/bin/sh
# Copyright (c) 2000-2012 Synology Inc. All rights reserved.
USB_BLUETOOTH_MAP="/usr/syno/hotplug/usb.bluetooth.table"
BLUETOOTH_INFO="/tmp/bluetooth.info_"
BLUETOOTH_MODULE="crypto_algapi crypto_hash hid rfkill led-class compat bluetooth rfcomm hidp"
BFUSB_MODULE="${BLUETOOTH_MODULE} bfusb"
BTUSB_MODULE="${BLUETOOTH_MODULE} compat_firmware_class btbcm btintel btrtl btusb"
ATH3K_MODULE="${BLUETOOTH_MODULE} compat_firmware_class ath3k"
BPA10X_MODULE="${BLUETOOTH_MODULE} hci_uart bpa10x"
BCM203X_MODULE="${BLUETOOTH_MODULE} bcm203x"
PLATFORM=`/bin/uname -m`

##
# Workflow in plug-in dongle, plug-out dongle, enable bluetooth, disable bluetooth
# Because we need to handle multiple bluetooth dongles at the same time,
#   we should maintain how many devices plugged.
#
# 1. plug-in dongle -> 	create the info for the dongle (info#seqnum) and insert modules
# 2. plug-out dongle ->	remove the info for the dongle (get the first match info#seqnum)
##

reverse() {
	local modules=$1
	local mod
	local ret=""

	for mod in $modules; do
	    ret="$mod $ret"
	done
	echo $ret
}

insert_modules() {
	local MODULES="$@"
	for mod in ${MODULES}; do
		if [ -f /lib/modules/${mod}.ko ]; then
			/sbin/insmod /lib/modules/${mod}.ko >> /tmp/usbdebug
		else
			echo "Modules ${mod} non-exists in /lib/modules/" >> /tmp/usbdebug
		fi
	done
}

remove_modules() {
	local MODULES="$@"
	for mod in ${MODULES}; do
		/sbin/rmmod ${mod//-/_} >> /tmp/usbdebug
	done
}

select_modules () {
	local module=$1
	local action=$2
	local modules_file

	MODULE_FILES=""

	case "${module}" in
		btusb)
			modules_file=${BTUSB_MODULE}
			;;
		bfusb)
			modules_file=${BFUSB_MODULE}
			;;
		ath3k)
			modules_file=${ATH3K_MODULE}
			;;
		bpa10x)
			modules_file=${BPA10X_MODULE}
			;;
		bcm203x)
			modules_file=${BCM203X_MODULE}
			;;
		*)
			echo "Failed to search the suitable modules with vendor[${usb_vendor}] and product[${usb_product}]" >> /tmp/usbdebug
			return;
			;;
	esac
	MODULE_FILES=${modules_file}
}

list_using_modules() {
	local module_names=`grep -h MODULES ${BLUETOOTH_INFO}* | grep -v grep | sed 's/\=/ /g' | awk '{print $2}' | sort -u`
	local ret=""
	USING_MODULES=""

	for module_name in ${module_names}; do
		if [ "x${module_name}" != "x" ]; then
			select_modules ${module_name}
			local filelist=${MODULE_FILES}

			for mod in ${filelist}; do
				if [ -z "$(echo ${ret} | grep ${mod})" ]; then
					ret="${mod} ${ret}"
				fi
			done
		fi
	done

	USING_MODULES=${ret}
}

plug_in_usb_bluetooth () {
	select_modules $1
	local filelist=${MODULE_FILES}
	insert_modules ${filelist}
}

plug_out_usb_bluetooth () {
	select_modules $1
	local list=${MODULE_FILES}
	local filelist=""
	list_using_modules

	for mod in ${list}; do
		if [ -z "$(echo ${USING_MODULES} | grep ${mod})" ]; then
			filelist="${mod} ${filelist}"
		fi
	done
	if [ -n "${filelist}" ]; then
		remove_modules "${filelist}"
	fi
}

set_bluetooth_parameters () {
	usb_vendor=${SYNO_USB_VENDER}
	usb_product=${SYNO_USB_PRODUCT}
	product=${PRODUCT}
	modules=${SYNO_USB_DRIVER}

	if [ -z "${DEVICE}" ]; then
		#We use the SYNO_ATTR_BUSNUM_DEVNUM to compose the device
		#The device should be /proc/bus/usb/xxx/xxx
		if [ "." != "${SYNO_ATTR_BUSNUM_DEVNUM}" ]; then
			DEVICE=`echo ${SYNO_ATTR_BUSNUM_DEVNUM} | awk -F. '{printf("/proc/bus/usb/%03d/%03d", $1, $2)}'`
		fi
		#for linux 3.10, we use the USEC_INITIALIZED to replace the DEVICE
		busname=$USEC_INITIALIZED
	fi

	device=${DEVICE}
}

remove_bluetooth_info () {
	local infofile=${BLUETOOTH_INFO}${busname}

	if [ ! -f ${infofile} ]; then
		return 0
	fi

	/bin/rm ${infofile}
	echo "Remove file [${infofile}]" >> /tmp/usbdebug
	return 1
}

create_bluetooth_info () {
	local file="${BLUETOOTH_INFO}${busname}"

	if [ -f ${file} ]; then
		return 0
	fi

	echo "USV_VENDOR=${usb_vendor}" >> ${file}
	echo "USV_PRODUCT=${usb_product}" >> ${file}
	echo "PRODUCT=${product}" >> ${file}
	echo "MODULES=${modules}" >> ${file}
	echo "DEVICE=${device}" >> ${file}

	return 1
}

start_bluetooth () {
	echo "start bluetoothd" >> /tmp/usbdebug
	/usr/syno/sbin/synoservicectl --start bluetoothd
}

terminate_bluetooth () {
	echo "stop bluetoothd" >> /tmp/usbdebug
	/usr/syno/sbin/synoservicectl --stop bluetoothd
}

enable_bluetooth_modules () {
	echo "Insert the modules for the following device" >> /tmp/usbdebug
	echo "USV_VENDOR=${usb_vendor}" >> /tmp/usbdebug
	echo "USV_PRODUCT=${usb_product}" >> /tmp/usbdebug
	echo "PRODUCT=${product}" >> /tmp/usbdebug
	echo "MODULES=${modules}" >> /tmp/usbdebug
	echo "DEVICE=${device}" >> /tmp/usbdebug
	plug_in_usb_bluetooth ${modules}
}

disable_bluetooth_modules () {
	echo "Remove the modules for the following device" >> /tmp/usbdebug
	echo "USV_VENDOR=${usb_vendor}" >> /tmp/usbdebug
	echo "USV_PRODUCT=${usb_product}" >> /tmp/usbdebug
	echo "PRODUCT=${product}" >> /tmp/usbdebug
	echo "MODULES=${modules}" >> /tmp/usbdebug
	echo "DEVICE=${device}" >> /tmp/usbdebug
	plug_out_usb_bluetooth ${modules}
}

reload_auto_connect_config () {
	sleep 1
	local pid_from_cmd=`/bin/pidof btacd`
	local pid_from_file=

	if [ -r "/var/run/btacd.pid" ]; then
		pid_from_file=`/bin/cat /var/run/btacd.pid`
	fi

	if [ "x${pid_from_cmd}" != "x${pid_from_file}" ]; then
		echo "btacd is not ready for reload" >> /tmp/usbdebug
		echo "pid_from_cmd: (${pid_from_cmd})" >> /tmp/usbdebug
		echo "pid_from_file: (${pid_from_file})" >> /tmp/usbdebug
		return
	fi

	echo "Reload auto connect config...(${pid_from_file})" >> /tmp/usbdebug
	/sbin/reload btacd
}

action=$1
shift;
case $action in
	[Pp][Ll][Uu][Gg]-[Ii][Nn])
		runha=`/bin/get_key_value /etc/synoinfo.conf runha`

		if [ "xyes" = "x$runha" ]; then
			echo "ha enabled, skip bt dongle" >> /tmp/usbdebug
			exit;
		fi

		set_bluetooth_parameters "$@"
		create_bluetooth_info
		ret=$?
		if [ "1" = "${ret}" ]; then
			enable_bluetooth_modules
			start_bluetooth
		fi
		reload_auto_connect_config
		;;
	[Pp][Ll][Uu][Gg]-[Oo][Uu][Tt])
		set_bluetooth_parameters "$@"
		remove_bluetooth_info
		ret=$?
		if [ "1" = "${ret}" ]; then
			terminate_bluetooth
			disable_bluetooth_modules
		fi
		;;
	*)
		echo "Usage: [plug-in|plug-out]"
		;;
esac


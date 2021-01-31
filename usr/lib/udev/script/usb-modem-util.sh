#!/bin/sh
# Copyright (c) 2000-2014 Synology Inc. All rights reserved.

USBMODEM_INFO="/tmp/usbmodem.info"
USBMODEM_HANDLER_LOCK="/tmp/lock/lock_usbmodem_plug"
COMMON_MODULE="slhc ppp_generic ppp_async"
OPTION_MODULE="usbserial usb_wwan usb_wwan_syno option"
CDC_ACM_MODULE="cdc-acm"
SIERRA_MODULE="usbserial sierra"
DAEMON_NAME="synousbmodemd"
USBMODEM_BACKUP_GW="/etc/ppp/usbmodem_backup_gw"
MODEM_DEBUG="/tmp/usbmodem.debug"

select_modules () {
	local module=$@
	local dev_modulefiles

	for mod in ${module}; do
		case "${mod}" in
			option)
				eval dev_modulefiles=\"\${dev_modulefiles} ${OPTION_MODULE}\"
				;;
			cdc-acm)
				eval dev_modulefiles=\"\${dev_modulefiles} ${CDC_ACM_MODULE}\"
				;;
			sierra)
				eval dev_modulefiles=\"\${dev_modulefiles} ${SIERRA_MODULE}\"
				;;
			*)
				echo "Failed to search the suitable modules with vendor[${usb_vendor}] and product[${usb_product}]" >> ${MODEM_DEBUG}
				;;
		esac
	done

	# some driver ko file might not exist in some platform
	# ex: usb_wwan_syno.ko only exist in linux 3.x platform, and no usb_wwan.ko
	MODULE_FILES=${COMMON_MODULE}
	for mod in ${dev_modulefiles}; do
		if [ -f /lib/modules/${mod}.ko ]; then
			MODULE_FILES="$MODULE_FILES $mod"
		fi
	done
}

list_using_modules() {
	local module_names=`grep -h MODULES ${USBMODEM_INFO}* | grep -v grep | cut -d'=' -f2 | sort -u`
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

	if [ -n "${ret}" -o "$(pidof pppd)" ]; then
		USING_MODULES="${ret} ${COMMON_MODULE}"
	else
		USING_MODULES=${ret}
	fi
}

check_device_to_skip ()
{
	# Vendor=04d8 ProdID=000a
	# this is LCD monitor used by bromolow, driver is cdc-acm, but it is not usbmodem
	local lcd_exist=`/bin/cat /proc/bus/usb/devices | /bin/grep "Vendor=04d8 ProdID=000a" | /usr/bin/wc -l`
	local driver_is_acm=`/bin/echo "$@" | /bin/grep ${CDC_ACM_MODULE} | /usr/bin/wc -l`

	if [ 0 -lt ${lcd_exist} -a 0 -lt ${driver_is_acm} ]; then
		return 1
	fi

	return 0
}

insert_modules() {
	select_modules $@
	local list=${MODULE_FILES}

	check_device_to_skip $list
	if [ 1 == $? ]; then
		return
	fi

	for mod in ${list}; do
		if [ -f /lib/modules/${mod}.ko ]; then
			/sbin/insmod /lib/modules/${mod}.ko >> ${MODEM_DEBUG}
		else
			echo "Modules ${mod} non-exists in /lib/modules/" >> ${MODEM_DEBUG}
		fi
	done
}

remove_modules() {
	select_modules $@
	local list=${MODULE_FILES}
	local filelist=""
	list_using_modules

	check_device_to_skip $list
	if [ 1 == $? ]; then
		return
	fi

	for mod in ${list}; do
		if [ -z "$(echo ${USING_MODULES} | grep ${mod})" ]; then
			filelist="${mod} ${filelist}"
		fi
	done

	for mod in ${filelist}; do
		/sbin/rmmod ${mod//-/_} >> ${MODEM_DEBUG}
	done
}

plug_in_usbmodem () {
	[ ! -d /tmp/lock ] && /bin/mkdir /tmp/lock
	(flock -x 666
		insert_modules $modules
	) 666>${USBMODEM_HANDLER_LOCK}
}

plug_out_usbmodem () {
	[ ! -d /tmp/lock ] && /bin/mkdir /tmp/lock
	(flock -x 666
		remove_modules $modules
	) 666>${USBMODEM_HANDLER_LOCK}
}

force_remove_all_usbmodem () {
	local usbmodem_info_list=`/bin/ls ${USBMODEM_INFO}*`
	local usbmodem_device_table='/lib/udev/devicetable/usb.usbmodem.table'

	# this function called after synousbmodemd is killed
	sleep 1

	# even synousbmodemd is dead, wvdial connection might still exist
	/bin/killall /usr/syno/bin/wvdial
	sleep 15

	# remove pid files
	/bin/rm /tmp/usbmodem.pid.*

	# remove drivers and info files
	for info_file in $usbmodem_info_list; do
		local vendor_id=`/bin/grep USB_VENDOR $info_file | /bin/cut -d'=' -f 2`
		local product_id=`/bin/grep USB_PRODUCT $info_file | /bin/cut -d'=' -f 2`
		local format_vendor_id=`/usr/bin/printf "0x%04x" 0x${vendor_id}`
		local format_product_id=`/usr/bin/printf "0x%04x" 0x${product_id}`
		local module_name

		# check if the device is record in the usbmodem map
		# ex: (0x12D1:0x140C,option)
		module_name=`grep -m 1 -i $format_vendor_id:$format_product_id ${usbmodem_device_table} |
					cut -d',' -f2 | cut -d')' -f1 | awk '$1=$1' ORS=' '`

		# ex: VENDOR(0x12D1,option)
		if [ -z "${module_name}" ]; then
			module_name=`grep VENDOR ${usbmodem_device_table} | grep -m 1 -i $format_vendor_id |
					cut -d',' -f2 | cut -d')' -f1 | awk '$1=$1' ORS=' '`
		fi

		remove_modules $module_name
		rm -f $info_file
	done
}

set_usbmodem_parameters () {
	usb_vendor=${SYNO_USB_VENDER}
	usb_product=${SYNO_USB_PRODUCT}
	product=${PRODUCT}
	modules=${SYNO_USB_DRIVER}
	device=${DEVICE}
}

set_support_usbmodem_key ()
{
	local synoinfoconf='/etc/synoinfo.conf'
	local key='support_usbmodem'
	local value=$1

	/usr/syno/bin/synosetkeyvalue $synoinfoconf $key $value
}

get_support_usbmodem_status ()
{
	local synoinfoconf='/etc/synoinfo.conf'
	local key='support_usbmodem'
	local value=`/usr/syno/bin/synogetkeyvalue $synoinfoconf $key`

	if [ "nox" = "${value}x" ]; then
		echo "no"
		return 0
	else
		echo "yes"
		return 1
	fi
}

start_usbmodem_daemon () {
	local hasdaemon=`/bin/ps aux | grep ${DAEMON_NAME} | grep -v grep`
	local hasdbus=`/bin/ps aux | grep dbus-daemon | grep system | grep -v grep`
	local waitCount=0;
	local maxWaitCount=60;

	if [ "x${hasdaemon}" = "x" ]; then

		while [ "x${hasdbus}" = "x" ] && [ $waitCount -lt $maxWaitCount ]; do
			echo "Wait for dbus-daemon starting..." >> ${MODEM_DEBUG}
			sleep 1
			waitCount=`expr $waitCount + 1`
			hasdbus=`/bin/ps aux | grep dbus-daemon | grep system | grep -v grep`
		done

		if [ "x${hasdbus}" = "x" ]; then
			echo "Timeout. Skip starting ${DAEMON_NAME}" >> ${MODEM_DEBUG}
		else
			echo "dbus-daemon is running. Try to start ${DAEMON_NAME}..." >> ${MODEM_DEBUG}
			`/usr/syno/sbin/${DAEMON_NAME}`
			hasdaemon=`/bin/ps aux | grep ${DAEMON_NAME} | grep -v grep`

			if [ "x${hasdaemon}" = "x" ]; then
				echo "Failed to start ${DAEMON_NAME}" >> ${MODEM_DEBUG}
			else
				echo "${DAEMON_NAME} is running" >> ${MODEM_DEBUG}
			fi
		fi
	elif [ "x${hasdaemon}" != "x" ]; then
		# signal it
		echo "----------> signal it " >> ${MODEM_DEBUG}
    fi
}

terminate_usbmodem_daemon () {
	local hasdaemon=`/bin/ps aux | grep ${DAEMON_NAME} | grep -v grep`

	# exmaple:
	# echo $hasdaemon
	# root 16830 0.0 0.6 147284 6208 ? Ss 17:17 0:00 /usr/syno/sbin/synousbmodemd
	if [ "x${hasdaemon}" != "x" ]; then
		local pid=`echo ${hasdaemon} | awk '{print $2}'`
		`/bin/kill -15 ${pid}`
		local ret=$?
		echo "Try to terminate ${DAEMON_NAME}..." >> ${MODEM_DEBUG}
		if [ ${ret} -ne 0 ]; then
			echo "Failed to terminate ${DAEMON_NAME}:[${pid}, ${ret}]" >> ${MODEM_DEBUG}
		fi
		sleep 1
	elif [ "x${hasdaemon}" != "x" ]; then
		# signal it
			echo "<---------- signal it " >> ${MODEM_DEBUG}
	fi
}

# input of this script: "plug-in/out" "${usb_idVendor}" "${usb_idProduct}" "${PRODUCT}" "${USBMODEM_DRIVER}" "${DEVICE}"
echo "-----------" >> ${MODEM_DEBUG}
echo "`date`" >> ${MODEM_DEBUG}
echo "action:[${ACTION}]" >> ${MODEM_DEBUG}

action=$1
shift;
case $action in
	[Pp][Ll][Uu][Gg]-[Ii][Nn])
		get_support_usbmodem_status
		if [ 1 == $? ]; then
			set_usbmodem_parameters "$@"
			plug_in_usbmodem
			start_usbmodem_daemon
		fi
		;;
	[Pp][Ll][Uu][Gg]-[Oo][Uu][Tt])
		set_usbmodem_parameters "$@"
		terminate_usbmodem_daemon
		plug_out_usbmodem
		;;
	[Dd][Ii][Ss][Aa][Bb][Ll][Ee]-[Ss][Uu][Pp][Pp][Oo][Rr][Tt])
		set_support_usbmodem_key "no"
		terminate_usbmodem_daemon
		force_remove_all_usbmodem
		;;
	[Ee][Nn][Aa][Bb][Ll][Ee]-[Ss][Uu][Pp][Pp][Oo][Rr][Tt])
		set_support_usbmodem_key "yes"
		;;
	[Ii][Ss]-[Ss][Uu][Pp][Pp][Oo][Rr][Tt])
		get_support_usbmodem_status
		;;
	*)
		echo "Usage: [plug-in|plug-out][disable-support][enable-support][is-support]"
		;;
esac


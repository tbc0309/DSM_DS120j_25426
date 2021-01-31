#!/bin/sh

UDEV_TABLE_DIR="/lib/udev/devicetable"
WIFI_DRIVER_TABLE=$UDEV_TABLE_DIR/usb.wifi.table
BLUETOOTH_DRIVER_TABLE=$UDEV_TABLE_DIR/usb.bluetooth.table
USBMODEM_DRIVER_TABLE=$UDEV_TABLE_DIR/usb.usbmodem.table

SYNO_USB_DEVICE_WIFI="WIFI"
SYNO_USB_DEVICE_BLUETOOTH="BLUETOOTH"
SYNO_USB_DEVICE_MODEM="MODEM"

usb_idVendor=$1
usb_idProduct=$2

query_wifi_driver()
{
	local copy_usb_idVendor="0x`printf '%04x' ${usb_idVendor}`"
	local copy_usb_idProduct="0x`printf '%04x' ${usb_idProduct}`"
	local test_vender=`echo ${copy_usb_idVendor} | awk -F"0x" {'print $2'}`
	local test_product=`echo ${copy_usb_idProduct} | awk -F"0x" {'print $2'}`

	if [ -n "${SYNO_USB_DEVICE}" ]; then
		return;
	fi
	if [ ! -f "${WIFI_DRIVER_TABLE}" ]; then
		return;
	fi

	if [ -n ${test_vender} -a -n ${test_product} ]; then
		WIFI_DRIVER=`grep -i $test_vender: ${WIFI_DRIVER_TABLE} | grep -i $test_product, |  cut -d',' -f2 | cut -d')' -f1 | awk 'NR==1 {print $1}'`
	fi
	if [ -n "${WIFI_DRIVER}" ]; then
		SYNO_USB_DEVICE="${SYNO_USB_DEVICE_WIFI}"
		SYNO_USB_DRIVER="${WIFI_DRIVER}"
	fi
}

query_bluetooth_driver()
{
	local test_vendor=`echo ${usb_idVendor} | awk -F"0x" {'print $2'}`
	local test_product=`echo ${usb_idProduct} | awk -F"0x" {'print $2'}`

	if [ -n "${SYNO_USB_DEVICE}" ]; then
		return;
	fi
	if [ ! -f "${BLUETOOTH_DRIVER_TABLE}" ]; then
		return;
	fi
	if [ -n ${test_vendor} -a -n ${test_product} ]; then
		BLUETOOTH_DRIVER=`grep -i $test_vendor: ${BLUETOOTH_DRIVER_TABLE} | grep -i $test_product, |  cut -d',' -f2 | cut -d')' -f1 | awk 'NR==1 {print $1}'`
	fi
	if [ -z "${BLUETOOTH_DRIVER}" -a -n ${test_vendor} ]; then
		BLUETOOTH_DRIVER=`grep VENDOR ${BLUETOOTH_DRIVER_TABLE} | grep -i $test_vendor |  cut -d',' -f2 | cut -d')' -f1 | awk 'NR==1 {print $1}'`
	fi

	if [ -n "${BLUETOOTH_DRIVER}" ]; then
		SYNO_USB_DEVICE="${SYNO_USB_DEVICE_BLUETOOTH}"
		SYNO_USB_DRIVER="${BLUETOOTH_DRIVER}"
	fi
}

exec_usb_modeswitch_and_reset ()
{
	local vid=$1
	local pid=$2
	local file=$3

	if [ -z $vid -o -z $pid -o -z $file ]; then
		return
	fi

	# normally for device add, DEVPATH will be like
	# ex: /devices/pci0000:01/0000:01:01.0/usb2/2-1/2-1
	# others are device's interface add and has no "serial"
	# ex: /devices/pci0000:01/0000:01:01.0/usb2/2-1/2-1:1.0,
	# we want this function happened only once per device
	local serialfile="/sys/${DEVPATH}/serial"
	if [ ! -r "${serialfile}" ]; then
		exit 0
	fi

	# before really do the modeswitch, need to check the device is already show up or not
	# sometimes the hotplug event occurred, while the device didnt ready
	local timeout=0
	local check_cmd='/bin/cat /proc/bus/usb/devices | /bin/grep "Vendor='$vid' ProdID='$pid'" | /usr/bin/wc -l'
	while [ 10 -ge $timeout ]; do
		local ret=`eval $check_cmd`
		if [ 1 -le $ret ]; then
			break
		fi
		timeout=`expr $timeout + 1`
		sleep 1;
	done

	/usr/bin/usb_modeswitch -v $vid -p $pid -c $file -R -D

	# a workaround for Braswell USB3 (soc)
	# sometimes the modeswitch do not work at first time
	# need to switch again and again
	timeout=0
	while [ 10 -ge $timeout ]; do
		sleep 1

		local ret=`eval $check_cmd`
		if [ 1 -le $ret ]; then
			/usr/bin/usb_modeswitch -v $vid -p $pid -c $file -R -D
		else
			break;
		fi
		timeout=`expr $timeout + 1`
	done

	exit 0
}

exec_usb_modeswitch ()
{
	local vid=$1
	local pid=$2
	local file=$3

	if [ -z $vid -o -z $pid -o -z $file ]; then
		return
	fi

	# check DEVPATH is attached with usb-storages driver or not
	local storage=0
	if [ -r "/sys/${DEVPATH}/driver" ]; then
		storage=`/usr/bin/readlink /sys/${DEVPATH}/driver | /bin/grep -c usb-storage`
	fi
	# if this interface is not usb-storage
	# should return and do the else stuff, ex: driver insert
	if [ 1 -ne $storage ]; then
		return
	fi

	# before really do the modeswitch, need to check the device is already show up or not
	# sometimes the hotplug event occurred, while the device didnt ready
	local timeout=0
	local check_cmd='/bin/cat /proc/bus/usb/devices | /bin/grep "Vendor='$vid' ProdID='$pid'" | /usr/bin/wc -l'
	while [ 10 -ge $timeout ]; do
		local ret=`eval $check_cmd`
		if [ 1 -le $ret ]; then
			break
		fi
		timeout=`expr $timeout + 1`
		sleep 1;
	done

	/usr/bin/usb_modeswitch -v $vid -p $pid -c $file -D
	return
}

check_and_do_modeswitch ()
{
	# when usb device plug-in, will occurred several 'add' action
	# one device add, and multi-interface add
	if [ 'xadd' != "x${ACTION}" ]; then
		return
	fi

	local idvendor=`/usr/bin/printf "%04x" ${usb_idVendor}`
	local idproduct=`/usr/bin/printf "%04x" ${usb_idProduct}`
	local filelist=`ls /usr/share/usbmodem/usb_modeswitch.d/${idvendor}:${idproduct}*`

	# check if the switch file exist or not
	if [ -z $filelist ]; then
		return
	fi

	# FIXME
	# most config file in usb_modeswitch.d will like ${idvendor}:${idproduct}
	# but few is different, ex:
	# 0471:1210:uMa=Philips and 0471:1210:uMa=Wisue
	# but we dont have the device to test those issue
	# so now only take care the ${idvendor}:${idproduct} format
	for eachfile in ${filelist}
	do
		if [ ! -f "$eachfile" ]; then
			continue
		fi

		# do the switch, check the key TargetProduct in file
		# if exist, after the switch need reset usb
		local need_reset=`/bin/grep -c TargetProduct $eachfile`
		if [ 0 -eq $need_reset ]; then
			exec_usb_modeswitch ${idvendor} ${idproduct} ${eachfile}
		else
			exec_usb_modeswitch_and_reset ${idvendor} ${idproduct} ${eachfile}
		fi

		return
	done
}

query_usbmodem_driver_from_device_table()
{
	# idVendor and idProduct show be regular hex format
	echo "$usb_idVendor" | egrep "\b0[xX][0-9a-fA-F]+\b" > /dev/null
	if [ $? != 0 ]; then
		return;
	fi
	echo "$usb_idProduct" | egrep "\b0[xX][0-9a-fA-F]+\b" > /dev/null
	if [ $? != 0 ]; then
		return;
	fi

	# check if the device is record in the usbmodem map
	local idvendor=`/usr/bin/printf "0x%04x" ${usb_idVendor}`
	local idproduct=`/usr/bin/printf "0x%04x" ${usb_idProduct}`

	# ex: (0x12D1:0x140C,option)
	if [ -n ${idvendor} -a -n ${idproduct} ]; then
		USBMODEM_DRIVER=`grep -m 1 -i $idvendor:$idproduct ${USBMODEM_DRIVER_TABLE} |  cut -d',' -f2 | cut -d')' -f1 | awk '$1=$1' ORS=' '`
	fi
	# ex: VENDOR(0x12D1,option)
	if [ -z "${USBMODEM_DRIVER}" -a -n ${idvendor} ]; then
		USBMODEM_DRIVER=`grep VENDOR ${USBMODEM_DRIVER_TABLE} | grep -m 1 -i $idvendor |  cut -d',' -f2 | cut -d')' -f1 | awk '$1=$1' ORS=' '`
	fi
}

force_assign_usbmodem_module()
{
	local ifClass=
	local ifSubClass=
	local ifProtocol=

	if [ ! -z "${USBMODEM_DRIVER}" ]; then
		return
	fi

	# Vendor=04d8 ProdID=000a
	# this is LCD monitor used by bromolow rs3413xs+ and rs10613xs+
	# driver is cdc-acm, but it is not usbmodem
	if [ "x0x4d8" == "x${usb_idVendor}" -a "x0xa" == "x${usb_idProduct}" ]; then
		return
	fi

	# check should force assign usbmodem driver or not
	if [ -z $INTERFACE ]; then
		return
	fi

	ifClass=`/bin/echo $INTERFACE | /usr/bin/cut -d'/' -f1`
	ifSubClass=`/bin/echo $INTERFACE | /usr/bin/cut -d'/' -f2`
	ifProtocol=`/bin/echo $INTERFACE | /usr/bin/cut -d'/' -f3`

	if [ "x2" == "x$ifClass" -a "x2" == "x$ifSubClass" ]; then
		if [ 6 -ge $ifProtocol -a 1 -le $ifProtocol ]; then
			USBMODEM_DRIVER="cdc-acm"
			return
		fi
	fi
}
query_usbmodem_driver()
{
	if [ -n "${SYNO_USB_DEVICE}" ]; then
		return;
	fi
	check_and_do_modeswitch
	query_usbmodem_driver_from_device_table
	force_assign_usbmodem_module

	if [ -n ${USBMODEM_DRIVER} ]; then
		SYNO_USB_DEVICE="${SYNO_USB_DEVICE_MODEM}"
		SYNO_USB_DRIVER="${USBMODEM_DRIVER}"
	fi
}

query_usb_driver()
{
	SYNO_USB_DEVICE=""
	SYNO_USB_DRIVER=""

	if [ -z "${usb_idVendor}" -o -z "${usb_idProduct}" ]; then
		return;
	fi

	query_wifi_driver
	if [ -n "$SYNO_USB_DEVICE" -o -n "${SYNO_USB_DRIVER}" ]; then
		return;
	fi

	query_bluetooth_driver
	if [ -n "$SYNO_USB_DEVICE" -o -n "${SYNO_USB_DRIVER}" ]; then
		return;
	fi

	query_usbmodem_driver
	if [ -n "$SYNO_USB_DEVICE" -o -n "${SYNO_USB_DRIVER}" ]; then
		return;
	fi
}

is_Hub()
{
	local idvendor=`/usr/bin/printf "%04x" ${usb_idVendor}`
	local idproduct=`/usr/bin/printf "%04x" ${usb_idProduct}`
	local hubcount=`/bin/cat /proc/bus/usb/devices | /bin/grep "Vendor=$idvendor ProdID=$idproduct" -A5 \
		| /bin/grep "Cls" | /bin/cut -d '=' -f5 | /bin/grep -c hub`
	if [ "${hubcount}" != 0 ]; then
		return 0
	else
		return 1
	fi
}

is_Hub
if [ $? -eq 1 ]; then
	query_usb_driver
else
	echo "device <vid=${usb_idVendor} pid=${usb_idProduct}> is hub. skip query_usb_driver" >> /tmp/usbdebug
fi

echo "SYNO_USB_DEVICE=${SYNO_USB_DEVICE}"
echo "SYNO_USB_DRIVER=${SYNO_USB_DRIVER}"


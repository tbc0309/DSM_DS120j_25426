#!/bin/sh
# Copyright (c) 2000-2015 Synology Inc. All rights reserved.

. /usr/syno/bin/synoupscommon

mkdir -p $UPS_ROOT

UPS_DRV_CURR=$UPS_ROOT"/ups_drv.curr"
UPS_DRV_LIST=$UPS_ROOT"/ups_drv.list"
UPS_INFO=$UPS_ROOT"/ups.info"
UPS_DRV_BIN_NAME=""
UPS_VENDER_ID=""
UPS_PROD_ID=""
UPS_CONF="/usr/syno/etc/ups/ups.conf"
SUPPORT_XA=`/bin/get_key_value /etc/synoinfo.conf support_xa`

{
flock -x 58

SwitchConf2Usb() {
	/bin/sed -i "s/^\tport = .*/\tport = auto/" $UPS_CONF
	/bin/sed -i "s/.*community = .*/\t#community = /" $UPS_CONF
	/bin/sed -i "s/.*snmp_version = .*/\t#snmp_version = v2c/" $UPS_CONF
	/bin/sed -i "s/.*mibs = .*/\t#mibs = /" $UPS_CONF
	/bin/sed -i "s/.*secName = .*/\t#secName = /" $UPS_CONF
	/bin/sed -i "s/.*secLevel = .*/\t#secLevel = /" $UPS_CONF
	/bin/sed -i "s/.*authProtocol = .*/\t#authProtocol = /" $UPS_CONF
	/bin/sed -i "s/.*authPassword = .*/\t#authPassword = /" $UPS_CONF
	/bin/sed -i "s/.*privProtocol = .*/\t#privProtocol = /" $UPS_CONF
	/bin/sed -i "s/.*privPassword = .*/\t#privPassword = /" $UPS_CONF
}

IsDrvAlive() {
	if [ ! -e $UPS_DRV_CURR ]; then
		return 1
	fi
	local CUR_DRV=`cat ${UPS_DRV_CURR}`
	local cntDrv=`ps -aux |grep ${CUR_DRV}| grep -cv grep`
	if [ $cntDrv -gt 0 ]; then
		return 0
	else
		return 1
	fi
}

GetDrv() {
	if [ ! -e $UPS_DRV_LIST ]; then
		cp -af $NUTSCAN_USB_H $UPS_DRV_LIST
	fi
	# { 0x0001, 0x0000, "blazer_usb" }
	eval UPS_DRV_BIN_NAME=`grep -r "0x$1, 0x$2," ${UPS_DRV_LIST} |cut -d " " -f 4`
	if [ "x" != "x$UPS_DRV_BIN_NAME" ]; then
		return 0
	else
		return 1
	fi
}

DetectDrv() {
	local count_dev=`cat /proc/bus/usb/devices|grep -c P:`
	local sDev=''
	local i=-1
	for i in `seq 1 1 $count_dev`; do
		sDev=`cat /proc/bus/usb/devices|grep P:|sed -n "${i}p"`
		eval `echo $sDev| awk '{print $2}'` #Vendor=xxxx
		eval `echo $sDev| awk '{print $3}'` #ProdID=xxxx
		GetDrv ${Vendor} ${ProdID}
		if [ $? -eq 0 ]; then
			return 0
		fi
	done
	return 1
}

SaveDrv() {
#	grep 'driver =' $UPS_CONF|grep -v ^#|cut -d '=' -f 2|sed 's/^[[:space:]]*\(.*\)[[:space:]]*$/\1/' > $UPS_DRV_CURR
	/usr/syno/bin/synogetkeyvalue $UPS_CONF driver > $UPS_DRV_CURR
}

StartDrv() { #param: DRV_NAME
	sed -i "s/^\tdriver.*/\tdriver = $1/" $UPS_CONF
	/usr/bin/upsdrvctl ${ARG_PRODUCT} start

	if [ $? -ne 0 ]; then
		return 255
	fi
	return 0
}

StartAllDrv() {
	local DRV_LIST="usbhid-ups blazer_usb bcmxcp_usb richcomm_usb tripplite_usb"
	local iRet=1

	DetectDrv
	if [ $? -eq 0 ]; then
		StartDrv $UPS_DRV_BIN_NAME
		if [ $? -eq 0 ]; then
			DRV_NAME=$UPS_DRV_BIN_NAME
			return 0
		fi
	fi

	for URV in ${DRV_LIST}; do
		StartDrv $URV
		iRet=$?
		if [ $iRet -eq 0 ]; then
			DRV_NAME=$UPS_DRV_BIN_NAME
			break
		fi
	done

	if [ $iRet -ne 0 ]; then
		return 255
	fi
	return 0
}

StartUps() { #param: DRV_NAME
	DRV_NAME=$1
	local i=-1
	for i in `seq 1 1 3`; do
		IsDrvAlive
		if [ 1 -eq $? ]; then
			if [ "xusb" != "x${UpsMode}" ]; then
				StopUps
				SwitchConf2Usb
			fi
			if [ "x" == "x${DRV_NAME}" ]; then
				StartAllDrv
			else
				StartDrv $DRV_NAME
			fi
			if [ 0 -ne $? ]; then
				ShowLog "This UPS is not supported. product=[$PRODUCT], cmd=[$ARG_PRODUCT]"
				if [ $i -eq 3 ]; then
					return 255
				fi
			else
				ShowLog "The UPS is connected. driver=[$DRV_NAME]"
				SaveDrv
				break
			fi
		else
			ShowLog "UPS driver alive"
			if [ $i -eq 3 ]; then
				return 1
			fi
		fi
		sleep 3
	done

	# Slave enabled -> Master, disable both
	if [ $SlaveEnabled -eq 1 ] || [ "xusb" != "x${UpsMode}" ]; then
		/usr/syno/bin/synosetkeyvalue $SYNOINFO_CONF ups_enabled no
		/usr/syno/bin/synosetkeyvalue $SYNOINFO_CONF upsslave_enabled no
		MasterEnabled=0
		SlaveEnabled=0
	fi

	/usr/syno/bin/synosetkeyvalue $SYNOINFO_CONF ups_mode usb
	/usr/syno/bin/synosetkeyvalue $UPS_INFO upsmaster yes

	UPSWaitTime=`/bin/get_key_value $SYNOINFO_CONF ups_wait_time`
	/bin/sed -i "/^AT ONBATT/d" $UPSSCHED_CONF
	echo "AT ONBATT * EXECUTE onbatt" >> $UPSSCHED_CONF
	if [ "x$UPSWaitTime" != "x" ]; then
		echo "AT ONBATT * START-TIMER fsd ${UPSWaitTime}" >> $UPSSCHED_CONF
	fi

	echo "Start UPS Server"
	StartServer
	# Server daemon init time
	sleep 1

	if [ $MasterEnabled -eq 1 ]; then
		echo "Start UPS client"
		CheckUpsmonConf "local"
		StartClient
	fi
	return 0
}

if [ "$SUPPORT_XA" == "yes" ]; then
	exit 0
fi

case "$1" in
start)
	if [ "$PRODUCT" != "" ]; then
		UPS_VENDER_ID=`echo ${PRODUCT} | awk -F/ '{printf("%04s", $1);}' | sed 's: :0:g'`
		UPS_PROD_ID=`echo ${PRODUCT} | awk -F/ '{printf("%04s", $2);}' | sed 's: :0:g'`

		GetDrv $UPS_VENDER_ID $UPS_PROD_ID
		if [ 0 -eq $? ]; then
			StartUps $UPS_DRV_BIN_NAME
			if [ 0 -eq $? ]; then
				ShowLog "$0 $1 invoked."
			fi
		fi
	else
		StartUps
		if [ 0 -eq $? ]; then
			ShowLog "$0 $1 invoked."
		fi
	fi
	;;
stop)
    synobootseq --is-safe-shutdown
    if [ 0 -ne $? ]; then 
    	StopUps
		if [ 0 -eq $? ]; then
	    	/usr/syno/bin/synosetkeyvalue $UPS_INFO upsmaster no
			ShowLog "$0 $1 invoked."
		else
			ShowLog "$0 $1 failed."
		fi
    fi
	;;
restart)
	ShowLog "$0 $1 invoked."

	StopUps
	WaitStop
	StartUps
	;;
esac

flock -u 58
} 58<>$UPS_LOCK


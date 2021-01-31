#!/bin/sh
# Copyright (c) 2008-2015 Synology Inc. All rights reserved.

. /usr/syno/bin/synoupscommon

GET_KEY_VALUE="/bin/get_key_value"

if [ "xusb" == "x${UpsMode}" ]; then
	exit
fi

StartUps() { #param: START_TYPE(start, restart)
	local IsV6=0
	local SnmpVersion=`$GET_KEY_VALUE $SYNOINFO ups_snmp_version`
	local SnmpMib=`$GET_KEY_VALUE $SYNOINFO ups_snmp_mib`
	local SnmpUser=`$GET_KEY_VALUE $SYNOINFO ups_snmp_user`
	local SnmpAuth=`$GET_KEY_VALUE $SYNOINFO ups_snmp_auth`
	local SnmpAuthType=`$GET_KEY_VALUE $SYNOINFO ups_snmp_auth_type`
	local SnmpAuthKey=`$GET_KEY_VALUE $SYNOINFO ups_snmp_auth_key`
	local SnmpPrivacy=`$GET_KEY_VALUE $SYNOINFO ups_snmp_privacy`
	local SnmpPrivacyType=`$GET_KEY_VALUE $SYNOINFO ups_snmp_privacy_type`
	local SnmpPrivacyKey=`$GET_KEY_VALUE $SYNOINFO ups_snmp_privacy_key`
	local SnmpSecLevel="noAuthNoPriv"

	if [ -f "$UPS_CONF_BACKUP" ]; then
		/bin/cp $UPS_CONF_BACKUP $UPS_CONF
	fi

	if [ "$SnmpVersion" == "" ]; then
		SnmpVersion="v2c"
	fi

	if [ "$SnmpMib" == "" ]; then 
		SnmpMib="auto"
	fi

	if [ "$SnmpAuth" == "yes" ] && [ "$SnmpPrivacy" == "no" ] ; then
		SnmpSecLevel="authNoPriv"
	elif [ "$SnmpAuth" == "yes" ] && [ "$SnmpPrivacy" == "yes" ] ; then
		SnmpSecLevel="authPriv"
	else
		SnmpSecLevel="noAuthNoPriv"
	fi

	if [ 1 -eq $SlaveEnabled ]; then
		UpsmonServer=`/bin/get_key_value $SYNOINFO upsslave_server`
		IsV6=`echo ${UpsmonServer}|grep -c ':'`
		if [ 0 -lt $IsV6 ]; then
			UpsmonServer="[${UpsmonServer}]"
		fi
		if [ "x$UpsmonServer" = "x" ]; then
			echo "No upsmon server, disable upsmon"
			grep -vE "upsslave_enabled|upsslave_server" $SYNOINFO > /tmp/synoinfo.tmp
			mv /tmp/synoinfo.tmp $SYNOINFO
		else
			echo "Start upsmon"
			CheckUpsmonConf remote ${UpsmonServer}
			StartClient
		fi
		UPSWaitTime=`/bin/get_key_value $SYNOINFO ups_wait_time`
		/bin/sed -i "/^AT ONBATT/d" $UPSSCHED_CONF
		echo "AT ONBATT * EXECUTE onbatt" >> $UPSSCHED_CONF
		if [ "x$UPSWaitTime" != "x" ]; then
			echo "AT ONBATT * START-TIMER fsd ${UPSWaitTime}" >> $UPSSCHED_CONF
		fi
	elif [ 1 -eq $MasterEnabled ] && [ "xsnmp" == "x${UpsMode}" ]; then
		UpsmonIp=`/bin/get_key_value $SYNOINFO ups_snmp_ip`
		SnmpCommunity=`/bin/get_key_value $SYNOINFO ups_snmp_community`

		IsV6=`echo ${UpsmonIp}|grep -c ':'`
		if [ 0 -lt $IsV6 ]; then
			UpsmonIp="udp6:[${UpsmonIp}]"
		fi

		sed -i "s/^\tdriver.*/\tdriver = snmp-ups/" $UPS_CONF
		sed -i "s/^\tport = .*/\tport = ${UpsmonIp}/" $UPS_CONF
		sed -i "s/.*community = .*/\tcommunity = ${SnmpCommunity}/" $UPS_CONF
		sed -i "s/.*snmp_version = .*/\tsnmp_version = $SnmpVersion/" $UPS_CONF
	    sed -i "s/.*mibs = .*/\tmibs = $SnmpMib/" $UPS_CONF
		sed -i "s/.*secName = .*/\tsecName = $SnmpUser/" $UPS_CONF
		sed -i "s/.*secLevel = .*/\tsecLevel = $SnmpSecLevel/" $UPS_CONF
		sed -i "s/.*authProtocol = .*/\tauthProtocol = $SnmpAuthType/" $UPS_CONF
		sed -i "s/.*authPassword = .*/\tauthPassword = $SnmpAuthKey/" $UPS_CONF
		sed -i "s/.*privProtocol = .*/\tprivProtocol = $SnmpPrivacyType/" $UPS_CONF
		sed -i "s/.*privPassword = .*/\tprivPassword = $SnmpPrivacyKey/" $UPS_CONF

		CheckUpsmonConf "local"

		/usr/bin/upsdrvctl start

		retryCount=15
		while [ $retryCount -ne 0 ]
		do
			processCount=`ps aux| grep -v "grep" | grep -c "a ups"`
			if [ $processCount -eq 1 ] ; then
				break
			fi
			retryCount=`expr $retryCount - 1`
			/usr/bin/upsdrvctl start
			sleep 1
		done

		UPSWaitTime=`/bin/get_key_value $SYNOINFO ups_wait_time`
		/bin/sed -i "/^AT ONBATT/d" $UPSSCHED_CONF
		echo "AT ONBATT * EXECUTE onbatt" >> $UPSSCHED_CONF
		if [ "x$UPSWaitTime" != "x" ]; then
			echo "AT ONBATT * START-TIMER fsd ${UPSWaitTime}" >> $UPSSCHED_CONF
		fi

		sleep 1
		StartServer
		sleep 1
		StartClient
	fi
}

{
flock -x 58
case "$1" in
start)
	StartUps start
	;;
stop)
    synobootseq --is-safe-shutdown
    if [ 0 -ne $? ]; then 
	    # do nothing
    	StopUps
    fi
	;;
restart)
	StopUps
	WaitStop
	StartUps restart
	;;
esac

flock -u 58
} 58<>$UPS_LOCK

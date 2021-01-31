#!/bin/sh

SERVICE_UPS_USB="ups-usb"
SERVICE_UPS_NET="ups-net"

UPS_V_NAME="SYNO_UPS"
UPS_V_VERSION="2.6"
UPS_V_VENDOR="Synology Inc."
UPS_V_MODVER="1.0"

UPS_F_LOCK="/tmp/synoups.lock"

CheckSnmpUpsNeedRestart() {
	UPS_CONF_PORT=`/bin/get_key_value /usr/syno/etc/ups/ups.conf port`

	ping ${UPS_CONF_PORT} -w 5 -c 1

	return $?
}

UpsRestart() {
	UpsMode=`/bin/get_key_value /etc/synoinfo.conf ups_mode`
	# ups_mode will be empty when upgrade to 4.2
	if [ "x" = "x${UpsMode}" ]; then
		UpsMode="usb"
	fi

	if [ "usb" = "${UpsMode}" ]; then
        echo "[Event] $0 from ${IFNAME}, UPS mode=usb, no need to restart UPS service." >> /var/log/messages
	elif [ "snmp" = "${UpsMode}" ]; then
		CheckSnmpUpsNeedRestart
		if [ $? -ne 0 ]; then
			/usr/syno/sbin/synoservice --restart $SERVICE_UPS_NET
		else
			echo "[Event] $0 from ${IFNAME}, ping SNMP UPS success, no need to restart UPS service." >> /var/log/messages
		fi
	fi
}

case $1 in
	--sdk-mod-ver)
		#Print SDK support version
		echo ${UPS_V_MODVER};
	;;
	--name)
		#Print package name
		echo ${UPS_V_NAME};
	;;
	--pkg-ver)
		#Print package name
		echo ${UPS_V_VERSION};
	;;
	--vendor)
		#Printf package vendor
		echo ${UPS_V_VENDOR};
	;;
	--pre)
		#Actions before share set
        echo "Do Nothing";
	;;
	--post)
	{
		if  [ `echo ${IFNAME} | cut -c 1-3` = "eth" ] ||
			[ `echo ${IFNAME} | cut -c 1-4` = "wlan" ] ||
			[ `echo ${IFNAME} | cut -c 1-4` = "bond" ]; then
			MSG="[Event] $0 from ${IFNAME}, restart UPS service."
		else
			exit 0
        fi

		if flock -n -x 7; then
			cntUpsMon=`ps -aux |grep '/usr/sbin/upsmon' |grep -cv grep`
			if [ 0 -lt $cntUpsMon ]; then
				sleep 5
				echo $MSG >> /var/log/messages
				UpsRestart
			fi
			flock -u 7
		fi
	} 7<>${UPS_F_LOCK} &
	;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac


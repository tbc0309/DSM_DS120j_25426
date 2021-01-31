#!/bin/sh
#
# Set the configuration file of the default gateway.
#
# @param MASTER [IN]
#		The interface name of the bonding master, e.g. "bond0".
# @param SLAVES [IN]
#		The interface name of the bonding slaves separated by comma, e.g. "eth0,eth1".
# @param ACTION [IN]
#		Two possible values.
#		1. "create": this is a hook event of creating a bonding interface
#		2. "delete": this is a hook event of deleting a bonding interface
#

DEFAULT_GATEWAY_FILE="/etc/iproute2/config/default-gateway"
DEFAULT_GATEWAY_V6_FILE="/etc/iproute2/config/default-gateway-v6"

case $1 in
	--sdk-mod-ver)
	#Print SDK support version
	echo "1.0";
	;;
	--name)
	#Print package name
	echo "SynorouterClient"
	;;
	--pkg-ver)
	#Print package version
	echo "1.0";
	;;
	--vendor)
	#Print package vendor
	echo "Synology";
	;;
	--pre)
		DEVICE=`/bin/get_key_value ${DEFAULT_GATEWAY_FILE} DEVICE`
		DEVICE_V6=`/bin/get_key_value ${DEFAULT_GATEWAY_V6_FILE} DEVICE`
		TMP="/tmp/gw_tmp"

		if [ "${ACTION}" = "delete" ]; then
			SLAVE_DEV=`echo ${SLAVES} | cut -d ',' -f 1`

			if [ "${DEVICE}" = "${MASTER}" ]; then
				/usr/syno/bin/synosetkeyvalue ${DEFAULT_GATEWAY_FILE} DEVICE ${SLAVE_DEV}
				sed 's/\"//g' ${DEFAULT_GATEWAY_FILE} > ${TMP}
				mv ${TMP} ${DEFAULT_GATEWAY_FILE}
			fi
			if [ "${DEVICE_V6}" = "${MASTER}" ]; then
				/usr/syno/bin/synosetkeyvalue ${DEFAULT_GATEWAY_FILE} DEVICE ${SLAVE_DEV}
				sed 's/\"//g' ${DEFAULT_GATEWAY_FILE} > ${TMP}
				mv ${TMP} ${DEFAULT_GATEWAY_FILE}
			fi
		elif [ "${ACTION}" = "create" ]; then
			# if gateway is in our bonding slave

			if [ "" != "`echo ${SLAVES} | grep ${DEVICE}`" ]; then
				/usr/syno/bin/synosetkeyvalue ${DEFAULT_GATEWAY_FILE} DEVICE ${MASTER}
				sed 's/\"//g' ${DEFAULT_GATEWAY_FILE} > ${TMP}
				mv ${TMP} ${DEFAULT_GATEWAY_FILE}
			fi
			if [ "" != "`echo ${SLAVES} | grep ${DEVICE_V6}`" ]; then
				/usr/syno/bin/synosetkeyvalue ${DEFAULT_GATEWAY_FILE} DEVICE ${MASTER}
				sed 's/\"//g' ${DEFAULT_GATEWAY_FILE} > ${TMP}
				mv ${TMP} ${DEFAULT_GATEWAY_FILE}
			fi
		fi
	;;
	*)
	echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac


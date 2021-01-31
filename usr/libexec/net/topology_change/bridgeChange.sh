#!/bin/sh

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

		if [ "${OLD_TOPOLOGY}" = "bridge" ]; then
			if [ "${DEVICE}" = "br0" ]; then
				sed -i 's/DEVICE=br0/DEVICE=eth0/g' ${DEFAULT_GATEWAY_FILE}
			fi
			if [ "${DEVICE_V6}" = "br0" ]; then
				sed -i 's/DEVICE=br0/DEVICE=eth0/g' ${DEFAULT_GATEWAY_V6_FILE}
			fi
		fi
		if [ "${NEW_TOPOLOGY}" = "bridge" ]; then
			if [ "${DEVICE}" = "eth0" ]; then
				sed -i 's/DEVICE=eth0/DEVICE=br0/g' ${DEFAULT_GATEWAY_FILE}
			fi
			if [ "${DEVICE_V6}" = "eth0" ]; then
				sed -i 's/DEVICE=eth0/DEVICE=br0/g' ${DEFAULT_GATEWAY_V6_FILE}
			fi
		fi
	;;
	*)
	echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac


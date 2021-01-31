#!/bin/sh
#delete routing rule when no link of static IP

del_route()
{
	if [ "tun0" = "${IFNAME}" -o "ppp200" = "${IFNAME}" -o "ppp300" = "${IFNAME}" -o "ntb_eth" = "${IFNAME:0:7}" ]; then
		return 0;
	fi

	if [ -d "/sys/devices/virtual/net/ovs_${IFNAME}" ] && [ "${IFNAME#eth*}" != "${IFNAME}" ] ; then
		IFNAME="ovs_${IFNAME}"
	fi

	local ADDRESS=`/sbin/ip addr | grep -w ${IFNAME} | grep inet | grep -v -E "AHA|ntb" | cut -d " " -f "6"`
	if [ "" != "$ADDRESS" ]; then
		local SUBNET=`/bin/ipcalc -n $ADDRESS | cut -d "=" -f 2`/`echo $ADDRESS | cut -d "/" -f 2`
	fi

	if [ "x" != "x${SUBNET}" -a "false" = "$IS_LINK" ]; then
		/sbin/ip route del ${SUBNET} dev ${IFNAME}
	fi
}

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
        --post)
		del_route
        ;;
        *)
        echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
        ;;
esac

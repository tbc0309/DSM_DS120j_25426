#!/bin/sh
#For event hook which has pre and post call, also for webapi call
SZF_INTERFACE_ROUTING_TABLE_LOCK="/tmp/syno_interface_routing_table.lock"
LOGGER="/usr/bin/logger"
IPROUTE2_CONFIG="/etc/iproute2/config"

log_msg()
{
        ${LOGGER} -s -p warn -t "Policy routing table" "$1"
}

routing_table_remove(){
        for ifn in `synonetdtool --get-interface-by-class -4 ethernet | sed -e 's/,/\n/g'`
        do
                local IFCFG_FILE="/etc/sysconfig/network-scripts/ifcfg-${ifn}"
                local BOOTPROTO=`get_key_value ${IFCFG_FILE} BOOTPROTO`
                if [ "${BOOTPROTO}" = "static" ]; then
                        local IPADDR=`get_key_value ${IFCFG_FILE} IPADDR`
                elif [ "${BOOTPROTO}" = "dhcp" ]; then
                        local DHCP_FILE="/etc/dhclient/ipv4/dhcpcd-${ifn}.info"
                        local IPADDR=`get_key_value ${DHCP_FILE} IPADDR`
                elif [ "${BOOTPROTO}" = "none" ]; then
                        continue
                fi

                synonetdtool --del-policy-route-rule -4 ${ifn}_policy ${ifn}
                synonetdtool --refresh-route-table -4 ${ifn} ${IPADDR}
        done

        for ifn in `synonetdtool --get-interface-by-class -6 ethernet | sed -e 's/,/\n/g'`
        do
                IPADDR_LIST=""
		NUM=`/sbin/ifconfig ${ifn} | grep inet6 | wc -l`
		for i in `seq 1 $NUM`
                do
                        IPADDR_INFO=`/sbin/ip addr show ${ifn} | grep inet6 | sed -n ${i}p`
                        SCOPE=`echo ${IPADDR_INFO} | awk -F" " '{print $4}'`
                        IPADDR_MASK=`echo ${IPADDR_INFO} | awk -F" " '{print $2}'`
                        IPADDR=`echo ${IPADDR_MASK} | awk -F"/" '{print $1}'`
                        echo ${SCOPE} ${IPADDR} ${NETMASK} ${i} ${ifn}_policy_v6_${SCOPE}_${i}
                        synonetdtool --del-policy-route-rule -6 ${ifn}_policy_v6_${SCOPE}_${i} ${ifn}
                        IPADDR_LIST="${IPADDR_LIST},${IPADDR}"
                done
                IPADDR_LIST=`echo $IPADDR_LIST | cut -c2-`
                synonetdtool --refresh-route-table -6 ${ifn} ${IPADDR_LIST}
        done
        /sbin/ip route flush cache
}

routing_table_build(){
        for ifn in `synonetdtool --get-interface-by-class -4 ethernet | sed -e 's/,/\n/g'`
        do
                echo $ifn
                local IFCFG_FILE="/etc/sysconfig/network-scripts/ifcfg-${ifn}"
                local BOOTPROTO=`get_key_value ${IFCFG_FILE} BOOTPROTO`
                if [ "${BOOTPROTO}" = "static" ]; then
                        local IPADDR=`get_key_value ${IFCFG_FILE} IPADDR`
                        local NETMASK=`get_key_value ${IFCFG_FILE} NETMASK`
                elif [ "${BOOTPROTO}" = "dhcp" ]; then
                        local DHCP_FILE="/etc/dhclient/ipv4/dhcpcd-${ifn}.info"
                        local IPADDR=`get_key_value ${DHCP_FILE} IPADDR`
                        local NETMASK=`get_key_value ${DHCP_FILE} NETMASK`
                elif [ "${BOOTPROTO}" = "none" ]; then
                        continue
                fi

                echo ${IPADDR} ${NETMASK}
                if [ ! -n ${IPADDR} ] || [ ! -n ${NETMASK} ]; then
                        log_msg "Something wrong => IP:${IPADDR}, MASK:${NETMASK}"
                        log_msg "Stop build routing table for interfaces! Do routing table remove to clean eviroment!"
                        exit 1
                        break
                fi

                synonetdtool --add-policy-route-rule -4 ${ifn}_policy ${ifn} ${IPADDR} ${NETMASK} ${IPADDR}
                synonetdtool --refresh-route-table -4 ${ifn} ${IPADDR}
        done

        for ifn in `synonetdtool --get-interface-by-class -6 ethernet | sed -e 's/,/\n/g'`
        do
                IPADDR_LIST=""
		NUM=`/sbin/ifconfig ${ifn} | grep inet6 | wc -l`
		for i in `seq 1 $NUM`
                do
                        IPADDR_INFO=`/sbin/ip addr show ${ifn} | grep inet6 | sed -n ${i}p`
                        SCOPE=`echo ${IPADDR_INFO} | awk -F" " '{print $4}'`
                        IPADDR_MASK=`echo ${IPADDR_INFO} | awk -F" " '{print $2}'`
                        IPADDR=`echo ${IPADDR_MASK} | awk -F"/" '{print $1}'`
                        NETMASK=`echo ${IPADDR_MASK} | awk -F"/" '{print $2}'`
                        echo ${SCOPE} ${IPADDR} ${NETMASK}
                        synonetdtool --add-policy-route-rule -6 ${ifn}_policy_v6_${SCOPE}_${i} ${ifn} ${IPADDR} ${NETMASK} NULL
                        IPADDR_LIST="${IPADDR_LIST},${IPADDR}"
                done
                IPADDR_LIST=`echo $IPADDR_LIST | cut -c2-`
                echo $IPADDR_LIST
                synonetdtool --refresh-route-table -6 ${ifn} ${IPADDR_LIST}
        done
        /sbin/ip route flush cache
}


case $1 in
	--webapi-start)
        routing_table_build #for webapi call
        ;;
	--webapi-stop)
        routing_table_remove #for webapi call
        ;;
	--sdk-mod-ver)
	#Print SDK support version
	echo "1.0";
	;;
	--name)
	#Print package name
	echo "";
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
        routing_table_remove
        ;;
	--post)
	# do nothing when interface change on shutdown step
	if /usr/syno/bin/synobootseq --is-shutdown > /dev/null 2>&1 ; then
		exit
	fi
        routing_table_build
	;;
	*)
	echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac


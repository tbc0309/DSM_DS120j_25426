#!/bin/sh
# Copyright (c) 2000-2012 Synology Inc. All rights reserved.

ETC_TEMPLATE="/usr/syno/etc/synovpnclient/template"
DEF_TEMPLATE="/usr/syno/etc.defaults/synovpnclient/template"

VPNC_CONNECTING="/usr/syno/etc/synovpnclient/vpnc_connecting"
IP_DOWN="/usr/syno/etc.defaults/synovpnclient/scripts/ip-down"

VPNC_LAST_CONNECT="/usr/syno/etc/synovpnclient/vpnc_last_connect"
VPNC_CURR="/tmp/vpnc_current"
VPNC_SHUTDOWN="/tmp/vpnc_shutdown"

start() {
	# check if config need to upgrade
	/usr/syno/bin/synovpnc update_conf
	#remove old templates
	rm -rf ${ETC_TEMPLATE}

	# auto reconnect
	if [ -e "${VPNC_LAST_CONNECT}" ]; then
		/usr/bin/killall synovpnc 2>/dev/null
		eval `/bin/grep '^proto=' ${VPNC_LAST_CONNECT}`
		eval `/bin/grep '^conf_name=' ${VPNC_LAST_CONNECT}`
		eval `/bin/grep '^reconnect=' ${VPNC_LAST_CONNECT}`
		eval `/bin/grep '^kill=' ${VPNC_LAST_CONNECT}`
        if [ "yes" = "${reconnect}" ] && [ "yes" != "${kill}" ]; then
			reconnect_times=10
			/bin/cp ${VPNC_LAST_CONNECT} ${VPNC_CONNECTING}
			/usr/syno/bin/synovpnc reconnect --protocol=${proto} --name=${conf_name} --keepfile
			if [ $? != 0 ]; then
				reconnect_times=$(($reconnect_times-1))
				/usr/syno/bin/synovpnc reconnect --protocol=${proto} --name=${conf_name} --retry=${reconnect_times} --interval=30 &
			fi
		fi
	fi
}

# kill the process of vpn client
# ip-down will do auto-reconnect
stop() {
	/usr/bin/killall synovpnc 2>/dev/null
	if [ -e "${VPNC_CURR}" ]; then
		eval `/bin/grep '^conf_id=' ${VPNC_CURR}`
		eval `/bin/grep '^proto=' ${VPNC_CURR}`
		if [ "openvpn" = "${proto}" ]; then
                        /bin/kill `cat /var/run/ovpn_client.pid` 2>/dev/null
		else
			#pptp
                        pid=`cat /var/run/ppp-vpn_${conf_id}.pid | head -1`
                        # kill pptp will signal ip-down script
                        /bin/kill ${pid} 2>/dev/null
		fi
	fi
}

# generate "vpnc_shutdown" for ip-down to create "vpnc_connecting" but not do auto-reconnect
shutdown() {
	if [ -e "${VPNC_CURR}" ]; then
		/bin/touch ${VPNC_SHUTDOWN}
		stop
	fi
}

disconnect() {
	/usr/syno/bin/synovpnc kill_client
}

case $1 in
start)
        start
        ;;
stop)
        stop
        ;;
shutdown)
        shutdown
        ;;
disconnect)
        disconnect
        ;;
*)
        echo "Usages: $0 [start|stop|shutdown|disconnect]"
        ;;
esac

#!/bin/sh
#
# Startup script for openvpn client
#

CONF_DIR="/usr/syno/etc/synovpnclient/openvpn"
OPENVPN_CONF="$2"
IPTABLES_MODULE_LIST="/usr/syno/etc.defaults/iptables_modules_list"
OVPNC_MODULES="tun.ko"
SERVICE="ovpnc"
BIN_IPTABLESTOOL="/usr/syno/bin/iptablestool"
BIN_SYNOMODULETOOL="/usr/syno/bin/synomoduletool"
SYNONETD_TOOL="/usr/syno/sbin/synonetdtool"
VPNC_CURRENT="/tmp/vpnc_current"

. ${IPTABLES_MODULE_LIST}

Ovpnc_Mod=""
for mod in $KERNEL_MODULES_CORE; do
	if [ -e "/lib/modules/$mod" ]; then
		Ovpnc_Mod="${Ovpnc_Mod} ${mod}"
	fi
done
for mod in $KERNEL_MODULES_COMMON; do
	if [ -e "/lib/modules/$mod" ]; then
		Ovpnc_Mod="${Ovpnc_Mod} ${mod}"
	fi
done
for mod in $KERNEL_MODULES_NAT; do
	if [ -e "/lib/modules/$mod" ]; then
		Ovpnc_Mod="${Ovpnc_Mod} ${mod}"
	fi
done
for mod in $IPV6_MODULES; do
	if [ -e "/lib/modules/$mod" ]; then
		Ovpnc_Mod="${Ovpnc_Mod} ${mod}"
	fi
done
for mod in $OPENVPN_MODULES; do
	if [ -e "/lib/modules/$mod" ]; then
		Ovpnc_Mod="${Ovpnc_Mod} ${mod}"
	fi
done

reverse_modules() {
	local modules=$1
	local mod
	local ret=""

	for mod in $modules; do
	    ret="$mod $ret"
	done

	echo $ret
}

load_module() {
	local service=$1

	if [ -x ${BIN_SYNOMODULETOOL} ]; then
		${BIN_SYNOMODULETOOL} --insmod ${service} ${Ovpnc_Mod}
	elif [ -x ${BIN_IPTABLESTOOL} ]; then
		${BIN_IPTABLESTOOL} --insmod ${service} ${Ovpnc_Mod}
	fi
}

unload_module() {
	local service=$1
	local modules=`reverse_modules "${Ovpnc_Mod}"`

	if [ -x ${BIN_SYNOMODULETOOL} ]; then
		${BIN_SYNOMODULETOOL} --rmmod ${service} $modules
	elif [ -x ${BIN_IPTABLESTOOL} ]; then
		${BIN_IPTABLESTOOL} --rmmod ${service} $modules
	fi
}

del_gateway_info() {
	local ifname=`/usr/syno/bin/get_section_key_value ${VPNC_CURRENT} curr_info if`

	logger -p user.err -t "ovpnc.sh" "${ifname} is down"

	${SYNONETD_TOOL} --del-gateway-info -4 ${ifname}
	${SYNONETD_TOOL} --del-gateway-info -6 ${ifname}
	${SYNONETD_TOOL} --refresh-gateway all

	local enable_multi_gateway=`/bin/get_key_value /etc/synoinfo.conf multi_gateway`
	if [ "xyes" = "x${enable_multi_gateway}" ]; then
		${SYNONETD_TOOL} --del-policy-route-rule -4 multi-gateway ${ifname}
		${SYNONETD_TOOL} --disable-route-table -4 ${ifname}
		${SYNONETD_TOOL} --del-policy-route-rule -6 multi-gateway ${ifname}
		${SYNONETD_TOOL} --disable-route-table -6 ${ifname}
	fi
}

case "$1" in
  start)
	echo 1 > /proc/sys/net/ipv4/ip_forward

	# Make device if not present (not devfs)
	if [ ! -c /dev/net/tun ]; then
  		# Make /dev/net directory if needed
  		if [ ! -d /dev/net ]; then
        		mkdir -m 755 /dev/net
  		fi
  		mknod /dev/net/tun c 10 200
	fi

	load_module ${SERVICE}

        echo "Starting openvpn client..."
	/usr/sbin/openvpn --daemon --cd ${CONF_DIR} --config ${OPENVPN_CONF} --writepid /var/run/ovpn_client.pid

        ;;
  stop)
        echo "Stopping openvpn client..."
        /bin/kill `cat /var/run/ovpn_client.pid` 2>/dev/null
		del_gateway_info

	#sleep 2
	#unload_module ${SERVICE}
	;;
  load)
	service=${SERVICE}

	if [ -n "$2" ]; then
		service=$2
	fi

	load_module ${service}
	;;
  unload)
	service=${SERVICE}

	if [ -n "$2" ]; then
		service=$2
	fi

	#unload_module ${service}
	;;
  *)
        echo "Usage: $0 {start conf|stop}"
        exit 1
esac

exit 0

# [EOF]


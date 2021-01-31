#!/bin/sh

L2TPC_MODULES="slhc.ko ppp_generic.ko ppp_async.ko arc4.ko ppp_mppe.ko bsd_comp.ko zlib_inflate.ko zlib_deflate.ko ppp_deflate.ko"
SERVICE="l2tpc"
BIN_IPTABLESTOOL="/usr/syno/bin/iptablestool"
BIN_SYNOMODULETOOL="/usr/syno/bin/synomoduletool"
CONF_DIR="/usr/syno/etc/synovpnclient/l2tp"
L2TP_CONF="${CONF_DIR}/$2"
KERNEL_VERSION=`uname -r`
IPTABLES_MODULE_LIST="/usr/syno/etc.defaults/iptables_modules_list"

case "$KERNEL_VERSION" in
"3.6."*|"3.10."*)
	IPSec_MODULES="hmac.ko xfrm_algo.ko xfrm_user.ko af_key.ko xfrm_ipcomp.ko ah4.ko ah6.ko esp4.ko esp6.ko tunnel4.ko tunnel6.ko xfrm4_tunnel.ko xfrm6_tunnel.ko ipcomp.ko ipcomp6.ko authenc.ko authencesn.ko deflate.ko xfrm4_mode_beet.ko xfrm6_mode_beet.ko xfrm4_mode_tunnel.ko xfrm6_mode_tunnel.ko xfrm4_mode_transport.ko xfrm6_mode_transport.ko"
	;;
*)
	IPSec_MODULES="hmac.ko xfrm_user.ko af_key.ko xfrm_ipcomp.ko ah4.ko ah6.ko esp4.ko esp6.ko tunnel4.ko tunnel6.ko xfrm4_tunnel.ko xfrm6_tunnel.ko ipcomp.ko ipcomp6.ko authenc.ko authencesn.ko deflate.ko xfrm4_mode_beet.ko xfrm6_mode_beet.ko xfrm4_mode_tunnel.ko xfrm6_mode_tunnel.ko xfrm4_mode_transport.ko xfrm6_mode_transport.ko"
	;;
esac

if [ -x "/usr/sbin/ipsec" ]; then
	IPSEC_SBIN="/usr/sbin/ipsec"
elif [ -x "/usr/local/sbin/ipsec" ]; then
	IPSEC_SBIN="/usr/local/sbin/ipsec"
else
	exit 1
fi

reverse_modules() {
	local modules=$1
	local mod
	local ret=""

	for mod in $modules; do
	    ret="$mod $ret"
	done

	echo $ret
}

. ${IPTABLES_MODULE_LIST}

IPSec_Mod=""
for mod in ${PPP_MODULES}; do
	if [ -e "/lib/modules/$mod" ]; then
		IPSec_Mod="${IPSec_Mod} ${mod}"
	fi
done
for mod in ${KERNEL_MODULES_CORE}; do
	if [ -e "/lib/modules/$mod" ]; then
		IPSec_Mod="${IPSec_Mod} ${mod}"
	fi
done
for mod in ${KERNEL_MODULES_COMMON}; do
	if [ -e "/lib/modules/$mod" ]; then
		IPSec_Mod="${IPSec_Mod} ${mod}"
	fi
done
for mod in ${KERNEL_MODULES_NAT}; do
	if [ -e "/lib/modules/$mod" ]; then
		IPSec_Mod="${IPSec_Mod} ${mod}"
	fi
done
for mod in ${L2TP_MODULES}; do
	if [ -e "/lib/modules/$mod" ]; then
		IPSec_Mod="${IPSec_Mod} ${mod}"
	fi
done

start() {
	echo "Starting L2TP/IPsec client: "
	/bin/mkdir -p /var/run/xl2tpd

	if [ -x ${BIN_SYNOMODULETOOL} ]; then
		${BIN_SYNOMODULETOOL} --insmod $SERVICE ${IPSec_Mod}
	elif [ -x ${BIN_IPTABLESTOOL} ]; then
		${BIN_IPTABLESTOOL} --insmod $SERVICE ${IPSec_Mod}
	fi

	if [ -n "`pidof xl2tpd`" ]; then
	   echo "Already running"
	   exit 1
	fi

	/usr/sbin/xl2tpd -c ${L2TP_CONF} -p /var/run/xl2tpd.pid
	${IPSEC_SBIN} setup start
}

stop() {
	echo -n "Shutting down L2TP/IPsec client: "
	local modules=`reverse_modules "${IPSec_Mod}"`

	echo "d L2TPserver" > /var/run/xl2tpd/l2tp-control
	${IPSEC_SBIN} auto --down L2TP-PSK-CLIENT
	sleep 2
	${IPSEC_SBIN} setup stop
	/bin/kill `cat /var/run/xl2tpd.pid` 2>/dev/null
	sleep 1
	if [ -n "`pidof xl2tpd`" ]; then
	    echo "Failed to stop xl2tpd"
	fi

	# if [ -x ${BIN_SYNOMODULETOOL} ]; then
	# 	${BIN_SYNOMODULETOOL} --rmmod $SERVICE $modules
	# elif [ -x ${BIN_IPTABLESTOOL} ]; then
	# 	${BIN_IPTABLESTOOL} --rmmod $SERVICE $modules
	# fi
}

case "$1" in
	start)
		start
	;;
	stop)
		stop
	;;
	start-connect)
		echo "c L2TPserver" > /var/run/xl2tpd/l2tp-control
	;;
	restart|reload)
		stop
		sleep 5
		start
	;;
	*)
	echo "Usage: $0 {start|stop|restart}"
	exit 1
esac
exit $?

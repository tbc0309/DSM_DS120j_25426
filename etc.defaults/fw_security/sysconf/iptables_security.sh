#!/bin/sh

PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/syno/sbin:/usr/syno/bin

KERNEL_VERSION=`uname -r`
CONF="/etc/synoinfo.conf"
DEFAULT_CONF="/etc.defaults/synoinfo.conf"
V4ONLY=`get_key_value $DEFAULT_CONF ipv4only`
SZD_FW_SECURITY_ROOT="/etc/fw_security"
SZD_FW_SECURITY_SYS_CONF="$SZD_FW_SECURITY_ROOT/sysconf"
SZK_FW_S_DOS_ENABLE="dos_protect_enable"
SZK_FW_S_PPTP_ENABLE="pptp_passthrough_enable"
SZK_FW_S_IPSEC_ENABLE="ipsec_passthrough_enable"
SZK_FW_S_L2TP_ENABLE="l2tp_passthrough_enable"
SZF_FW_S_DOS_PATTERN="dos.pattern"
SZF_FW_S_DOSV6_PATTERN="dosv6.pattern"
SZF_FW_S_PPTP_PATTERN="pptp_passthrough.pattern"
SZF_FW_S_IPSEC_PATTERN="ipsec_passthrough.pattern"
SZF_FW_S_L2TP_PATTERN="l2tp_passthrough.pattern"
SZF_RULES_SECURITY_DUMP="/etc/firewall_rules_security.dump"
SZF_RULES_6_SECURITY_DUMP="/etc/firewall_6_rules_security.dump"
SZK_SUPPORT_NET_TOPOLOGY="support_net_topology"
SZK_NET_TOPOLOGY="net_topology"
ROUTER="router"
BRIDGE="bridge"
SERV_DOS="fw_dos"
SERV_VPN_PASSTHROUGH="fw_vpn_passthrough"
PPPOE="pppoe"
WLAN0="wlan0"
INSMOD_DOS=0
HAS_PORTFW_RULE=0

## Get module list
source /usr/syno/etc.defaults/iptables_modules_list
KERNEL_FIREWALL="${KERNEL_MODULES_CORE} ${KERNEL_MODULES_COMMON}"
DOS_MODULES="${KERNEL_FIREWALL} xt_limit.ko"
VPN_PASSTHROUGH_MODULES="${KERNEL_FIREWALL} nf_nat.ko nf_conntrack_proto_gre.ko nf_nat_proto_gre.ko nf_conntrack_pptp.ko nf_nat_pptp.ko"

clear_chain_rules() {
	iptables -F DOS_PROTECT
	iptables -F VPN_PASSTHROUGH

	if [ "yes" != "${V4ONLY}" ]; then
		ip6tables -F DOS_PROTECT
		ip6tables -F VPN_PASSTHROUGH
	fi
}

reverse_syno() {
	local modules=$1
	local mod
	local ret=""

	for mod in $modules; do
	    ret="$mod $ret"
	done

	echo $ret
}

check_vpn_passthrough() {
	local ret=0
	local support_net_topology=`get_key_value $CONF $SZK_SUPPORT_NET_TOPOLOGY`
	local topology=`get_key_value $CONF $SZK_NET_TOPOLOGY`
	local has_nat_table=0
	local has_portfw_rule=$1
	local has_upnp_rule=0
	local os_name=`get_key_value /etc.defaults/synoinfo.conf os_name`

	## If is router would always support vpn passthrough
	if [ "xSRM" = "x${os_name}" ]; then
		return 1
	fi

	ret=`/bin/grep nat /proc/net/ip_tables_names 2>&1`
	if [ 0 -eq $? -a "xnat" = "x$ret" ]; then
		has_nat_table=1
	fi

	ret=`iptables-save -t nat | grep "\-j NUPNPD" | wc -l`
	if [ 0 -lt $ret ]; then
		has_upnp_rule=1
	fi

	ret=0
	[ "yes" = "${support_net_topology}" ] && [ "${ROUTER}" = "${topology}" -o "${BRIDGE}" = "${topology}" ] &&
		[ 1 -eq $has_nat_table ] && [ 1 -eq $has_portfw_rule -o 1 -eq $has_upnp_rule ] && ret=1

	return $ret
}

#ipv6 ip6tables
ipv6_rule_apply() {
	while read line
	do
		ip6tables $line
	done < $1
}

#ipv4 iptables, ipv4 modules must been loaded, because of following ipv6 firewall may use those modules
ipv4_rule_apply() {
	while read line
	do
		iptables $line
	done < $1
}

modules_reload() {
	local modules_reverse=""

	##### remove modules #####
	#if old settings have dos/vpn passthrough but not for new settings, we need to clean old settings related modules
	if [ 0 -eq $support_vpn_passthrough ]; then
		modules_reverse=`reverse_syno "$VPN_PASSTHROUGH_MODULES"`
		/usr/syno/bin/iptablestool --rmmod $SERV_VPN_PASSTHROUGH $modules_reverse
	fi
	if [ 0 -eq $INSMOD_DOS ]; then
		#before remove kernel modules, DOS_PROTECT chain should be delete first, or it will fail to remove iptable_filter.ko
		if [ "yes" != "${V4ONLY}" ]; then
			ret=`/bin/grep filter /proc/net/ip6_tables_names 2>&1`
			if [ 0 -eq $? -a "xfilter" = "x$ret" ]; then
				clear_chain_rules
			fi
			modules_reverse=`reverse_syno "$IPV6_MODULES"`
			/usr/syno/bin/iptablestool --rmmod $SERV_DOS $modules_reverse
		fi
		ret=`/bin/grep filter /proc/net/ip_tables_names 2>&1`
		if [ 0 -eq $? -a "xfilter" = "x$ret" ]; then
			clear_chain_rules
		fi
		modules_reverse=`reverse_syno "$DOS_MODULES"`
		/usr/syno/bin/iptablestool --rmmod $SERV_DOS $modules_reverse
	fi

	##### insert modules #####
	#if new settings have dos/vpn passthrough, we need to insmod the related modules
	if [ 1 -eq $INSMOD_DOS ]; then
		/usr/syno/bin/iptablestool --insmod $SERV_DOS ${DOS_MODULES}
		if [ "yes" != "${V4ONLY}" ]; then
			/usr/syno/bin/iptablestool --insmod $SERV_DOS ${IPV6_MODULES}
		fi
	fi
	#load VPN passthrough related modules only for 213air router mode
	if [ 1 -eq $support_vpn_passthrough ]; then
		/usr/syno/bin/iptablestool --insmod $SERV_VPN_PASSTHROUGH ${VPN_PASSTHROUGH_MODULES}
	fi
}

dump_rules_clear() {
	for i in $@;
	do
		if [ -e $i ]; then
			rm -f $i &> /dev/null
		fi
	done
}

start() {
	fw_security_dump
	modules_reload

	clear_chain_rules
	[ -f $SZF_RULES_SECURITY_DUMP ] && ipv4_rule_apply $SZF_RULES_SECURITY_DUMP
	[ "yes" != "${V4ONLY}" -a -f $SZF_RULES_6_SECURITY_DUMP ] && ipv6_rule_apply $SZF_RULES_6_SECURITY_DUMP

	return 0
}

ipv6_stop() {
	local modules_reverse=""

	echo ""
	echo "Unloading kernel ipv6 netfilter modules... "
	modules_reverse=`reverse_syno "$IPV6_MODULES"`
	/usr/syno/bin/iptablestool --rmmod $SERV_DOS $modules_reverse

	dump_rules_clear $SZF_RULES_6_SECURITY $SZF_RULES_6_SECURITY_DEL
}

ipv4_stop() {
	local modules_reverse=""

	echo ""
	echo "Unloading kernel ipv4 netfilter modules... "
	modules_reverse=`reverse_syno "$VPN_PASSTHROUGH_MODULES"`
	/usr/syno/bin/iptablestool --rmmod $SERV_VPN_PASSTHROUGH $modules_reverse
	modules_reverse=`reverse_syno "$DOS_MODULES"`
	/usr/syno/bin/iptablestool --rmmod $SERV_DOS $modules_reverse

	dump_rules_clear $SZF_RULES_SECURITY $SZF_RULES_SECURITY_DEL
}

stop() {
	clear_chain_rules
	[ "yes" != "${V4ONLY}" ] && ipv6_stop
	ipv4_stop

	return 0
}

restart() {
	stop
	start $1
}

get_interface() {
	local out_if=""
	local interface=""

	interface=`/usr/syno/sbin/synonet --show | grep "interface: " | awk '{print $NF}'`
	if [ $? -eq 0 ]; then
		out_if=$interface
	fi

	#get wlan0
	support_wifi=`/bin/get_key_value $DEFAULT_CONF support_wireless`
	if [ "xyes" = "x$support_wifi" ]; then
		tmp=`/bin/echo $out_if | grep $WLAN0`
		if [ 0 -ne $? ]; then
			out_if="$out_if $WLAN0"
		fi
	fi

	#get pppoe
	out_if="$out_if $PPPOE"

	#get usbmodem
	usbmodem_list=`synowireless --get-usbmodem-interface-list`
	for usbmodem in $usbmodem_list;
	do
		out_if="$out_if $usbmodem"
	done

	echo $out_if
}

fw_security_dump() {
	local ret=""
	local interface=""
	local all_if=""
	local modconf=""
	local ifName=""

	dump_rules_clear $SZF_RULES_SECURITY_DUMP $SZF_RULES_6_SECURITY_DUMP

	for modfile in $SZD_FW_SECURITY_ROOT/*.conf.tmp ;
	do
		modconf=`basename $modfile | sed 's/.conf.tmp$//g'`
	done

	all_if=`get_interface`

	for inf in $all_if ;
	do
		if [ "$modconf" = "$inf" ]; then
			file=$modfile
		else
			file=$SZD_FW_SECURITY_ROOT/$inf.conf
		fi
		interface=$inf
		if [ "$PPPOE" = "$inf" ]; then
			ret=`/usr/syno/sbin/synonet --check_pppoe`
			if [ 0 -ne $? ]; then
				continue
			fi
			ifName=`/usr/syno/sbin/synonet --get_if pppoe`
			if [ 0 -ne $? ]; then
				continue
			fi
			interface=$ifName
		fi

		ret=`/bin/get_key_value $file $SZK_FW_S_DOS_ENABLE`
		if [ "xyes" = "x$ret" ]; then
			INSMOD_DOS=1
			cat $SZD_FW_SECURITY_SYS_CONF/$SZF_FW_S_DOS_PATTERN | sed -e s/INTERFACE/"$interface"/g >> $SZF_RULES_SECURITY_DUMP
			[ "yes" != "${V4ONLY}" ] && cat $SZD_FW_SECURITY_SYS_CONF/$SZF_FW_S_DOSV6_PATTERN | sed -e s/INTERFACE/"$interface"/g | grep -v icmp >> $SZF_RULES_6_SECURITY_DUMP
		fi

		if [ 1 -eq $support_vpn_passthrough ]; then
			if [ "wlan0" = "$interface" ]; then
				continue
			fi
			ret=`/bin/get_key_value $file $SZK_FW_S_PPTP_ENABLE`
			if [ "xyes" = "x$ret" ]; then
				cat $SZD_FW_SECURITY_SYS_CONF/$SZF_FW_S_PPTP_PATTERN | sed -e s/INTERFACE/"$interface"/g >> $SZF_RULES_SECURITY_DUMP
				[ "yes" != "${V4ONLY}" ] && cat $SZD_FW_SECURITY_SYS_CONF/$SZF_FW_S_PPTP_PATTERN | sed -e s/INTERFACE/"$interface"/g >> $SZF_RULES_6_SECURITY_DUMP
			else
				cat $SZD_FW_SECURITY_SYS_CONF/$SZF_FW_S_PPTP_PATTERN | sed -e s/INTERFACE/"$interface"/g | sed -e s/ACCEPT/DROP/g >> $SZF_RULES_SECURITY_DUMP
				[ "yes" != "${V4ONLY}" ] && cat $SZD_FW_SECURITY_SYS_CONF/$SZF_FW_S_PPTP_PATTERN | sed -e s/INTERFACE/"$interface"/g | sed -e s/ACCEPT/DROP/g >> $SZF_RULES_6_SECURITY_DUMP
			fi

			ret=`/bin/get_key_value $file $SZK_FW_S_IPSEC_ENABLE`
			if [ "xyes" = "x$ret" ]; then
				cat $SZD_FW_SECURITY_SYS_CONF/$SZF_FW_S_IPSEC_PATTERN | sed -e s/INTERFACE/"$interface"/g >> $SZF_RULES_SECURITY_DUMP
				[ "yes" != "${V4ONLY}" ] && cat $SZD_FW_SECURITY_SYS_CONF/$SZF_FW_S_IPSEC_PATTERN | sed -e s/INTERFACE/"$interface"/g >> $SZF_RULES_6_SECURITY_DUMP
			else
				cat $SZD_FW_SECURITY_SYS_CONF/$SZF_FW_S_IPSEC_PATTERN | sed -e s/INTERFACE/"$interface"/g | sed -e s/ACCEPT/DROP/g >> $SZF_RULES_SECURITY_DUMP
				[ "yes" != "${V4ONLY}" ] && cat $SZD_FW_SECURITY_SYS_CONF/$SZF_FW_S_IPSEC_PATTERN | sed -e s/INTERFACE/"$interface"/g | sed -e s/ACCEPT/DROP/g >> $SZF_RULES_6_SECURITY_DUMP
			fi

			ret=`/bin/get_key_value $file $SZK_FW_S_L2TP_ENABLE`
			if [ "xyes" = "x$ret" ]; then
				cat $SZD_FW_SECURITY_SYS_CONF/$SZF_FW_S_L2TP_PATTERN | sed -e s/INTERFACE/"$interface"/g >> $SZF_RULES_SECURITY_DUMP
				[ "yes" != "${V4ONLY}" ] && cat $SZD_FW_SECURITY_SYS_CONF/$SZF_FW_S_L2TP_PATTERN | sed -e s/INTERFACE/"$interface"/g >> $SZF_RULES_6_SECURITY_DUMP
			else
				cat $SZD_FW_SECURITY_SYS_CONF/$SZF_FW_S_L2TP_PATTERN | sed -e s/INTERFACE/"$interface"/g | sed -e s/ACCEPT/DROP/g >> $SZF_RULES_SECURITY_DUMP
				[ "yes" != "${V4ONLY}" ] && cat $SZD_FW_SECURITY_SYS_CONF/$SZF_FW_S_L2TP_PATTERN | sed -e s/INTERFACE/"$interface"/g | sed -e s/ACCEPT/DROP/g >> $SZF_RULES_6_SECURITY_DUMP
			fi
		fi
	done

	return 0;
}

check_has_portfwd_rules()
{
	local PF_FILTER_DUMP="/etc/portforward/routerpf/filter_rules.dump"
	rm ${PF_FILTER_DUMP} &> /dev/null
	synorouterportfwd
	if [ -f "$PF_FILTER_DUMP" ]; then
		rm ${PF_FILTER_DUMP} &> /dev/null
		return 0
	fi
	return 1
}

# do operations if support_fw_security="yes", or just return.
support_fw_security=`/bin/get_key_value $DEFAULT_CONF support_fw_security`
if [ "xyes" != "x$support_fw_security" ]; then
	echo "This platform doesn't support firewall security setting!"
	exit 1;
fi

if check_has_portfwd_rules; then
	HAS_PORTFW_RULE=1
fi

check_vpn_passthrough ${HAS_PORTFW_RULE}
support_vpn_passthrough=$?

case "$1" in
	start)
		start ${HAS_PORTFW_RULE}
		RETVAL=$?
		;;
	force-reload)
		start ${HAS_PORTFW_RULE}
		RETVAL=$?
		;;
	stop)
		stop
		RETVAL=$?
		;;
	restart)
		restart ${HAS_PORTFW_RULE}
		RETVAL=$?
		;;
	*)
		echo $"Usage: ${0##*/} {start|stop|restart|force-reload}"
		RETVAL=2
		;;
esac

exit $RETVAL

#!/bin/sh
# Copyright (c) 2000-2013 Synology Inc. All rights reserved.

CHAIN_FWD="FUPNPD"
CHAIN_NAT="NUPNPD"
IFCONFIG="/sbin/ifconfig"
UNAME="/bin/uname"
UUID_GEN="/usr/bin/uuidgen"
IPTABLES="/sbin/iptables"
IP_SAVE="/sbin/iptables-save"
UPNPD="/usr/bin/miniupnpd"
UPNPD_PID="/tmp/miniupnpd-"
UPNPD_CONFIG_DIR="/etc/sysconfig/miniupnpd"
UPNPD_CONFIG_NAME_FORMAT=".*upnp-\(.*\)-\(.*\).conf"

generate_nat_chain() {
	local if_ext=$1

	if [ -z "${if_ext}" ]; then
		return 0
	fi
	CHAIN_NAT_NAME="${CHAIN_NAT}-${if_ext}"
	return 1
}

generate_fwd_chain() {
	local if_ext=$1

	if [ -z "${if_ext}" ]; then
		return 0
	fi
	CHAIN_FWD_NAME="${CHAIN_FWD}-${if_ext}"
	return 1
}

generate_config_name() {
	local if_ext=$1
	local if_inn=$2

	if [ -z "${if_ext}" -o -z "${if_inn}" ]; then
		return 0
	fi
	if [ ! -d "${UPNPD_CONFIG_DIR}" ]; then
		`mkdir -p ${UPNPD_CONFIG_DIR}`
	fi
	CONFIG_FILENAME="${UPNPD_CONFIG_DIR}/upnp-${if_ext}-${if_inn}.conf"
	return 1
}

check_iface_alive() {
	local if_name=$1

	count=`${IFCONFIG} | grep "^${if_name}" | wc -l`
	if [ $count -gt 0 ]; then
		return 1
	fi

	return 0
}

check_upnpd_started() {
	local if_ext=$1
	local if_inn=$2

	if [ -z "${if_ext}" -o -z "${if_inn}" ]; then
		return 0
	fi
	ret=`ps -w | grep -v grep | grep "${UPNPD}" | grep "${if_ext}" | grep "${if_inn}"`

	if [ "x${ret}" = "x" ]; then
		# means no miniupnpd is running
		return 0
	else
		return 1
	fi
}

prepare_config() {
	local if_ext=$1
	local if_inn=$2

	local listen_ip=""
	local dsm_name=""
	local dsm_version=""
	local dsm_model=""
	local dsm_ui=""
	local dsm_uuid=""
	local mac_addr=""
	local adport=""
	local adip=""

	generate_nat_chain "${if_ext}"
	ifext_ret=$?
	generate_fwd_chain "${if_ext}"
	ifinn_ret=$?
	if [ ${ifext_ret} -eq 0 -o ${ifinn_ret} -eq 0 ]; then
		return 1
	fi
	adport=`get_key_value /etc/synoinfo.conf admin_port`
	adip=`${IFCONFIG} ${if_inn} | grep 'inet addr' | sed -e 's/.*addr:\([.0-9]*\).*/\1/g'`

	listen_ip=`${IFCONFIG} ${if_inn} | grep 'inet addr' | sed -e 's/.*addr:\([.0-9]*\).*Mask:\([.0-9]*\)/\1\/\2/g'`
	mac_addr=`${IFCONFIG} ${if_inn} | grep 'HWaddr' | sed -e 's/.*HWaddr \([:0-9a-zA-Z]*\)/\1/g'`
	dsm_uuid=`${UUID_GEN}`
	dsm_name=`${UNAME} -n`
	dsm_model=`get_key_value /etc/synoinfo.conf upnpmodelname`
	local version_major=`get_key_value /etc.defaults/VERSION majorversion`
	local version_minor=`get_key_value /etc.defaults/VERSION minorversion`
	dsm_version="${version_major}.${version_minor}"
	dsm_ui="http://${adip}:${adport}"

	generate_config_name ${if_ext} ${if_inn}
cat > "${CONFIG_FILENAME}" <<-EOF
ext_ifname=${if_ext}
inn_ifname=${if_inn}
listening_ip=${listen_ip}
port=0
enable_upnp=yes
enable_natpmp=yes
secure_mode=yes
upnp_forward_chain=${CHAIN_FWD_NAME}
upnp_nat_chain=${CHAIN_NAT_NAME}
notify_interval=60
system_uptime=yes
friendly_name=${dsm_name}
model_number=${dsm_version}
model_name=${dsm_model}
serial=${mac_addr}
clean_ruleset_interval=600
clean_ruleset_threshold=20
presentation_url=${dsm_ui}
uuid=${dsm_uuid}
#allow is need to be decided 
allow 0-65535 ${listen_ip} 1-65535
deny 0-65535 0.0.0.0/0 0-65535

EOF
return 0
}

remove_config() {
	local if_ext=$1
	local if_inn=$2

	generate_config_name ${if_ext} ${if_inn}
	local ret=$?
	if [ -f "${CONFIG_FILENAME}" -a  ${ret} -eq 1 ]; then
		`rm -f "${CONFIG_FILENAME}"`
		return 0
	fi

	return 1
}

initial_iptables() {
	local if_ext=$1

	generate_nat_chain "${if_ext}"
	ifext_ret=$?
	generate_fwd_chain "${if_ext}"
	ifinn_ret=$?
	if [ ${ifext_ret} -eq 0 -o ${ifinn_ret} -eq 0 ]; then
		return 1
	fi
	check_iptables "${if_ext}"
	ret=$?
	if [ ${ret} -ne 1 ]; then
		# means the iptable is wrong
		release_iptables "${if_ext}"

		# add the nat chain
		`${IPTABLES} -t nat -N ${CHAIN_NAT_NAME} > /dev/null 2>&1`
		# add rules in nat
		`${IPTABLES} -t nat -A PRIMITIVE_PREROUTING -i ${if_ext} -j ${CHAIN_NAT_NAME} > /dev/null 2>&1`

		# add the filter chain
		`${IPTABLES} -t filter -N ${CHAIN_FWD_NAME} > /dev/null 2>&1`
		# add rules in filter
		`${IPTABLES} -t filter -A PRIMITIVE_FORWARD -i ${if_ext} ! -o ${if_ext} -j ${CHAIN_FWD_NAME} > /dev/null 2>&1`
		return 1
	fi
	return 0
}

release_iptables() {
	local if_ext=$1
	local flag=1
	local last_count=0

	generate_nat_chain "${if_ext}"
	ifext_ret=$?
	generate_fwd_chain "${if_ext}"
	ifinn_ret=$?
	if [ ${ifext_ret} -eq 0 -o ${ifinn_ret} -eq 0 ]; then
		return 1
	fi

	while :
	do
		local num=`${IP_SAVE} | grep ${if_ext} | wc -l`
		if [ ${num} -eq 0 -o ${num} -eq ${last_count} ]; then
			break;
		fi
		last_count=${num}
		# flush(remove rules) the nat chain
		`${IPTABLES} -t nat -F ${CHAIN_NAT_NAME} > /dev/null 2>&1`
		# delete rules in nat
		`${IPTABLES} -t nat -D PRIMITIVE_PREROUTING -i ${if_ext} -j ${CHAIN_NAT_NAME} > /dev/null 2>&1`
		# delete chain
		`${IPTABLES} -t nat -X ${CHAIN_NAT_NAME} > /dev/null 2>&1`

		# flush(remove rules) the filter chain
		`${IPTABLES} -t filter -F ${CHAIN_FWD_NAME} > /dev/null 2>&1`
		# delete rules in filter
		`${IPTABLES} -t filter -D PRIMITIVE_FORWARD -i ${if_ext} ! -o ${if_ext} -j ${CHAIN_FWD_NAME} > /dev/null 2>&1`
		# delete chain
		`${IPTABLES} -t filter -X ${CHAIN_FWD_NAME} > /dev/null 2>&1`
	done
	return 0
}

start_upnpd() {
	local if_ext=$1
	local if_inn=$2
	local config=""
	local restart_flag=0

	generate_config_name ${if_ext} ${if_inn}
	local ret=$?
	config=${CONFIG_FILENAME}

	if [ -z ${config} -o ${ret} -eq 0 ]; then
		return 1
	fi
	check_iface_alive ${if_ext}
	ret1=$?
	check_iface_alive ${if_inn}
	ret2=$?

	if [ ${ret1} -eq 0 -o ${ret2} -eq 0 ]; then
		# interface(s) does not exist.
		return 1
	fi

	initial_iptables ${if_ext}
	restart_flag=$?

	check_upnpd_started ${if_ext} ${if_inn}
	ret=$?
	if [ ${ret} -eq 1 ]; then
		if [ ${restart_flag} -ne 1 ]; then
			#no need to start miniupnpd
			return 1
		fi
		# has started, but need to restart
		stop_upnpd ${if_ext} ${if_inn}
	fi
	# now we start miniupnpd by and upstart:miniupnpd
	#`${UPNPD} -f ${config} -P ${UPNPD_PID}${if_ext}.pid > /dev/null 2>&1`

	return 0
}

stop_upnpd() {
	local if_ext=$1
	local if_inn=$2
	local config=""

	generate_config_name ${if_ext} ${if_inn}
	local ret=$?
	config=${CONFIG_FILENAME}

	if [ -z ${config} -o ${ret} -eq 0 ]; then
		return 1
	fi
	#pid=`ps -w | grep -v grep | grep "${UPNPD}" | grep "${CONFIG_FILENAME}" | awk '{print $1}'`
	#if [ -n "${pid}" ]; then
		#`kill -9 ${pid}`
	#fi
	#we use upstart now, so no need to kill daemon

	# release iptable
	release_iptables ${if_ext}
	return 0
}

sync_ppp() {
	local need_start=""
	local need_stop=""

	local ppp_list=`${IFCONFIG} | grep "^ppp" | awk '{print $1}'`
	local files=`ls ${UPNPD_CONFIG_DIR}/* | grep ppp`
	for configs in ${files}; do
		local flag=""
		for if_ext in ${ppp_list}; do
			local ret=`echo ${configs} | grep ${if_ext}`
			if [ -n ${ret} ]; then
				# means ${configs} and ${if_ext} exists, need to start it
				need_start="${need_start} ${configs}"
				flag="${configs}"
				break;
			fi
		done
		if [ -z ${flag} ]; then
			# means ${configs} exists, but no ${if_ext} mapping to, need to stop it
			need_stop="${need_stop} ${configs}"
		fi
	done
	for config in ${need_start}; do
		start_config ${config}
	done
	for config in ${need_stop}; do
		stop_config ${config}
	done
}

parse_config() {
	# will assign IF_EXT & IF_INN variable
	IF_EXT=""
	IF_INN=""
	local config=$1
	ret=`echo ${config} | sed -e "s/${UPNPD_CONFIG_NAME_FORMAT}/\1 \2/g"`
	if [ "x${ret}" = "x${config}" ]; then
		return 1;
	fi
		
	for iface in $ret; do
		if [ "x${IF_EXT}" = "x" ]; then
			IF_EXT=${iface}
		elif [ "x${IF_INN}" = "x" ]; then
			IF_INN=${iface}
		fi
	done
	return 0
}

start_config() {
	parse_config "$@"

	local ret=$?
	if [ ${ret} -ne 0 ]; then
		return ${ret}
	else
		prepare_config ${IF_EXT} ${IF_INN}
		ret=$?
		if [ ${ret} -ne 0 ]; then
			return ${ret}
		fi
		start_upnpd ${IF_EXT} ${IF_INN}
		ret=$?
		if [ ${ret} -ne 0 ]; then
			return ${ret}
		fi
	fi
	return 0
}

stop_config() {
	parse_config "$@"

	local ret=$?
	if [ ${ret} -eq 0 ]; then
		stop_upnpd ${IF_EXT} ${IF_INN}
	fi
	return 0
}

check_iptables() {
	local if_name=$1

	generate_nat_chain "${if_name}"
	ifext_ret=$?
	generate_fwd_chain "${if_name}"
	ifinn_ret=$?
	if [ ${ifext_ret} -eq 0 -o ${ifinn_ret} -eq 0 ]; then
		return 1
	fi
	local num_nat=`${IP_SAVE} | grep ${CHAIN_NAT_NAME} | wc -l`
	local num_fwd=`${IP_SAVE} | grep ${CHAIN_FWD_NAME} | wc -l`

	if [ ${num_nat} -lt 2 -o ${num_fwd} -lt 2 ]; then
		return 0
	else
		return 1
	fi
}

action=$1
shift;

case $action in
	[Pp][Rr][Ee][Pp][Aa][Rr][Ee])
		prepare_config "$@"
		;;
	[Rr][Ee][Mm][Oo][Vv][Ee])
		remove_config "$@"
		;;
	[Ii][Nn][Ii][Tt][Ii][Aa][Ll])
		initial_iptables "$@"
		;;
	[Rr][Ee][Ll][Ee][Aa][Ss][Ee])
		release_iptables "$@"
		;;
	[Cc][Hh][Ee][Cc][Kk])
		check_iptables "$@"
		;;
	[Ss][Tt][Aa][Rr][Tt])
		start_upnpd "$@"
		;;
	[Ss][Tt][Oo][Pp])
		stop_upnpd "$@"
		;;
	[Ss][Yy][Nn][Cc]-[Pp][Pp][Pp])
		sync_ppp "$@"
		;;
	[Ss][Tt][Aa][Rr][Tt]-[Cc][Oo][Nn][Ff][Ii][Gg])
		start_config "$@"
		;;
	[Ss][Tt][Oo][Pp]-[Cc][Oo][Nn][Ff][Ii][Gg])
		stop_config "$@"
		;;
	*)
		echo "Usage: [prepare|initial|release|start|stop]"
		echo "	prepare: Prepare the config file with [ext_if inn_if]"
		echo "	remove: Remove the config file with [ext_if inn_if]"
		echo "	initial: Initial the iptables for the interface [ext_if]"
		echo "	release: Release the iptables for the interface [ext_if]"
		echo "	start: Start the miniupnpd with [ext_if inn_if]"
		echo "	stop: Stop the miniupnpd with [ext_if inn_if]"
		echo "	sync-ppp: Sync ppp and miniupnpd"
		echo "	start-config: Stop the miniupnpd with [config]"
		echo "	stop-config: Stop the miniupnpd with [config]"
		;;
esac

ret=$?
exit ${ret}

#!/bin/sh

PATH="$PATH:/bin/"		# cat, echo, mkdir
PATH="$PATH:/usr/bin"		# basename

SSDPD="/usr/bin/minissdpd"
SZF_SSDPD_ENV="/run/ssdp/env.tmp"

SZD_SSDPD_NGINX_CONF="/usr/syno/etc/ssdp/nginx"
SZD_NGINX_CONFD="/usr/local/etc/nginx/conf.d/"
NGINX_CONF="dsm.ssdp.conf"

usage() {
	cat <<EOF
Usage: $(basename $0) [start|stop|restart]
EOF
}
warn() {
	local ret=$?
	echo "$@" >&2
	return $ret
}

enum_interface() {
	#only bind eth*, ovs_eth*, bond*, ovs_bond*, and br*
	/usr/syno/sbin/synonet --show | awk '/Network interface/ { print $3 }' | grep -e '^eth.*\|^ovs_eth.*\|^bond.*\|^ovs_bond.*\|^br.*'
	return
}

enum_service() {
	local i=
	local dir=/usr/syno/etc/ssdp/*.conf
	if [ `ls $dir 2>/dev/null | wc -l` -ne 0 ]; then
		for i in "${dir}"; do
			echo $i;
		done
	fi
	dir=/usr/local/etc/ssdp/*.conf
	if [ `ls $dir 2>/dev/null | wc -l` -ne 0 ] ; then
		for i in "${dir}"; do
			echo $i;
		done
	fi
}

pre_start() {
	local i= interface=""

	mkdir -p /usr/syno/synoman/ssdp/
	mkdir -p /run/ssdp/

	for i in $(enum_interface); do
		interface="$interface -i $i"
	done

	echo "target interface: "$interface
	echo "INTERFACE=\"${interface}\"" > ${SZF_SSDPD_ENV}

	mkdir -p ${SZD_NGINX_CONFD}
	cp ${SZD_SSDPD_NGINX_CONF}/${NGINX_CONF} ${SZD_NGINX_CONFD}/${NGINX_CONF}
	synoservice --reload nginx
}

post_start() {
	local reg_service="/usr/syno/bin/reg_ssdp_service"
	local i=""

	for i in $(enum_service); do
		echo $reg_service $i
		$reg_service $i
	done

	cp -rf /usr/syno/synoman/ssdp/ /tmp/ssdp
	touch /tmp/ssdp/dummy.xml
}

case "$1" in
	pre-start) pre_start;;
	post-start) post_start;;
	*)       usage >&2 ; exit 1 ;;
esac


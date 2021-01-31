#!/bin/sh
# Copyright (c) 2000-2017 Synology Inc. All rights reserved.

SZD_SERVICES_TMP_NGINX="/var/services/tmp/nginx"

case "$1" in
	'reload')
		if ! /usr/syno/sbin/synoservicectl --status nginx > /dev/null 2>&1; then
			exit 0
		fi

		[ ! -d "$SZD_SERVICES_TMP_NGINX" ] && /bin/mkdir -p "$SZD_SERVICES_TMP_NGINX" || true

		/usr/syno/bin/synow3tool --deploy-hup > /dev/null 2>&1
		ret_hup=$?

		if [ $ret_hup -eq 255 ]; then
			# depoly config error
			/bin/logger -p user.err -t "$(/bin/basename "$0")" "Cannot reload nginx service"
			exit 1
		elif [ $ret_hup -eq 2 ]; then
			# Default mode, skip reload
			exit 0
		fi

		/usr/sbin/start alias-register || true

		/usr/sbin/reload nginx
		;;
	*)
		echo "Usage $0 { reload }"
		exit 1
		;;
esac

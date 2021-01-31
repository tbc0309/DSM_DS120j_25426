#!/bin/sh
# Copyright (c) 2000-2015 Synology Inc. All rights reserved.

SYNOINFO_DEF="/etc.defaults/synoinfo.conf"
USBSTATION=`get_key_value $SYNOINFO_DEF usbstation`

usage() {
	cat << EOF
Usage: $(basename $0) [start]
EOF
}

UpgradeConfig()
{
	Event=$1

	if [ ! -f "/var/.UpgradeBootup" ]; then
		return
	fi

	orgVer="/.old_patch_info/VERSION"
	if [ -f "/.updater" ]; then
		upgType="migrate"
	else
		upgType="upgrade"
	fi

	if [ -f $orgVer ]; then
		/usr/syno/bin/configupdate -c $Event -t $upgType -p $orgVer

		if [ -x "/usr/syno/bin/configupdate.small" ]; then
			/usr/syno/bin/configupdate.small -c $Event -p $orgVer
		fi

	else
		echo "Skip update config because not found ${orgVer}"
	fi
}

make_var_service_tmp()
{
	local TMP_LINK=/var/services/tmp
	local TMP_STATIC=/var/services/tmp.static
	local TMP_BIN
	local TMP_TARGET

	# Clean /var/services/tmp.static
	/bin/rm -rf $TMP_LINK
	/bin/rm -rf $TMP_STATIC

	# At least 5 MB free space
	TMP_BIN=`servicetool --get-alive-sharebin 5`

	if [ $? -ne 1 ]; then
		TMP_TARGET=$TMP_STATIC
	else
		TMP_TARGET=$TMP_BIN/@tmp
	fi

	[ -d "$TMP_TARGET" ] || mkdir $TMP_TARGET
	chmod 1777 $TMP_TARGET

	# Create nginx dir in /var/service/tmp
	/bin/mkdir -p -m 700 $TMP_TARGET/nginx
	/usr/bin/chown http:root $TMP_TARGET/nginx

	/bin/ln -sfn $TMP_TARGET $TMP_LINK
}

start()
{
	/usr/syno/bin/synocheckshare
	if [ "$USBSTATION" != "yes" ]; then
		/usr/syno/sbin/synoquota --migrate
		# finish check share, pause service which required share is not ready
		/usr/syno/sbin/synoservice --check-depend-share-service
		if [ -x "/usr/syno/sbin/synosharesnaptool" ]; then
			/usr/syno/sbin/synosharesnaptool misc boot-check
		fi
		/usr/syno/bin/synocheckiscsitrg
	fi
	# when no volume exist, pgsql and related service can not start.
	# On this case, we pause pgsql by reason "no-volume", to avoid
	# boot up sequence be blocked by wait pgsql and related service ready
	/usr/syno/bin/servicetool --get-service-path pgsql >/dev/null 2>&1
	if [ $? -eq 0 ]; then
		/usr/syno/sbin/synoservice --pause-by-reason pgsql no-volume
	fi

	make_var_service_tmp
	UpgradeConfig "share_ready"
	/sbin/initctl emit --no-wait syno.share.ready
}

case "$1" in
	start) start;;
	*) usage >&2; exit 1;;
esac

#!/bin/sh

. /usr/syno/share/dsmupdate/dsmupdate.subr

ETC_BUILD_NUM=""
ETC_DEFAULTS_BUILD_NUM=`/bin/get_key_value /etc.defaults/VERSION buildnumber`
ETC_SMALLFIX_NUM="0"
ETC_DEFAULTS_SMALLFIX_NUM=`/bin/get_key_value /etc.defaults/VERSION smallfixnumber`

# PrepareDefaultConfig
PrepareDefaultConfig() {
	if [ $# -eq 0 ]; then
		return 0
	fi

	for DefaultConfigDir in $@; do
		if [ ! -d ${DefaultConfigDir}.defaults ]; then
			echo "Config ${DefaultConfigDir}.defaults is not exist" >> /.prepare_default_config_failed
			continue
		fi
		/bin/rm -rf $DefaultConfigDir/*
		/bin/rm -rf $DefaultConfigDir/.[^.]*
		/bin/mkdir -p $DefaultConfigDir
		/bin/cp -af ${DefaultConfigDir}.defaults/* ${DefaultConfigDir}/
	done
}

if [ -f /etc/VERSION ]; then
	ETC_BUILD_NUM=`/bin/get_key_value /etc/VERSION buildnumber`
	ETC_SMALLFIX_NUM=`/bin/get_key_value /etc/VERSION smallfixnumber`
fi

IsMigrateBootUp() {
	if [ -f /.updater -a -f /.old_patch_info/VERSION ]; then
		return 0
	fi
	return 1
}

# Replace new default config if
# new install (passwd and group are symbolic link) or upgrade (version not match)
if IsMigrateBootUp || [ -h /etc/passwd -o -h /etc/group -o "${ETC_BUILD_NUM}" != "${ETC_DEFAULTS_BUILD_NUM}" ]; then
	/bin/mkdir -p /.syno/dsminfo
	/bin/echo "Prepare config for ${ETC_DEFAULTS_BUILD_NUM}" >> /.syno/dsminfo/default_config.log
	/bin/date >> /.syno/dsminfo/default_config.log

	# backup version file for ddsm
	if /usr/syno/bin/synoddsmtool --is-ddsm; then
		OLD_PATCH_DIR="/.old_patch_info"
		/bin/rm -rf ${OLD_PATCH_DIR}
		/bin/mkdir -p ${OLD_PATCH_DIR}
		/bin/cp /etc/VERSION ${OLD_PATCH_DIR}/VERSION
		/bin/cp /etc/synoinfo.conf ${OLD_PATCH_DIR}/synoinfo.conf
	fi

	BackupConfig "/" "/"

	PrepareDefaultConfig "/etc" "/var" "/usr/syno/etc"

	# Remove file who should NOT be preserved after replace default config
	if [ -h /.upd@te/etc/passwd ]; then
		/bin/rm -f /.upd@te/etc/passwd
	fi
	if [ -h /.upd@te/etc/group ]; then
		/bin/rm -f /.upd@te/etc/group
	fi
	if [ -f /.upd@te/etc/VERSION ]; then
		/bin/rm -f /.upd@te/etc/VERSION
	fi

	if /usr/syno/bin/synoddsmtool --is-ddsm; then
		RestoreConfig "/" "/" "no"
	else
		RestoreConfig "/" "/" "yes"
	fi

	/bin/touch /var/.UpgradeBootup
fi

# untar indexdb
if [ -f /.SynoUpgradeIndexdb.txz ]; then
	/bin/tar xf /.SynoUpgradeIndexdb.txz -C /usr/syno/synoman/indexdb
	/bin/rm -f /.SynoUpgradeIndexdb.txz
fi
# untar synohdpack
if [ -f /.SynoUpgradeSynohdpackImg.txz ]; then
	/bin/tar xf /.SynoUpgradeSynohdpackImg.txz -C /
	/bin/rm -f /.SynoUpgradeSynohdpackImg.txz
fi

# Prepare if normal bootup without default config
if [ ! -d /etc ]; then
	PrepareDefaultConfig "/etc"
fi
if [ ! -d /var ]; then
	PrepareDefaultConfig "/var"
fi
if [ ! -d /usr/syno/etc ]; then
	PrepareDefaultConfig "/usr/syno/etc"
fi

# Copy from linuxrc.syno
/bin/rm -rf /var/tmp
/bin/mkdir -p /var/tmp
/bin/chmod 755 /var
/bin/chmod 777 /var/tmp
/bin/rm -rf /usr/syno/etc/rc.sysv
/bin/ln -s /usr/syno/etc.defaults/rc.sysv /usr/syno/etc/rc.sysv

if /usr/syno/bin/synoddsmtool --is-ddsm > /dev/null 2>&1 && [ "${ETC_SMALLFIX_NUM}" != "${ETC_DEFAULTS_SMALLFIX_NUM}" ]; then
	if [ ! -d /smallupd@te -a -f /usr/syno/etc/smallupdate_patch/autoupd@te.info ]; then
		/bin/mkdir -p /.syno/dsminfo
		/bin/echo "Restore backup file for smallupdate [orig=$ETC_DEFAULTS_SMALLFIX_NUM, new=$ETC_SMALLFIX_NUM]" >> /.syno/dsminfo/default_config.log
		/usr/syno/sbin/synoupgrade --restore-smallupdate
	fi
fi

sync ; sync ; sync

if [ -f /.prepare_default_config_failed ]; then
	/bin/touch /.noroot
	/sbin/reboot
	exit 1
fi

#!/bin/bash
# Copyright (c) 2000-2019 Synology Inc. All rights reserved.

is_nslcd_enable() {
	# synoservice --is-enable nslcd => retune 1:enable, 0:disable
	if synoservice --is-enable nslcd >/dev/null; then
		return 1
	fi
	return 0
}

is_booting_up() {
	if /usr/syno/bin/synobootseq --is-booting-up > /dev/null 2>&1 ; then
		return 0
	fi
	return 1
}

sss_get_domain() {
	echo $(awk -F'= ' '/^domains/{print $2}' /etc/sssd/sssd.conf)
}

sss_get_host() {
	echo $(awk -F'= ' '/^ldap_uri/{ sub(".*://", "", $2); print $2}' /etc/sssd/sssd.conf)
}

# trigger_hook [action] [domain] [host_uri]
trigger_hook() {
	if [ $# -lt 3 ]; then
		return 1
	fi

	act="$1"
	dom="$2"
	host="$3"
	syno_hook_trgr -a ${act} -e TYPE=ldap,DOMAIN=${dom},HOST_URI=${host},RESULT=0 dirsvs dirsvs_join
}

sss_recover() {
	if /usr/syno/bin/synobootseq --is-shutdown > /dev/null 2>&1 ; then
		return 0
	fi

	IS_LDAP_BINDED="no"
	if is_nslcd_enable; then
		IS_LDAP_BINDED="yes"
	fi

	ONLY_POST="no"
	if [ $# -ge 1 ] && [ "xonly_post" == "x$1" ]; then
		ONLY_POST="yes"
	fi

	domain=$(sss_get_domain)
	host=$(sss_get_host)

	if [ "x${IS_LDAP_BINDED}" == "xyes" ] && [ "xno" == "x${ONLY_POST}" ]; then
		trigger_hook pre $domain $host
	fi

	REPLACE_MOD=""
	if [ "x${IS_LDAP_BINDED}" == "xyes" ]; then
		REPLACE_MOD=" ldap"
	fi
	# recover nss
	echo "recover nsswitch.conf"
	sed -i "/^passwd/s/ sss/${REPLACE_MOD}/g" /etc/nsswitch.conf
	sed -i "/^shadow/s/ sss/${REPLACE_MOD}/g" /etc/nsswitch.conf
	sed -i "/^group/s/ sss/${REPLACE_MOD}/g" /etc/nsswitch.conf

	# recover pam
	echo "recover pam module."
	umount -f -l /usr/lib/security/pam_ldap.so

	if [ "x${IS_LDAP_BINDED}" == "xyes" ]; then
		trigger_hook post $domain $host
	fi
}

sss_prestart_sssd() {
	/usr/bin/chmod 600 /etc/sssd/sssd.conf

	if is_nslcd_enable ; then
		echo "nslcd is enable."
	else
		echo "nslcd is not enable."
		return 1
	fi

	if ! is_booting_up ; then
		echo "setup nsswitch.conf..."
		if grep 'passwd' /etc/nsswitch.conf | grep -q 'ldap' \
			&& grep 'shadow' /etc/nsswitch.conf | grep -q 'ldap' \
			&& grep 'group' /etc/nsswitch.conf | grep -q 'ldap'; then

			trigger_hook pre $(sss_get_domain) $(sss_get_host)
			sed -i '/^passwd/s/ldap/sss/g' /etc/nsswitch.conf
			sed -i '/^shadow/s/ldap/sss/g' /etc/nsswitch.conf
			sed -i '/^group/s/ldap/sss/g' /etc/nsswitch.conf
		else
			echo "nsswitch.conf should has ldap module first."
			return 1
		fi
	fi

	echo "setup pam..."
	if grep -q "pam_ldap.so" /proc/mounts; then
		echo "pam_ldap.so already binded."
	else
		mount --bind /usr/lib/security/pam_sss.so /usr/lib/security/pam_ldap.so
	fi
}

sss_poststart_sssd() {
	if ! is_booting_up; then
		trigger_hook post $(sss_get_domain) $(sss_get_host)
	fi
}

if [ $# -lt 1 ]; then
	echo "Does not give action."
	exit 1
else
	action=$1
	shift
fi

case $action in
	prestart_sssd)
		sss_prestart_sssd
		;;
	poststart_sssd)
		sss_poststart_sssd
		;;
	prestop_sssd)
		sss_recover
		;;
	poststop_sssd)
		sss_recover only_post
		;;
	*)
		exit 1
		;;
esac
# vim: noet: ts=4:

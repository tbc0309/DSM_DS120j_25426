#!/bin/sh

SZ_RULE_NAME=05-system-default.rules
SZD_UDEV_RULES=/lib/udev/rules.d
SZF_DEFAULT_RULE=${SZD_UDEV_RULES}/${SZ_RULE_NAME}
SZF_TMP_DEFAULT_RULE=/lib/udev/${SZ_RULE_NAME}

# dump the env rules, $1 env key, $2 env value"
dump_env_rule() {
	/bin/echo "ENV{$1}=\"$2\"" >> $SZF_TMP_DEFAULT_RULE
}

# create new rule file to replace old one
gen_new_rule() {

	PLATFORM=`/bin/get_key_value /etc.defaults/synoinfo.conf unique | cut -d"_" -f2`
	dump_env_rule "SYNO_INFO_PLATFORM_NAME" $PLATFORM

	KERNEL_VERSION=`/bin/uname -r | /usr/bin/cut -d'.' -f1-2`
	dump_env_rule "SYNO_KERNEL_VERSION" $KERNEL_VERSION

	SUPPORT_SAS=`/bin/get_key_value /etc.defaults/synoinfo.conf supportsas`
	if [ -n "$SUPPORT_SAS" ]; then
		dump_env_rule "SYNO_SUPPORT_SAS" $SUPPORT_SAS
	fi
	SUPPORT_DUALHEAD=`/bin/get_key_value /etc.defaults/synoinfo.conf support_dual_head`
	if [ -n "$SUPPORT_DUALHEAD" ]; then
		dump_env_rule "SYNO_SUPPORT_DUALHEAD" $SUPPORT_DUALHEAD
	fi
	SUPPORT_XA=`/bin/get_key_value /etc.defaults/synoinfo.conf support_xa`
	if [ -n "SUPPORT_XA" ]; then
		dump_env_rule "SYNO_SUPPORT_XA" $SUPPORT_XA
	fi
	BLOCK_OPTIONAL_USB=`/bin/get_key_value /etc.defaults/synoinfo.conf block_optional_usb`
	if [ -n "$BLOCK_OPTIONAL_USB" ]; then
		dump_env_rule "SYNO_BLOCK_OPTIONAL_USB" $BLOCK_OPTIONAL_USB
	fi

	/bin/mv -f $SZF_TMP_DEFAULT_RULE $SZF_DEFAULT_RULE
}

# remove old tmp file
init() {
	/bin/rm -f $SZF_TMP_DEFAULT_RULE
}

case "$1" in
	'gen-rule-file')
		# remove old tmp file
		init
		# generate new file
		gen_new_rule
	;;
	*)
		echo "Usages: $0 gen-rule-file"
	;;
esac

#!/bin/sh

if [ "`/bin/get_key_value /etc/synoinfo.conf support_dual_head`" == "yes" ]; then
	echo 1 > /proc/sys/kernel/syno_enc_pwr_ctl
fi


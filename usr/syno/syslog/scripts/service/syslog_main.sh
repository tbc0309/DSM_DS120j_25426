#!/bin/sh
# Copyright (c) 2000-2014 Synology Inc. All rights reserved.

######################################################################################################################
# script to generate syslog-ng relative configurations,
#
#   - native log    | /etc/syslog-ng/syslog.conf               | always enable
#   - Synology log  | /etc/syslog-ng/syno.d/synolog.conf       | always enable
#   - Log accounting| /etc/syslog-ng/syno.d/syslog-acc.conf    | always enable
######################################################################################################################

SYSLOGNG_CONFIG_FOLDER=/etc/syslog-ng/patterndb.d
SYSLOGNG_CONFIG_NOTIFICATION=${SYSLOGNG_CONFIG_FOLDER}/syslog-notification.conf

SYSLOGNG_NOTIFY_SETTING=/etc/synosyslog/notify.conf

SYSLOGNG_SCRIPT_FOLDER=/usr/syno/syslog/scripts/service
. ${SYSLOGNG_SCRIPT_FOLDER}/syslog_common.sh
. ${SYSLOGNG_SCRIPT_FOLDER}/syslog_notification.sh

Usage(){
    echo "Usage: $0 (acc|client|bsd|ietf|localarch|notification|custrule) (confgen|confclr)"
}

case $1 in
    notification)
        case $2 in
            confgen)
                SyslogNotificationConfigGen
            ;;
            confclr)
                SyslogNotificationConfigClr
            ;;
            *)
                Usage
            ;;
        esac
    ;;
    *)
        Usage
    ;;
esac


#!/bin/sh
# Copyright (c) 2000-2014 Synology Inc. All rights reserved.

BIN_GET_SKV=/usr/syno/bin/get_section_key_value

SyslogNotificationConfigGen(){
    NotificationSettingGet

    NotificationConfDataClear
    touch ${SYSLOGNG_CONFIG_NOTIFICATION}

    NotificationRewrite
    NotificationSeverity
    NotificationKeyword
}

SyslogNotificationConfigClr(){
    NotificationConfDataClear
}

########################
NotificationSettingGet(){
    NOTIFY_SEV_ENABLE=`${BIN_GET_SKV} ${SYSLOGNG_NOTIFY_SETTING} pri notify_enable`
    NOTIFY_SEV_VALUE=`${BIN_GET_SKV} ${SYSLOGNG_NOTIFY_SETTING} pri notify_pri`

    NOTIFY_KW_ENABLE=`${BIN_GET_SKV} ${SYSLOGNG_NOTIFY_SETTING} pat_1 notify_enable`
    NOTIFY_KW_VALUE_1=`${BIN_GET_SKV} ${SYSLOGNG_NOTIFY_SETTING} pat_1 notify_pat`
    NOTIFY_KW_VALUE_2=`${BIN_GET_SKV} ${SYSLOGNG_NOTIFY_SETTING} pat_2 notify_pat`
    NOTIFY_KW_VALUE_3=`${BIN_GET_SKV} ${SYSLOGNG_NOTIFY_SETTING} pat_3 notify_pat`
}

NotificationConfDataClear(){
    rm -rf ${SYSLOGNG_CONFIG_NOTIFICATION} > /dev/null 2>&1
}

NotificationRewrite() {
    # escape \ and "
    echo "rewrite r_syno_escape_double_quote { subst(\"\x22\", \"\", value(\"MESSAGE\"), flags(\"global\")); };" >> ${SYSLOGNG_CONFIG_NOTIFICATION}
    echo "rewrite r_syno_escape_backslash { subst(\"\\\\\\\\\", \"\", value(\"MESSAGE\"), flags(\"global\")); };" >> ${SYSLOGNG_CONFIG_NOTIFICATION}
}

NotificationSeverityFilterProcess(){
    SEV_RANGE="emerg"
    #format of syslog-ng: emerg, alert, crit, err, warning, notice, info, debug

    if [ "0" == ${NOTIFY_SEV_VALUE} ]; then
        SEV_RANGE="emerg"
    elif [ "1" == ${NOTIFY_SEV_VALUE} ]; then
        SEV_RANGE="alert..emerg"
    elif [ "2" == ${NOTIFY_SEV_VALUE} ]; then
        SEV_RANGE="crit..emerg"
    elif [ "3" == ${NOTIFY_SEV_VALUE} ]; then
        SEV_RANGE="err..emerg"
    fi

    # create severity filter rule
    echo "filter f_syno_severity { level(${SEV_RANGE}); };" >> ${SYSLOGNG_CONFIG_NOTIFICATION}
}

NotificationSeverityDestProcess(){
    # create severity destination rule
    echo "destination d_syno_severity_notification {
        pipe(\"/tmp/syslog_recv.fifo\"
            template(\"{
                \\\"hostname\\\": \\\"\$HOST\\\",
                \\\"command\\\": \\\"NTF\\\",
                \\\"ntf_type\\\": \\\"severity\\\",
                \\\"severity\\\": \\\"\$LEVEL\\\",
                \\\"content\\\": \\\"\$MSGONLY\\\"
            }\")
            log_fifo_size(50000)
        );
    };" >> ${SYSLOGNG_CONFIG_NOTIFICATION}
}

NotificationSeverityLogProcess(){
    # create severity rule for available source local
    echo "log { source(s_syno_syslog); filter(f_syno_severity); filter(f_sys_conn_xfer); rewrite(r_syno_escape_double_quote); rewrite(r_syno_escape_backslash); destination(d_syno_severity_notification); };" \
    >> ${SYSLOGNG_CONFIG_NOTIFICATION}
}

NotificationKeywordFilterProcess(){
    # create keyword filter rule
    if [ ! -z "${NOTIFY_KW_VALUE_1}" ]; then
        echo "filter f_syno_keyword_1 { message(\"${NOTIFY_KW_VALUE_1}\"); };" \
        >> ${SYSLOGNG_CONFIG_NOTIFICATION}
    fi

    if [ ! -z "${NOTIFY_KW_VALUE_2}" ]; then
        echo "filter f_syno_keyword_2 { message(\"${NOTIFY_KW_VALUE_2}\"); };" \
        >> ${SYSLOGNG_CONFIG_NOTIFICATION}
    fi

    if [ ! -z "${NOTIFY_KW_VALUE_3}" ]; then
        echo "filter f_syno_keyword_3 { message(\"${NOTIFY_KW_VALUE_3}\"); };" \
        >> ${SYSLOGNG_CONFIG_NOTIFICATION}
    fi
}

NotificationKeywordDestProcess(){
    # create keyword destination rule
    if [ ! -z "${NOTIFY_KW_VALUE_1}" ]; then
        echo "destination d_syno_keyword_notification_1 {
            pipe(\"/tmp/syslog_recv.fifo\"
                template(\"{
                    \\\"hostname\\\": \\\"\$HOST\\\",
                    \\\"command\\\": \\\"NTF\\\",
                    \\\"ntf_type\\\": \\\"keyword\\\",
                    \\\"keyword\\\": \\\"${NOTIFY_KW_VALUE_1}\\\",
                    \\\"content\\\": \\\"\$MSGONLY\\\"
                }\")
                log_fifo_size(50000)
            );
        };" >> ${SYSLOGNG_CONFIG_NOTIFICATION}
    fi

    if [ ! -z "${NOTIFY_KW_VALUE_2}" ]; then
        echo "destination d_syno_keyword_notification_2 {
            pipe(\"/tmp/syslog_recv.fifo\"
                template(\"{
                    \\\"hostname\\\": \\\"\$HOST\\\",
                    \\\"command\\\": \\\"NTF\\\",
                    \\\"ntf_type\\\": \\\"keyword\\\",
                    \\\"keyword\\\": \\\"${NOTIFY_KW_VALUE_2}\\\",
                    \\\"content\\\": \\\"\$MSGONLY\\\"
                }\")
                log_fifo_size(50000)
            );
        };" >> ${SYSLOGNG_CONFIG_NOTIFICATION}
    fi

    if [ ! -z "${NOTIFY_KW_VALUE_3}" ]; then
        echo "destination d_syno_keyword_notification_3 {
            pipe(\"/tmp/syslog_recv.fifo\"
                template(\"{
                    \\\"hostname\\\": \\\"\$HOST\\\",
                    \\\"command\\\": \\\"NTF\\\",
                    \\\"ntf_type\\\": \\\"keyword\\\",
                    \\\"keyword\\\": \\\"${NOTIFY_KW_VALUE_3}\\\",
                    \\\"content\\\": \\\"\$MSGONLY\\\"
                }\")
                log_fifo_size(50000)
            );
        };" >> ${SYSLOGNG_CONFIG_NOTIFICATION}
    fi
}

ProcessLocalLog(){
    if [ ! -z "${NOTIFY_KW_VALUE_1}" ]; then
        echo "log { source(s_syno_syslog); filter(f_syno_keyword_1); filter(f_sys_conn_xfer); rewrite(r_syno_escape_double_quote); rewrite(r_syno_escape_backslash); destination(d_syno_keyword_notification_1); };" \
        >> ${SYSLOGNG_CONFIG_NOTIFICATION}
    fi
    if [ ! -z "${NOTIFY_KW_VALUE_2}" ]; then
        echo "log { source(s_syno_syslog); filter(f_syno_keyword_2); filter(f_sys_conn_xfer); rewrite(r_syno_escape_double_quote); rewrite(r_syno_escape_backslash); destination(d_syno_keyword_notification_2); };" \
        >> ${SYSLOGNG_CONFIG_NOTIFICATION}
    fi
    if [ ! -z "${NOTIFY_KW_VALUE_3}" ]; then
        echo "log { source(s_syno_syslog); filter(f_syno_keyword_3); filter(f_sys_conn_xfer); rewrite(r_syno_escape_double_quote); rewrite(r_syno_escape_backslash); destination(d_syno_keyword_notification_3); };" \
        >> ${SYSLOGNG_CONFIG_NOTIFICATION}
    fi
}

NotificationKeywordLogProcess(){
    ProcessLocalLog
}

NotificationSeverity(){
    if [ "0" == ${NOTIFY_SEV_ENABLE} ]; then
        return
    fi

    NotificationSeverityFilterProcess
    NotificationSeverityDestProcess
    NotificationSeverityLogProcess
}
NotificationKeyword(){
    if [ "0" == ${NOTIFY_KW_ENABLE} ]; then
        return
    fi

    NotificationKeywordFilterProcess
    NotificationKeywordDestProcess
    NotificationKeywordLogProcess
}



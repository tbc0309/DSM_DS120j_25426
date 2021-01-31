#!/bin/sh
# Copyright (c) 2000-2014 Synology Inc. All rights reserved.

SyslogAccountingReload(){
    IsServiceRunning "syslog-acc"

    if [ "1" == ${SERVICE_RUNNING} ]; then
        synoservice --reload "syslog-acc"
    else
        synoservice --soft-start "syslog-acc"
    fi
}


IsServiceEnable(){
    SERVICE_ENABLE=0
    synoservice --is-enabled $1
    if [ "1" = "$?" ]; then
        SERVICE_ENABLE=1
    fi
}

IsServiceRunning(){
    SERVICE_RUNNING=0
    synoservice --status $1
    if [ "0" = "$?" ]; then
        SERVICE_RUNNING=1
    fi
}

SearviceRestart(){
    IsServiceRunning $1

    if [ "1" == ${SERVICE_RUNNING} ]; then
        synoservice --reload $1
    else
        synoservice --soft-start $1
    fi
}

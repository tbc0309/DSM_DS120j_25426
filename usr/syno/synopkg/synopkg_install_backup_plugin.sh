#!/bin/sh
# Copyright (c) 2000-2014 Synology Inc. All rights reserved.

BIN_INSTALL=/usr/syno/sbin/install_backup_plugin.sh

if [ "x${SYNOPKG_PKG_STATUS}" = "xINSTALL" -o "x${SYNOPKG_PKG_STATUS}" = "xUPGRADE" ];then
	${BIN_INSTALL} ${SYNOPKG_PKGNAME}
fi


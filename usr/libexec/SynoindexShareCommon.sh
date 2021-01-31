#!/bin/sh

SYNOINDEX_PKG_NAME="Synoindex"
SYNOINDEX_PKG_VERSION="1.0"
SYNOINDEX_PKG_VENDOR="Synology Inc."
SYNOINDEX_PKG_MODVER="2.0"

SYNOINDEX_SHARE_NAME=""
SYNOINDEX_SHARE_PATH=""
SYNOINDEX_SHARE_NAME_OLD=""
SYNOINDEX_SHARE_PATH_OLD=""

BIN_INDEXFOLDER=/usr/syno/bin/indexfolder
BIN_SYNOINDEX=/usr/syno/bin/synoindex

CheckExternalPath() {
	if [ "/volumeUSB" = "${1:0:10}" -o "/volumeSATA" = "${1:0:11}" ]; then
		return 0
	fi
	return 1
}

SynoindexShareCreate(){
    SYNOINDEX_RESULT=`${BIN_INDEXFOLDER} --type=SHARE_CREATE --share="${SYNOINDEX_SHARE_NAME}" --share_path="${SYNOINDEX_SHARE_PATH}"`
}

SynoindexShareRename(){
    SYNOINDEX_RESULT=`${BIN_INDEXFOLDER} --type=SHARE_RENAME --share="${SYNOINDEX_SHARE_NAME}" --share_path="${SYNOINDEX_SHARE_PATH}" --old_share="${SYNOINDEX_SHARE_NAME_OLD}" --old_share_path="${SYNOINDEX_SHARE_PATH_OLD}"`
}

SynoindexShareRemove(){
	SYNOINDEX_RESULT=0
	CheckExternalPath "$SYNOINDEX_SHARE_PATH"
	if [ 1 -eq $? ]; then
		SYNOINDEX_RESULT=`${BIN_INDEXFOLDER} --type=SHARE_REMOVE --share="${SYNOINDEX_SHARE_NAME}" --share_path="${SYNOINDEX_SHARE_PATH}"`
	fi
}

SynoindexRemove(){
	${BIN_SYNOINDEX} -D "${SYNOINDEX_SHARE_PATH}" &
}

SynoindexReindex(){
	${BIN_SYNOINDEX} -R "${SYNOINDEX_SHARE_PATH}" &
}

SynoindexAdd(){
	${BIN_SYNOINDEX} -A "${SYNOINDEX_SHARE_PATH}" &
}

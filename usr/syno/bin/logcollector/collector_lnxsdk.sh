#!/bin/sh

SZD_TMP="$1"

mkdir -p $SZD_TMP
cp --parents /tmp/eunitinfo_* $SZD_TMP
exit 0

#!/bin/sh

SZD_TMP=$1
# for iproute2 related info
mkdir -p "$SZD_TMP"/result
ip -4 rule > "$SZD_TMP"/result/"ip-4-rule.result" 2>&1
ip -6 rule > "$SZD_TMP"/result/"ip-6-rule.result" 2>&1

exit 0

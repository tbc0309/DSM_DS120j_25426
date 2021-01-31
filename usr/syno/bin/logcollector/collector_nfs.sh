#!/bin/sh

SZD_TMP=$1
mkdir -p "$SZD_TMP"/result/
nfs_status=$(synoservice --status nfsd | awk 'NR==1{print $3}')
if [ "status=[enable]" = "$nfs_status" ];
then
  /sbin/rpcinfo -p > "$SZD_TMP"/result/rpcinfo_probe.result 2>&1
  /sbin/showmount -e > "$SZD_TMP"/result/showmount_exports.result 2>&1

  # collect all nfs mount clients
  /usr/sbin/showmount --all > "$SZD_TMP"/result/showmount.result
fi

exit 0

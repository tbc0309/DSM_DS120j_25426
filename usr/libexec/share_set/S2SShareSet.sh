#!/bin/sh

PKG_INFO="/usr/syno/bin/s2s_hook_info"
SHARE_HOOK="/usr/syno/bin/s2s_share_hook"

case $1 in
	# print package info
	--name|--pkg-ver|--vendor)
		${PKG_INFO} $1
	;;

	# print SDK module version
	--sdk-mod-ver)
		${SHARE_HOOK} --sdk-mod-ver
	;;

	# execute pre hook
	--pre)
		${SHARE_HOOK} --pre-set
	;;

	# execute post hook
	--post)
		${SHARE_HOOK} --post-set
	;;

	*)
	;;
esac

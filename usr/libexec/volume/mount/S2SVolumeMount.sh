#!/bin/sh

PKG_INFO="/usr/syno/bin/s2s_hook_info"
HOOK_BIN="/usr/syno/bin/s2s_volume_hook"

case $1 in
	# print package info
	--name|--pkg-ver|--vendor)
		${PKG_INFO} $1
	;;

	# print SDK module version
	--sdk-mod-ver)
		${HOOK_BIN} --sdk-mod-ver
	;;

	# execute pre hook
	--pre)
		${HOOK_BIN} --pre-mount
	;;

	# execute post hook
	--post)
		${HOOK_BIN} --post-mount
	;;

	*)
	;;
esac

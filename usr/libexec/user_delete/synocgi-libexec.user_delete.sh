#!/bin/sh

SYNOCGID_BINARY=/usr/syno/sbin/synocgitool

SYNOCGID_PKG_NAME="synocgid"
SYNOCGID_PKG_VERSION="1.0"
SYNOCGID_PKG_VENDOR="Synology Inc."
SYNOCGID_PKG_MODVER="1.0"

case $1 in
	--sdk-mod-ver)
		echo ${SYNOCGID_PKG_MODVER}
	;;
	--name)
		echo ${SYNOCGID_PKG_NAME}
	;;
	--pkg-ver)
		echo ${SYNOCGID_PKG_VERSION}
	;;
	--vendor)
		echo ${SYNOCGID_PKG_VENDOR}
	;;
	--pre)
	;;
	--post)
		if [ -f "${SYNOCGID_BINARY}" ]; then
			INDEX=1
			while [ "${INDEX}" -le "${NITEMS}" ]
			do
				eval "USER=\$USER_NAME_$INDEX"
				if [ -n "${USER}" -a "${USER}" != "SynologyCMS" ]; then
					logger -p user.warn -t synocgitool "hook[user_delete] Username (${USER}) deleted. - Kick user[${USER}]"
					${SYNOCGID_BINARY} --kick_user_session ${USER}
				fi
				INDEX=$((INDEX + 1))
			done
		fi
		;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac

#!/bin/sh

SYNODRCRED_BINARY=/usr/syno/synodr/sbin/synodrcred

SYNODR_PKG_NAME="SynoDRNode"
SYNODR_PKG_VERSION="1.0"
SYNODR_PKG_VENDOR="Synology Inc."
SYNODR_PKG_MODVER="1.0"

case $1 in
	--sdk-mod-ver)
		echo ${SYNODR_PKG_MODVER}
	;;
	--name)
		echo ${SYNODR_PKG_NAME}
	;;
	--pkg-ver)
		echo ${SYNODR_PKG_VERSION}
	;;
	--vendor)
		echo ${SYNODR_PKG_VENDOR}
	;;
	--pre)
	;;
	--post)
		if [ -f "${SYNODRCRED_BINARY}" ]; then
			INDEX=1
			while [ "${INDEX}" -le "${NITEMS}" ]
			do
				eval "OP_RET=\$USER_OP_RESULT_${INDEX}"
				if [ "0x0000" == "${OP_RET}" ]; then
					eval "ORIGIN_USER=\$ORIGIN_USER_NAME_${INDEX}"

					if [ -n "${ORIGIN_USER}" ]; then
						eval "USER=\$USER_NAME_$INDEX"
						eval "EXPIRE_STATE=\$EXPIRE_STATE_${INDEX}"
						if [ "${USER}" != "${ORIGIN_USER}" -o "disabled" == "${EXPIRE_STATE}" ]; then
							logger -p user.warn -t synodrnode "Delete session of user[${ORIGIN_USER}] by user-set hook (name[${USER}]/expire[${EXPIRE_STATE}])"
							${SYNODRCRED_BINARY} session delete_by_user ${ORIGIN_USER}
						fi
					fi
				fi
				INDEX=$((INDEX + 1))
			done
		fi
		;;
	*)
		echo "Usage: $0 --sdk-mod-ver|--name|--pkg-ver|--vendor|--pre|--post"
	;;
esac

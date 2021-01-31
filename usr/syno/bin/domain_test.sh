#! /usr/bin/env sh
NET=`which net`
SMB_CONF="/etc/samba/smb.conf"

realm=`synogetkeyvalue /etc/samba/smb.conf realm`
workgroup=`synogetkeyvalue /etc/samba/smb.conf workgroup`

log()
{
	MESSAGE="$1"
	echo "$MESSAGE"
	logger -p user.warning -t domain_test "$MESSAGE"
}

usage()
{
echo "\
usage: $0 [-h] -a []

optional arguments:
  -h, --help		   show this help message and exit
  --timeSynced		   check if time synced
  --hostnameConflict   check if hostname conflict in subnet
  --testMTU		  check MTU
  --testDC		  check DC by dig
  --testKrb		  check Krb by dig
  --testLdap	  check ldap by dig
"
}

EXEC_TIMEOUT()
{
	local PID=0
	local retry=60	#timeout 60s align testjoin
	$@ &
	PID=$!
	while [ $retry -gt 0 ] && [ -d "/proc/$PID" ] > /dev/null;
	do
		sleep 1
		retry=$(($retry-1))
	done
	if [ $retry = 0 ]; then
		kill -9 $PID
	fi
	wait $PID
	return $?
}

test_check()
{
	local domainType=`synogetkeyvalue ${SMB_CONF} security`
	if [ "$domainType" != "ads" ]; then
		echo "Test only support ADS domain"
		exit 1
	fi
}

_GETKeyValue()
{
	key="$1"
	file="$2"
	var=`synogetkeyvalue $2 "$1"`
	echo "$var"
}
_PING()
{
	local ip="$1"
	if [ 2 -eq $# ]; then
		local mtu=`expr $2 - 28` # reduce tcp header length
		ret=`ping -c 1 -W 5 -s "$mtu" "$ip" | grep receive | cut -d ',' -f 2`
	else
		ret=`ping -c 1 -W 5 "$ip" | grep receive | cut -d ',' -f 2`
	fi
	if [ "1" == "${ret:1:1}" ]; then
		return 0
	fi
	return 1
}
_BIND()
{
	local ip="$1"
	if EXEC_TIMEOUT net ads auth -P -S $ip > /dev/null 2>&1; then
		return 0
	fi
	return 1
}
_KRB5()
{
	local ip="$1"
	if EXEC_TIMEOUT smbclient -P -L //${ip} -k > /dev/null 2>&1; then
		return 0
	fi
	return 1
}
_NTLM()
{
	local ip="$1"
	if EXEC_TIMEOUT smbclient -P -L //${ip} > /dev/null 2>&1; then
		return 0
	fi
	return 1
}
_LDAP()
{
	local ip="$1"
	EXEC_TIMEOUT net ads info -S $ip >/dev/null
}

timeSynced()
{
	ret=`net ads info 2>/dev/null | grep Server_time_offset | cut -d '=' -f 2 | cut -d '"' -f 2`
	if [ -z "$ret" ]; then
		log "Failed to get time"
		return 1
	fi
	if [ "0" -gt "$ret" ]; then
		ret=$((-$ret))
	fi

	if [ "300" -le "$ret" ]; then
		log "The difference of time is over 300"
		return 1
	fi

	return 0
}
hostnameConflict()
{
	local hostname=`hostname | awk '{print toupper($0)}'`
	local IPs=`synonet --show | grep IP | cut -d' ' -f2`
	local CFL_LOG=""
	if [ "$hostname" == "$workgroup" ]; then
		log "hostname is equal to workgroup"
		return 1
	fi

	CFL_LOG=`synowin -checkDNSHostConflict`
	if [ $? = 1 ]; then
		log "$CFL_LOG"
		return 1
	fi

	return 0
}
testMTU()
{
	${NET} lookup kdc | sed 's/:88$//' | sed 's/:389$//' | while read _ip_
	do
		local _mtu_=`synonet --show | grep "MTU Setting" | cut -d ":" -f 2 | head -n1`
		if ! _PING $_ip_ $_mtu_; then
			log "Server $_ip_ has no response cuz MTU issue"
			return 1
		fi
	done
	return $?
}
testDC()
{
	${NET} lookup dc | sed 's/:88$//' | sed 's/:389$//' | while read _ip_
	do
		if ! _BIND $_ip_; then
			log "Failed to bind DC $_ip_"
			return 1
		fi
		if ! _NTLM $_ip_; then
			log "Failed to check NTLM of DC $_ip_"
			return 1
		fi
	done
	return $?
}
testKrb()
{
	${NET} lookup kdc | sed 's/:88$//' | sed 's/:389$//' | while read _ip_
	do
		if ! _PING $_ip_; then
			log "Failed to ping krb $_ip_"
			return 1
		fi
		if ! _KRB5 $_ip_; then
			log "Failed to test krb5 $_ip_"
			return 1
		fi
	done
	return $?
}

testLdap()
{
	${NET} lookup ldap "$realm" | sed 's/:88$//' | sed 's/:389$//' | while read _ip_
	do
		if ! _PING $_ip_; then
			log "Failed to ping ldap $_ip_"
			return 1
		fi
		if ! _LDAP $_ip_; then
			log "Failed to test ldap $_ip_"
			return 1
		fi
	done
	return $?
}


test_check
TEST_RET=0
while [ -n "$1" ]; do
	case "$1" in
		--timeSynced)
			timeSynced
			TEST_RET=$?
		;;
		--hostnameConflict)
			hostnameConflict
			TEST_RET=$?
		;;
		--testDC)
			testDC
			TEST_RET=$?
		;;
		--testMTU)
			testMTU
			TEST_RET=$?
		;;
		--testKrb)
			testKrb
			TEST_RET=$?
		;;
		--testLdap)
			testLdap
			TEST_RET=$?
		;;
		-h|--help)
			usage
			TEST_RET=$?
		;;
		-a)
			if ! timeSynced; then
				echo "time is not synced"
				TEST_RET=1
			fi
			if ! hostnameConflict; then
				echo "there are conflict hostname"
				TEST_RET=1
			fi
			if ! testMTU; then
				echo "Default MTU is not suitable"
				TEST_RET=1
			fi
			if ! testDC; then
				echo "DC test failed"
				TEST_RET=1
			fi
			if ! testKrb; then
				echo "Krb test failed"
				TEST_RET=1
			fi
			if ! testLdap; then
				echo "Ldap test failed"
				TEST_RET=1
			fi
		;;
	esac
	shift
done
exit ${TEST_RET}

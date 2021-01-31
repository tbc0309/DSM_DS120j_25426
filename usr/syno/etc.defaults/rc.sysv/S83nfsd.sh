#!/bin/sh
# Copyright (c) 2000-2008 Synology Inc. All rights reserved.

. /etc.defaults/rc.subr

LinuxVersionCode=$(KernelVersionCode $(KernelVersion))
ProcName="nfsd"
PidFile="/var/run/${ProcName}.pid"
RM="/bin/rm"
TOUCH="/bin/touch"
SZF_NFS_KRB5_KEY="/etc/nfs/krb5.keytab"
Krb5Principal=`/bin/get_key_value /etc/nfs/syno_nfs_conf kerberos_principal`


# rpcsec_gss_krb5 module is built-in in kernel 2.6.32
if [ $LinuxVersionCode -ne $(KernelVersionCode "2.6.32") ]; then
	KERNELMODULEV4="rpcsec_gss_krb5"
fi
KERNELMODULE="${KERNELMODULEV4} exportfs nfsd"


waitServDead()
{
	local serv="$1"
	local retryCount=0

	while [ $retryCount -le 10 ]
	do
		if ! pidof ${serv}; then
			return
		fi &> /dev/null
		sleep 1
		retryCount=`expr $retryCount + 1`
	done

	killall -9 ${serv}
}

stopNFSServ()
{
	killall statd
	killall mountd
	/bin/rm -rf /var/lib/nfs/sm
	nfsd 0
	killall idmapd
	killall svcgssd
	killall rpcbind

	waitServDead "mountd"
	waitServDead "statd"
	waitServDead "nfsd"
	waitServDead "rpcbind"
	waitServDead "idmapd"
	waitServDead "svcgssd"

	/usr/sbin/exportfs -au >/dev/null 2>&1
	/usr/sbin/exportfs -f >/dev/null 2>&1
}

case $1 in
	start)

		$0 status
		if [ 0 -eq $? ]; then
			exit 0;
		fi

		EnableVersion4=`/bin/get_key_value /etc/nfs/syno_nfs_conf nfsv4_enable`
		EnableCustomPort=`/bin/get_key_value /etc/nfs/syno_nfs_conf nfs_custom_port_enable`

		echo "Starting NFS server..."

		N=`cat /proc/meminfo | grep MemTotal: | awk '{ m = ($2 / 1024 / 32) ; print int(m) +1;}'`
		N=$((N > 128 ? 128 : N))
		if [ x$EnableCustomPort == xyes ] ; then
			NlmPort=`/bin/get_key_value /etc/nfs/syno_nfs_conf nlm_port`
			echo $NlmPort > /proc/sys/fs/nfs/nlm_tcpport
			echo $NlmPort > /proc/sys/fs/nfs/nlm_udpport
		else
			echo 0 > /proc/sys/fs/nfs/nlm_tcpport
			echo 0 > /proc/sys/fs/nfs/nlm_udpport
		fi
		SYNOLoadModules $KERNELMODULE
		/bin/mount -t nfsd none /proc/fs/nfsd
		/usr/sbin/exportfs -r >/dev/null 2>&1
		/sbin/rpcbind
		/usr/sbin/mountd -p 892
		/bin/mkdir -p /var/lib/nfs/v4recovery
		if [ $LinuxVersionCode -ge $(KernelVersionCode "4.4") ]; then
			echo "-4.2" > /proc/fs/nfsd/versions
		fi
		if [ x$EnableVersion4 == xyes ] ; then
			if [ $LinuxVersionCode -ge $(KernelVersionCode "3.10") ]; then
				/usr/sbin/nfsd --nfs-version 4.1 $N
			else
				/usr/sbin/nfsd --no-nfs-version 4.1 $N
			fi
		else
			/usr/sbin/nfsd --no-nfs-version 4 $N
		fi
		/bin/mkdir -p /var/lib/nfs/sm
		/bin/mkdir -p /var/lib/nfs/rpc_pipefs/nfs
		/usr/sbin/idmapd
		if [ $LinuxVersionCode -ge $(KernelVersionCode "3.2") ] && [ -f "$SZF_NFS_KRB5_KEY" ] && [ "x$Krb5Principal" != x ]; then
			/usr/sbin/svcgssd -p $Krb5Principal
		fi

		StatdPort=`/bin/get_key_value /etc/nfs/syno_nfs_conf statd_port`
		if [ x$EnableCustomPort == xyes ] && [ x$StatdPort != x ] ; then
			/usr/sbin/statd -p $StatdPort
		else
			/usr/sbin/statd
		fi
		if [ -f $PidFile ]; then
			$RM $PidFile
		fi

		$TOUCH $PidFile
		echo `pidof $ProcName | awk '{print $NF}'` > $PidFile
	;;
	stop)
		stopNFSServ

		/bin/rm -rf /var/lib/nfs/v4recovery
		/bin/rm -rf /var/lib/nfs/rpc_pipefs/nfs
		/bin/umount /proc/fs/nfsd
		SYNOUnloadModules $KERNELMODULE

		$RM $PidFile
		echo `date +'%s'` > /proc/net/rpc/auth.rpcsec.context/flush
	;;
	status)
		svcgssdErr=0;
		if [ $LinuxVersionCode -ge $(KernelVersionCode "3.2") ] && [ -f "$SZF_NFS_KRB5_KEY" ] && [ "x$Krb5Principal" != x ] && ! pidof svcgssd; then
			svcgssdErr=1;
		fi  &> /dev/null

		if pidof mountd && pidof statd && pidof rpcbind && pidof nfsd && pidof idmapd && [ 0 == $svcgssdErr ] ; then
			if [ -f $PidFile ]; then
				pid=`cat $PidFile`
				if [ 0 != `ps aux | grep $ProcName | grep $pid | wc -l` ]; then
					exit $LSB_STAT_RUNNING
				else
					exit $LSB_STAT_DEAD_FPID
				fi
			fi
			exit $LSB_STAT_RUNNING
		else
			if [ -f $PidFile ]; then
				exit $LSB_STAT_DEAD_FPID
			else
				exit $LSB_STAT_NOT_RUNNING
			fi
		fi &> /dev/null
	;;
	restart)
		$0 stop
		sleep 1
		$0 start
	;;
	reload)
		/usr/syno/sbin/synoservice --is-enabled nfsd
		# skip reload if nfsd is stop
		if [ 1 -eq $? ]; then
			/usr/sbin/exportfs -ar
			exit $?
		fi
		exit 0
	;;
	reloadidmap)
		killall -9 svcgssd
		killall -9 idmapd
		sleep 1
		echo `date +'%s'` > /proc/net/rpc/auth.rpcsec.context/flush
		if [ $LinuxVersionCode -ge $(KernelVersionCode "3.2") ] && [ -f "$SZF_NFS_KRB5_KEY" ] && [ "x$Krb5Principal" != x ]; then
			/usr/sbin/svcgssd -p $Krb5Principal
		fi
		/usr/sbin/idmapd
	;;
	*)
	echo "Usages: $0 [start|stop|restart|status|reload|reloadidmap]"
	;;
esac


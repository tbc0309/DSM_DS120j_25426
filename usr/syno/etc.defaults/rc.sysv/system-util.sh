#!/bin/sh

case $1 in
	handle-umount-root-fail)
		# when the library used by init is update on disk mode,
		# umount root fs to read-only will fail, this issue can be
		# fix by restart init

		# use /proc/maps to check if init finish restart
		old_map=$(cat /proc/1/maps)
		map=$old_map
		i=0
		timeout=5

		# ask init to restart
		telinit u

		while [ "$map" = "$old_map" ]
		do
			sleep 1
			map=$( cat /proc/1/maps )
			i=$((i+1))
			if [ $i -eq $timeout ] ; then
				break
			fi
		done

		if [ "$map" = "$old_map" ] ; then
			echo "FAIL: init failed to respawn in $timeout seconds - unmounting anyway"
		fi

		if ! /bin/umount /; then
			echo "fail to umount root"
		fi

		# if the flag can be success touch, the root fs is not read-only
		if touch /.umount_root_failed > /dev/null 2>&1; then
			echo "umount root failed"
			ps auxf > /.umount_root_failed
		else
			echo "umount root success"
		fi

		# retry and wait until init can handle event
		for i in `seq 1 1 100`; do
			if initctl emit --no-wait umount-root-ok; then
				break;
			fi
			sleep 1
		done
	;;
	*)
		echo "Usages: $0 [handle-umount-root-fail]"
	;;
esac


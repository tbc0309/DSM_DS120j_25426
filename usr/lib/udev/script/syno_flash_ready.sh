#!/bin/sh
BOOT_DEV=$1

if [ ! -f /.burnin_loader.sh ]; then
    exit 0
fi

if [ -c "/dev/$BOOT_DEV" ] || [ -b "/dev/$BOOT_DEV" ]; then
    /usr/bin/logger -p warn "boot device is ready: $BOOT_DEV"
    # emit signal to start B2 /.burnin_loader.sh
    /sbin/initctl emit --no-wait syno.flash.ready
else
    /usr/bin/logger -p err "boot device is NOT ready: $BOOT_DEV"
fi

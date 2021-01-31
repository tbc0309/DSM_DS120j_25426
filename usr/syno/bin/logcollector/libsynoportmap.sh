#!/bin/sh
# expect $1 is target copy direcotry: e.g. /tmp/debug.dat/dsm

target_dir=$1

ETC_PF_DIR=/etc/portforward
VAR_LIB_PF_DIR=/var/lib/portforward

/bin/mkdir -p $target_dir/$ETC_PF_DIR
/bin/cp -f $ETC_PF_DIR/* $target_dir/$ETC_PF_DIR/.
/bin/sed -i -e 's/^user=.*/user=***/g' $target_dir/$ETC_PF_DIR/router.conf*
/bin/sed -i -e 's/^pass=.*/pass=***/g' $target_dir/$ETC_PF_DIR/router.conf*

/bin/mkdir -p $target_dir/$VAR_LIB_PF_DIR
/bin/cp -rf $VAR_LIB_PF_DIR/routerdb $target_dir/$VAR_LIB_PF_DIR/.
/bin/cp -f $VAR_LIB_PF_DIR/* $target_dir/$VAR_LIB_PF_DIR/.


#!/bin/sh
# Copyright (c) 2000-2016 Synology Inc. All rights reserved.
#/usr/syno/bin/syno_disk_db_update
smartDbDir="/var/lib/smartmontools"
/bin/cp -af ${smartDbDir}/synodrivedb.db /tmp/synodrivedb.db
/bin/cp -af ${smartDbDir}/drivedb.db /tmp/drivedb.db

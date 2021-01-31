#!/bin/sh
# Copyright (c) 2000-2015 Synology Inc. All rights reserved.


(flock -n 9 || exit 1) 9> /run/synosdk/lock/lock_pkg
exit $?

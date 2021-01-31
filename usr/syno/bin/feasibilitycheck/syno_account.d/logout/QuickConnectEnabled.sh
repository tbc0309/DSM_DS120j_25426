#!/usr/bin/env sh

synoservice --status synorelayd > /dev/null && exit 1

exit 0

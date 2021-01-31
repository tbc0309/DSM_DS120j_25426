#!/usr/bin/env bash

synoservice --status ddns > /dev/null || exit 0 # ddns service is not started

synoddnsinfo --get-provider-inused | grep -q Synology && exit 1

exit 0

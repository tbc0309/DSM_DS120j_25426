#!/usr/bin/python
# Copyright (c) 2000-2016 Synology Inc. All rights reserved.

from utils import *
import sys
sys.path.append('/var/dynlib/securityscan/dbutils')
from dbutils import *

class RuleDictResult(DictResult):
    _non_comp_version    = [DEFAULT_NON_COMP_VERSION]
    _group               = [GROUP_COMPANY]
    _category            = CATEGORY_NETWORK
    _severity            = LEVEL_WARNING
    _strId               = 'rule_http_compression'

    def getStatus(self):
        import json

        try:
            with open('/usr/syno/etc/www/DSM.json') as fd:
                data = json.load(fd)

            if 'https' in data and 'compression' in data['https']:
                if data['https']['compression']:
                    return SZ_FAIL
            return SZ_PASS
        except Exception as e:
            return SZ_ERROR

    def getMethod(self):
        method = {
            METHOD_ACTION        : METHOD_ACTION_LINK,
            METHOD_ACTION_VAL    : 'SYNO.SDS.AdminCenter.Application:SYNO.SDS.AdminCenter.Security.Main:AdvancedTab'}
        return method

    def getAction(self):
        return {
            ACTION_STR_KEY: 'action',
            ACTION_REPLACE_VAR: {
                '%0': "_T('controlpanel', 'leaf_security')",
                '%1': "_T('http_compression', 'title')"
            }
        }

